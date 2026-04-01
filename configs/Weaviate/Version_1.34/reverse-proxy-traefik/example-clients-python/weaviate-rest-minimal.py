"""
Minimal REST-only Weaviate client for testing a secure instance.
"""

import requests
import json

API_KEY = "example-key-12345"
BASE_URL = "http://127.0.0.1:8080"
COLLECTION_NAME = "Question"
DATA_URL = "https://raw.githubusercontent.com/weaviate-tutorials/quickstart/main/data/jeopardy_tiny.json"


def check_ready():
    r = requests.get(f"{BASE_URL}/v1/.well-known/ready")
    print("Ready:", r.status_code)


def create_class():
    schema = {
        "class": COLLECTION_NAME,
        "properties": [
            {"name": "answer", "dataType": ["text"]},
            {"name": "question", "dataType": ["text"]},
            {"name": "category", "dataType": ["text"]},
        ],
        # No vectorizer required → simplest possible class
        "vectorizer": "none"
    }

    r = requests.post(
        f"{BASE_URL}/v1/schema",
        headers={
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json",
        },
        data=json.dumps(schema),
    )
    print("Create class:", r.status_code, r.text)


def fetch_data():
    r = requests.get(DATA_URL, timeout=15)
    r.raise_for_status()
    return r.json()


def import_data(data):
    for item in data:
        obj = {
            "class": COLLECTION_NAME,
            "properties": {
                "answer": item["Answer"],
                "question": item["Question"],
                "category": item["Category"],
            },
            "vector": [0] * 4  # dummy vector of length 4 (minimal)
        }
        r = requests.post(
            f"{BASE_URL}/v1/objects",
            headers={
                "Authorization": f"Bearer {API_KEY}",
                "Content-Type": "application/json",
            },
            data=json.dumps(obj),
        )
        if r.status_code not in (200, 201):
            print("Insert error:", r.status_code, r.text)
            break


def query_example():
    r = requests.get(
        f"{BASE_URL}/v1/objects?class={COLLECTION_NAME}&limit=2",
        headers={"Authorization": f"Bearer {API_KEY}"},
    )
    print("Query:", r.status_code)
    print(r.text)


def main():
    check_ready()
    create_class()
    data = fetch_data()
    import_data(data)
    query_example()


if __name__ == "__main__":
    main()
