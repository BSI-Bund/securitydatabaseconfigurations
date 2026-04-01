"""
Weaviate + Ollama demo client (REST + gRPC) for secure reverse-proxy setup.
Requires Ollama models and Weaviate 1.34.

Features:
- Preflight check: verifies Ollama connectivity and pulled models
- Works with Traefik-exposed Weaviate (REST) and local gRPC
- Uses the generative API compatible with the installed weaviate-client
"""

import os
import sys
import requests
import weaviate
from weaviate.classes.init import Auth
from weaviate.classes.config import Configure

# --------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------
API_KEY = "example-key-12345"

# Host-facing endpoint (used by this client for preflight checks)
OLLAMA_ENDPOINT_HOST = os.getenv("OLLAMA_ENDPOINT", "http://127.0.0.1:11434")
# Endpoint reachable from inside the Weaviate container
OLLAMA_ENDPOINT_WEAVIATE = os.getenv("OLLAMA_ENDPOINT_WEAVIATE", "http://ollama:11434")
EMBED_MODEL = os.getenv("OLLAMA_EMBED_MODEL", "nomic-embed-text")
GENERATE_MODEL = os.getenv("OLLAMA_GENERATE_MODEL", "llama3.2")


# --------------------------------------------------------------------
# Pre-flight check: ensure Ollama is reachable & models exist
# --------------------------------------------------------------------
def ensure_ollama_models():
    try:
        resp = requests.get(f"{OLLAMA_ENDPOINT_HOST}/api/tags", timeout=5)
        resp.raise_for_status()
        models = resp.json().get("models", [])
        available = {m.get("name", "").split(":")[0] for m in models}

        missing = [m for m in (EMBED_MODEL, GENERATE_MODEL) if m not in available]

        if missing:
            print("⚠️ Missing Ollama models:", ", ".join(missing))
            print("Pull them with:")
            for m in missing:
                print(f"  docker exec -it ollama ollama pull {m}")
            sys.exit(1)

    except Exception as exc:
        print(f"❌ Could not reach Ollama at {OLLAMA_ENDPOINT_HOST}: {exc}")
        sys.exit(1)


# --------------------------------------------------------------------
# Main
# --------------------------------------------------------------------
def main():
    print("🔍 Checking Ollama models...")
    ensure_ollama_models()

    # ------------------------------------------------------------
    # Connect to Weaviate (REST + gRPC enabled)
    # ------------------------------------------------------------
    print("🔗 Connecting to Weaviate...")
    client = weaviate.connect_to_custom(
        http_host="127.0.0.1",
        http_port=8080,
        http_secure=False,

        grpc_host="127.0.0.1",
        grpc_port=50051,
        grpc_secure=False,

        auth_credentials=Auth.api_key(API_KEY),
        skip_init_checks=True,  # init checks optional
    )

    with client:
        # --------------------------------------------------------
        # Create or retrieve collection
        # --------------------------------------------------------
        print("📦 Ensuring collection exists...")
        try:
            questions = client.collections.create(
                name="QuestionOllama",
                vector_config=Configure.Vectors.text2vec_ollama(
                    api_endpoint=OLLAMA_ENDPOINT_WEAVIATE,
                    model=EMBED_MODEL,
                    source_properties=["question", "category"],
                ),
                generative_config=Configure.Generative.ollama(
                    api_endpoint=OLLAMA_ENDPOINT_WEAVIATE,
                    model=GENERATE_MODEL,
                ),
            )
        except Exception:
            questions = client.collections.get("QuestionOllama")

        # --------------------------------------------------------
        # Insert a sample object
        # --------------------------------------------------------
        print("📝 Inserting sample object...")
        questions.data.insert(
            {
                "question": "What is a vector database?",
                "category": "databases",
            }
        )

        # --------------------------------------------------------
        # Query + generative response
        # --------------------------------------------------------
        print("🔎 Querying and generating response...")
        result = questions.generate.near_text(
            query="vector databases",
            limit=1,
            single_prompt=(
                "You are answering user questions about databases.\n"
                "Question: {{question}}\n"
                "Answer in 2-3 sentences."
            ),
        )

        # --------------------------------------------------------
        # Output
        # --------------------------------------------------------
        if not result.objects:
            print("⚠️ No objects returned. Check that data insertion and generation succeeded.")
            return

        for obj in result.objects:
            print("\n=== Result ===")
            print("Question:", obj.properties.get("question"))
            print("Generated answer:")
            try:
                print(obj.generative.text)
            except Exception:
                print("(no direct .text field, raw payload):", obj.generative)


# --------------------------------------------------------------------
# Run
# --------------------------------------------------------------------
if __name__ == "__main__":
    main()
