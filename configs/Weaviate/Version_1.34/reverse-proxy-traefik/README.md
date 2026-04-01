# 🧠 Weaviate 1.34.0 behind Traefik proxy (TLS, API key, RBAC)

This setup provides a hardened **Weaviate 1.34.0** instance with its
**HTTP API exposed through a Traefik v3.5 reverse proxy** using **TLS**.  
Direct local access remains available on `127.0.0.1:8080` (HTTP) and
`127.0.0.1:50051` (gRPC, if enabled).  
External access through Traefik is HTTPS only:

- `https://weaviate.docker.localhost` – Weaviate API
- `https://traefik.docker.localhost` – Traefik dashboard (optional)

Focus: **security by default**
- 🔐 API key authentication  
- 🔏 RBAC enabled  
- 🛡️ Container hardening (cap_drop, no-new-privileges, read-only)  
- 🌐 TLS via Traefik  
- 🚫 No anonymous access  

---

## 📂 Project structure

```text
reverse-proxy-traefik/
├── docker-compose.yml
├── .env.example
├── certs/
│   ├── local.crt
│   └── local.key
└── dynamic/
    └── tls.yml
```

---

## ⚙️ Services

### 1) Weaviate (`weaviate-db-proxy`)
- Image: `cr.weaviate.io/semitechnologies/weaviate:1.34.0`
- REST/GraphQL API on port `8080` (local only)
- Authentication: `Authorization: Bearer <API_KEY>`
- RBAC enabled
- Modules optional via `.env`

### 2) Traefik (`traefik`)
- Reverse proxy & TLS termination
- Redirect HTTP → HTTPS
- Certificates from `./certs`
- Security middleware: `secure-headers`

---

## 🔐 `.env` – environment variables

```dotenv
WEAVIATE_VERSION=1.34.0
WEAVIATE_HOST=0.0.0.0
WEAVIATE_PORT=8080
WEAVIATE_SCHEME=http
TZ=Europe/Berlin

WEAVIATE_DATA_PATH=/var/lib/weaviate
WEAVIATE_QUERY_LIMIT=100
WEAVIATE_CLUSTER_HOSTNAME=node1
DISABLE_TELEMETRY=true
QUERY_SLOW_LOG_ENABLED=true

AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED=false
AUTHENTICATION_APIKEY_ENABLED=true
WEAVIATE_API_KEYS=example-key-12345
WEAVIATE_API_USERS=admin
AUTHORIZATION_ENABLE_RBAC=true
WEAVIATE_ROOT_USERS=admin

ENABLE_API_BASED_MODULES=false
ENABLE_MODULES=
OLLAMA_ENDPOINT="http://127.0.0.1:11434"
OLLAMA_ENDPOINT_WEAVIATE="http://ollama:11434"

WEAVIATE_DOMAIN=weaviate.docker.localhost
TRAEFIK_DASHBOARD_DOMAIN=traefik.docker.localhost
```

Notes:
- No quotes around `true`/`false`.
- Order of keys ↔ users must match exactly.
- Rotate API keys regularly.

---

## 🔏 TLS configuration

### Create certificate

Create a local certificate that covers both hostnames via SAN:

```bash
openssl req -x509 -newkey rsa:4096 -nodes \
  -keyout certs/local.key \
  -out certs/local.crt \
  -days 365 \
  -subj "/CN=weaviate.docker.localhost" \
  -addext "subjectAltName=DNS:weaviate.docker.localhost,DNS:traefik.docker.localhost"
```

### `dynamic/tls.yml`

```yaml
tls:
  certificates:
    - certFile: /certs/local.crt
      keyFile: /certs/local.key

http:
  middlewares:
    secure-headers:
      headers:
        frameDeny: true
        contentTypeNosniff: true
        referrerPolicy: "strict-origin-when-cross-origin"
        stsSeconds: 31536000
        stsIncludeSubdomains: true
        stsPreload: true
```

---

## 🌐 Hosts entry (macOS / Linux)

```text
127.0.0.1   weaviate.docker.localhost
127.0.0.1   traefik.docker.localhost
```

---

## 🚀 Start & operations

