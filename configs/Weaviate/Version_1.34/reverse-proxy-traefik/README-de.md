# 🧠 Weaviate 1.34.0 hinter Traefik-Proxy (TLS, API-Key, RBAC)

Dieses Setup stellt eine gehärtete **Weaviate 1.34.0**-Instanz bereit, deren
**HTTP-API über einen Traefik v3.5 Reverse Proxy** mit **TLS** veröffentlicht wird.  
Direkter lokaler Zugriff bleibt auf `127.0.0.1:8080` (HTTP) und
`127.0.0.1:50051` (gRPC, falls aktiviert) möglich.  
Externer Zugriff über Traefik erfolgt ausschließlich per HTTPS:

- `https://weaviate.docker.localhost` – Weaviate API
- `https://traefik.docker.localhost` – Traefik Dashboard (optional)

Der Fokus liegt auf **Security-by-Default**:
- 🔐 API-Key-Authentifizierung  
- 🔏 RBAC aktiviert  
- 🛡️ Container-Härtung (cap_drop, no-new-privileges, read-only)  
- 🌐 TLS über Traefik  
- 🚫 Kein anonymer Zugriff  

---

## 📂 Projektstruktur

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
- REST/GraphQL API auf Port `8080` (nur lokal verfügbar)
- Authentifizierung: `Authorization: Bearer <API_KEY>`
- RBAC aktiviert
- Module optional über `.env` konfigurierbar

### 2) Traefik (`traefik`)
- Reverse Proxy & TLS-Termination
- Redirect HTTP → HTTPS
- Zertifikate aus `./certs`
- Sicherheit durch Middleware: `secure-headers`

---

## 🔐 `.env` – Umgebungsvariablen

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

Hinweise:
- Keine Anführungszeichen bei `true`/`false`.
- Reihenfolge Keys ↔ User muss exakt passen.
- API-Key regelmäßig rotieren.

---

## 🔏 TLS-Konfiguration

### Zertifikat erzeugen:

Ein lokales Zertifikat erzeugen, das beide Hostnamen per SAN abdeckt:

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

## 🌐 Hosts-Eintrag (macOS / Linux)

```text
127.0.0.1   weaviate.docker.localhost
127.0.0.1   traefik.docker.localhost
```

---

## 🚀 Start & Verwaltung

### Starten 
siehe auch: allgemeine README für Weaviate Version 1.34.0

```bash
docker compose pull
docker compose up -d
```

### Stoppen

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

## 🧪 Funktionsprüfung

```bash
curl -i http://127.0.0.1:8080/v1/.well-known/ready
curl -ik https://weaviate.docker.localhost/v1/meta -H "Authorization: Bearer example-key-12345"
curl -ik https://weaviate.docker.localhost/v1/schema -H "Authorization: Bearer example-key-12345"
```

---

## TLS + Authentication + REST-only client

Siehe `example-clients-python/weaviate-rest-minimal.py`  
Funktioniert ohne Embedding-Module (kein Ollama, kein OpenAI).

## 🧩 Optionale KI-Integration mit Ollama (Embeddings & Generative)

Siehe `example-clients-python/weaviate-ollama-client.py`


Das Basis-Setup funktioniert **ohne** Embedding-Module.  
Optional kann Weaviate mit **Ollama** verbunden werden, um:

- Vektoren per `text2vec-ollama` zu erzeugen (Embeddings)
- Generative Antworten per `generative-ollama` zu erzeugen

### 1. Ollama bereitstellen

**Ollama im Docker-Container**

Für ein vollständig containerisiertes Setup kann der bereits vorhandene optionale
`ollama`-Service im gleichen Netzwerk wie Weaviate genutzt werden, z. B.:

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
      - ollama  # starten mit: docker compose --profile ollama up -d
```

In `.env` die Module explizit aktivieren:

```bash
ENABLE_API_BASED_MODULES=true
ENABLE_MODULES=text2vec-ollama,generative-ollama
```

In diesem Fall lautet der Endpoint für Weaviate:
http://ollama:11434

### 2. Modelle/Endpoints konfigurieren
Weaviate selbst kennt damit die Module; welches Modell bzw. welcher Endpoint
verwendet wird, legt man pro Collection im Client fest.

--> in Docker - die entsprechenden Modelle ziehen:
```bash
docker exec -it ollama ollama pull nomic-embed-text
docker exec -it ollama ollama pull llama3.2
```

### 3. Ausführen

Im Ordner `example-clients-python`:

```bash
pip install weaviate-client
python weaviate-ollama-client.py
```

Der Client:
- prüft, ob Ollama auf http://127.0.0.1:11434 erreichbar ist
- prüft, ob `nomic-embed-text` und `llama3.2` vorhanden sind
- erstellt eine Collection `QuestionOllama` mit:
  - `text2vec-ollama` (Embeddings)
  - `generative-ollama` (LLM)
- fügt ein Beispielobjekt ein: `question = "What is a vector database?"`
- führt eine `near_text`-Suche aus und erzeugt eine Antwort mit `single_prompt`
- gibt Frage + generierte Antwort auf der Konsole aus

---

## 🛠️ Schnelle API-Checks (curl)

Mit Reverse-Proxy (TLS) und API-Key:

```bash
# Ready & Meta
curl -ik https://weaviate.docker.localhost/v1/.well-known/ready -H "Authorization: Bearer example-key-12345"
curl -ik https://weaviate.docker.localhost/v1/meta                  -H "Authorization: Bearer example-key-12345"

# Schema ansehen
curl -ik https://weaviate.docker.localhost/v1/schema               -H "Authorization: Bearer example-key-12345"

# Beispiel-Objekt anlegen (Class Question)
curl -ik https://weaviate.docker.localhost/v1/objects \
  -H "Authorization: Bearer example-key-12345" \
  -H "Content-Type: application/json" \
  -d '{"class":"Question","properties":{"question":"What is a vector database?","answer":"A DB that stores vectors for similarity search","category":"databases"},"vector":[0,0,0,0]}'

# Objekte auflisten (limit 3)
curl -ik "https://weaviate.docker.localhost/v1/objects?class=Question&limit=3" \
  -H "Authorization: Bearer example-key-12345"

# GraphQL Query
curl -ik https://weaviate.docker.localhost/v1/graphql \
  -H "Authorization: Bearer example-key-12345" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ Get { Question(limit: 3) { question answer category _additional { id } } } }"}'
```

> Hinweis: Lokal ohne Traefik geht auch über `http://127.0.0.1:8080/...` (kein TLS, kein Host-Header nötig).

---

© 2025 – Sichere Datenbankkonfigurationen
