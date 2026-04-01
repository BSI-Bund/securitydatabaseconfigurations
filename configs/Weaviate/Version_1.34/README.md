# <img src=../weaviate-logo-w.png alt="Weaviate Logo" width="26"/> Weaviate - Configurations (Docker Compose)

- [🚀 Getting started with the Docker Compose setup](#-getting-started-with-the-docker-compose-setup)
  - [⚙️ Services](#️-services)
    - [🧠 weaviate](#-weaviate)
  - [🧰 Environment variables](#-environment-variables)
  - [📑 Parameter reference (short)](#-parameter-reference-short)
  - [📁 Volumes & mounts](#-volumes--mounts)
  - [🌐 Ports](#-ports)
  - [🛡️ Security notes](#️-security-notes)
  - [🧊 Container hardening (optional, recommended)](#-container-hardening-optional-recommended)
- [🧭 TLS & reverse proxy](#-tls--reverse-proxy)
- [🎛️ Start & operations](#️-start--operations)
- [🧪 Health check](#-health-check)

---

## 🚀 Getting started with the Docker Compose setup

This setup provides a **Weaviate 1.34.0** instance (vector database with REST/GraphQL API).
Configuration file:

```bash
docker-compose.yml  # uses values from .env
```

> **Secure by default:** Anonymous access is disabled. Access is via **API key** and **RBAC** is enabled.

---

### ⚙️ Services

#### 🧠 weaviate

- Image `cr.weaviate.io/semitechnologies/weaviate:${WEAVIATE_VERSION}`
- Starts with `--host 0.0.0.0 --port 8080 --scheme http`
- Authentication via **API key**, authorization via **RBAC**
- Optional modules such as `text2vec-ollama` & `generative-ollama` (configured per collection on the client side)

---

### 🧰 Environment variables

Example values live in `.env` (see below).  
**Important:** The order of `WEAVIATE_API_KEYS` and `WEAVIATE_API_USERS` must match **1:1**.

`cp .env.example .env` – then adjust values.

**.env (excerpt, production-style):**
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

AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED="false"
AUTHENTICATION_APIKEY_ENABLED="true"
WEAVIATE_API_KEYS=example-key-12345,another-key-67890
WEAVIATE_API_USERS=admin,user
AUTHORIZATION_ENABLE_RBAC="true"
WEAVIATE_ROOT_USERS=admin

# Optional (only if modules are used):
ENABLE_API_BASED_MODULES="true"
ENABLE_MODULES=text2vec-ollama,generative-ollama
```

---

### 📑 Parameter reference (short)

| Variable                           | Purpose                                          | Recommendation |
|------------------------------------|--------------------------------------------------|----------------|
| `WEAVIATE_VERSION`                 | Pin Weaviate version (avoid `latest`)            | `1.34.0` |
| `WEAVIATE_HOST`                    | Bind address inside container                    | `0.0.0.0` |
| `WEAVIATE_PORT`                    | API port                                         | `8080` |
| `WEAVIATE_SCHEME`                  | Internal protocol                                | `http` |
| `TZ`                               | Timezone                                         | `Europe/Berlin` |
| `WEAVIATE_DATA_PATH`               | Persistence path in container                    | `/var/lib/weaviate` |
| `WEAVIATE_QUERY_LIMIT`             | Default query limit                              | `100` |
| `WEAVIATE_CLUSTER_HOSTNAME`        | Node name (Raft/cluster)                         | `node1` |
| `DISABLE_TELEMETRY`                | Opt out of anonymous usage metrics               | `true` |
| `QUERY_SLOW_LOG_ENABLED`           | Enable slow query logging                        | `true` |

**Auth & RBAC**

| Variable                                    | Purpose                                 | Recommendation |
|---------------------------------------------|-----------------------------------------|----------------|
| `AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED`   | Disable anonymous access                | `"false"` |
| `AUTHENTICATION_APIKEY_ENABLED`             | Enable API key auth                     | `"true"` |
| `WEAVIATE_API_KEYS`                         | API keys (comma separated)              | `keyA,keyB` |
| `WEAVIATE_API_USERS`                        | Users mapped to keys (same order)       | `userA,userB` |
| `AUTHORIZATION_ENABLE_RBAC`                 | Enable RBAC                             | `"true"` |
| `WEAVIATE_ROOT_USERS`                       | Root users (admin)                      | `userA` |

**Modules (optional)**

| Variable                    | Purpose                               | Recommendation |
|-----------------------------|---------------------------------------|----------------|
| `ENABLE_API_BASED_MODULES`  | Allow API-based modules               | `"true"` |
| `ENABLE_MODULES`            | Modules to enable                     | `text2vec-ollama,generative-ollama` |

> ℹ️ **Module note:** Model and endpoint (e.g., Ollama `http://ollama:11434`) are set **per collection in the client**, not via `.env`.

---

### 📁 Volumes & mounts

| Mount                                      | Description                             |
|--------------------------------------------|-----------------------------------------|
| `weaviate_data:/var/lib/weaviate`          | Persistent volume for Weaviate data     |

> Backups: regularly back up `weaviate_data` and **test restore**.

---

### 🌐 Ports

| Port   | Service  | Description                 |
|--------|----------|-----------------------------|
| `8080` | Weaviate | REST/GraphQL API (HTTP)     |

> **gRPC (50051)** is **not** exposed (recommended). Open only if explicitly needed.

---

### 🛡️ Security notes

This configuration is **secure by default** and follows hardened deployment basics:

| Category             | Recommendation |
|----------------------|----------------|
| **Authentication**   | API key auth enabled; anonymous access disabled. |
| **Authorization (RBAC)** | Role-based access active; only defined root users have full access. |
| **Network access**   | Ideally bind to localhost (127.0.0.1); expose externally only via TLS proxy. |
| **API keys**         | Use long, random keys (>32 chars) and rotate regularly. |
| **Volumes**          | Back up `weaviate_data` and restrict access. |
| **Updates**          | Avoid `latest` images; use pinned versions (e.g., `1.34.0`). |
| **Modules**          | Enable only what you need (`text2vec-ollama`, `generative-ollama`, etc.). |

> 💡 For production, place Weaviate behind a reverse proxy (e.g., Traefik or Nginx with HTTPS) and protect API access via IP allowlists or VPN.

---

### 🧊 Container hardening (optional, recommended)

These settings reduce the attack surface without changing architecture:

| Measure | Purpose |
|---------|---------|
| `security_opt: no-new-privileges:true` | Prevents privilege escalation. |
| `cap_drop: ["ALL"]` | Drops all Linux capabilities (least privilege). |
| `read_only: true` + `tmpfs: /tmp` | Read-only root FS; temporary writes go to /tmp. |
| `mem_limit` / `cpus` | Resource limits; protect against DoS/runaway queries. |

**Compose snippet (excerpt):**
```yaml
security_opt:
  - no-new-privileges:true
cap_drop: ["ALL"]
read_only: true
tmpfs:
  - /tmp:size=64m,mode=1777
mem_limit: "4g"
cpus: "2.0"
```

> Note: The data volume (weaviate_data → ${WEAVIATE_DATA_PATH}) remains writable. If more writable paths are needed, add targeted tmpfs mounts.

---

## 🧭 TLS & reverse proxy

For secure exposure, run Weaviate behind a **Traefik reverse proxy with TLS termination**.  
The full setup—certs, secure headers, domain config, API key protection—is documented in:

➡️ **[reverse-proxy-traefik](./reverse-proxy-traefik)**

That folder covers:
- TLS (self-signed or production)
- secure routing (`websecure`)
- API key authentication & RBAC
- secure headers (`secure-headers`)
- container hardening
- hostname-based routes for Weaviate & Traefik dashboard
- health checks & localhost binding (`127.0.0.1`)

Python client examples for accessing the database live in **[example-clients-python](./reverse-proxy-traefik/example-clients-python)**.

---

## 🎛️ Start & operations

### ▶️ Start

```bash
# once: provide/verify .env
docker compose --env-file .env pull
docker compose --env-file .env up -d
```

### ⏹️ Stop

```bash
docker compose --env-file .env down
```

### 🧾 Show logs

```bash
docker compose --env-file .env logs -f weaviate
```

### 🧹 Remove data (optional)

```bash
# Warning: deletes persistent data
docker volume rm <project>_weaviate_data
```

---

## 🧪 Health check

**Call readiness endpoint (with API key):**
```bash
curl -i "http://localhost:${WEAVIATE_PORT}/v1/.well-known/ready"   -H "x-api-key: example-key-12345"
```

- Expected: `HTTP/1.1 200 OK`
- If `401/403`: check API key or key↔user order in `.env`.

**Note on modules (optional):**
If `ENABLE_MODULES` is set (e.g., `text2vec-ollama,generative-ollama`), set **endpoint & model per collection** in the client, e.g.:

```python
from weaviate.classes.config import Configure
# ...
client.collections.create(
  name="Docs",
  vector_config=[Configure.Vectors.text2vec_ollama(
    name="textvec",
    source_properties=["title","content"],
    api_endpoint="http://ollama:11434",
    model="nomic-embed-text"
  )],
  generative_config=Configure.Generative.ollama(
    api_endpoint="http://ollama:11434",
    model="llama3.2"
  ),
)
```

---

© 2025 – Secure database configurations