### Start  
(see also the main Weaviate 1.34.0 README)

```bash
docker compose pull
docker compose up -d
```

### Stop

```bash
docker compose down
```

### Logs

```bash
docker logs weaviate-db-proxy --tail 50
docker logs traefik --tail 50
```

### Status

```bash
docker compose ps
```

---

## 🧪 Health checks

```bash
curl -i http://127.0.0.1:8080/v1/.well-known/ready
curl -ik https://weaviate.docker.localhost/v1/meta -H "Authorization: Bearer example-key-12345"
curl -ik https://weaviate.docker.localhost/v1/schema -H "Authorization: Bearer example-key-12345"
```

---

## TLS + authentication + REST-only client

See `example-clients-python/weaviate-rest-minimal.py`.  
This works without embedding modules (no Ollama, no OpenAI).

## 🧩 Optional AI integration with Ollama (embeddings & generative)

See `example-clients-python/weaviate-ollama-client.py`.

The base setup works **without** embedding modules.  
Optionally, connect Weaviate to **Ollama** to:

- Create vectors via `text2vec-ollama` (embeddings)
- Generate responses via `generative-ollama`

### 1. Provide Ollama

**Ollama in a Docker container**

For a fully containerized setup, use the existing optional `ollama` service
in the same network as Weaviate, e.g.:

```bash
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: unless-stopped
    networks:
      - proxy
    volumes:
      - ollama_data:/root/.ollama
    ports:
      - "127.0.0.1:11434:11434"
    profiles:
      - ollama  # start with: docker compose --profile ollama up -d
```

In `.env`, enable the modules explicitly:

```bash
ENABLE_API_BASED_MODULES=true
ENABLE_MODULES=text2vec-ollama,generative-ollama
```

Resulting endpoint for Weaviate: `http://ollama:11434`

### 2. Configure models/endpoints
Weaviate then knows the modules; the **model/endpoint** is set per collection in the client.

Pull models in Docker:
```bash
docker exec -it ollama ollama pull nomic-embed-text
docker exec -it ollama ollama pull llama3.2
```

### 3. Run

In `/example-clients-python`:

```bash
pip install weaviate-client
python weaviate-ollama-client.py
```

The client:
- Checks if Ollama is reachable at http://127.0.0.1:11434
- Verifies `nomic-embed-text` and `llama3.2` exist
- Creates collection `QuestionOllama` with:
  - `text2vec-ollama` (embeddings)
  - `generative-ollama` (LLM)
- Inserts one example object: `question = "What is a vector database?"`
- Runs a near_text search and generates an answer with `single_prompt`
- Prints question + generated answer

---

## 🛠️ Quick API checks (curl)

Use the reverse-proxy hostnames (TLS) and your API key:

```bash
# Ready & meta
curl -ik https://weaviate.docker.localhost/v1/.well-known/ready -H "Authorization: Bearer example-key-12345"
curl -ik https://weaviate.docker.localhost/v1/meta                  -H "Authorization: Bearer example-key-12345"

# Schema view
curl -ik https://weaviate.docker.localhost/v1/schema               -H "Authorization: Bearer example-key-12345"

# Insert a sample object (class Question)
curl -ik https://weaviate.docker.localhost/v1/objects \
  -H "Authorization: Bearer example-key-12345" \
  -H "Content-Type: application/json" \
  -d '{"class":"Question","properties":{"question":"What is a vector database?","answer":"A DB that stores vectors for similarity search","category":"databases"},"vector":[0,0,0,0]}'

# List objects (limit 3)
curl -ik "https://weaviate.docker.localhost/v1/objects?class=Question&limit=3" \
  -H "Authorization: Bearer example-key-12345"

# GraphQL query
curl -ik https://weaviate.docker.localhost/v1/graphql \
  -H "Authorization: Bearer example-key-12345" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ Get { Question(limit: 3) { question answer category _additional { id } } } }"}'
```

> Tip: Local REST access without Traefik also works via `http://127.0.0.1:8080/...`
> (no TLS, no Host header). The Python Ollama example also uses local gRPC on
> `127.0.0.1:50051`, not Traefik.

---

© 2025 – Secure database configurations
