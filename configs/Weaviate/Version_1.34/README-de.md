# <img src=../weaviate-logo-w.png alt="Weaviate Logo" width="26"/> Weaviate - Konfigurationen (Docker Compose)

- [🚀 Hinweise zum Start mit Docker Compose Setup](#-hinweise-zum-start-mit-docker-compose-setup)
  - [⚙️ Services](#-services)
    - [🧠 weaviate](#-weaviate)
  - [🧰 Umgebungsvariablen](#-umgebungsvariablen)
  - [📑 Parameter-Referenz (Kurz)](#-parameter-referenz-kurz)
  - [📁 Volumes & Mounts](#-volumes--mounts)
  - [🌐 Ports](#-ports)
  - [🛡️ Sicherheitshinweise](#-sicherheitshinweise)
  - [🧊 Container-Härtung (optional, empfohlen)](#-container-härtung-optional-empfohlen)
- [🧭 TLS & Reverse Proxy](#-tls--reverse-proxy)
- [🎛️ Start & Verwaltung](#-start--verwaltung)
- [🧪 Funktionsprüfung (Healthcheck)](#-funktionsprüfung-healthcheck)

---

## 🚀 Hinweise zum Start mit Docker Compose Setup

Dieses Setup stellt eine **Weaviate 1.34.0**-Instanz bereit (Vektor-Datenbank mit REST/GraphQL API).  
Die Konfiguration erfolgt über:

```bash
docker-compose.yml  # nutzt Werte aus .env
```

> **Sicherheit by Default:** Anonymer Zugriff ist deaktiviert, Zugriff erfolgt via **API-Key**. **RBAC** (rollenbasiert) ist aktiviert.

---

### ⚙️ Services

#### 🧠 weaviate

- Verwendet das Image `cr.weaviate.io/semitechnologies/weaviate:${WEAVIATE_VERSION}`  
- Startet mit `--host 0.0.0.0 --port 8080 --scheme http`  
- Authentifizierung per **API-Key**, Autorisierung via **RBAC**  
- Optional können Module wie `text2vec-ollama` & `generative-ollama` aktiviert werden (pro Collection im Client konfigurierbar)

---

### 🧰 Umgebungsvariablen

Beispielwerte liegen in `.env` (siehe unten).  
**Wichtig:** Die Reihenfolge von `WEAVIATE_API_KEYS` und `WEAVIATE_API_USERS` muss **1:1** korrespondieren.

`cp .env.example .env` – anschließend die Werte anpassen.

**.env (Auszug, produktionsnah):**
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

# Optional (nur wenn Module verwendet werden):
ENABLE_API_BASED_MODULES="true"
ENABLE_MODULES=text2vec-ollama,generative-ollama
```

---

### 📑 Parameter-Referenz (Kurz)

| Variable                           | Zweck                                              | Empfehlung |
|-----------------------------------|----------------------------------------------------|-------------|
| `WEAVIATE_VERSION`                | Feste Weaviate-Version (kein `latest`)             | `1.34.0` |
| `WEAVIATE_HOST`                   | Bind-Adresse im Container                          | `0.0.0.0` |
| `WEAVIATE_PORT`                   | API-Port                                           | `8080` |
| `WEAVIATE_SCHEME`                 | Protokoll intern                                   | `http` |
| `TZ`                              | Zeitzone                                           | `Europe/Berlin` |
| `WEAVIATE_DATA_PATH`              | Persistenzpfad im Container                        | `/var/lib/weaviate` |
| `WEAVIATE_QUERY_LIMIT`            | Default-Limit für Abfragen                         | `100` |
| `WEAVIATE_CLUSTER_HOSTNAME`       | Knotenname (Raft/Cluster)                          | `node1` |
| `DISABLE_TELEMETRY`               | Telemetrie (anonyme Nutzungsdaten) deaktivieren    | `true` |
| `QUERY_SLOW_LOG_ENABLED`          | Slow-Query-Log aktivieren                          | `true` |

**Auth & RBAC**

| Variable                                    | Zweck                                   | Empfehlung |
|---------------------------------------------|-----------------------------------------|-------------|
| `AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED`   | Anonyme Zugriffe deaktivieren            | `"false"` |
| `AUTHENTICATION_APIKEY_ENABLED`             | API-Key Auth aktivieren                  | `"true"` |
| `WEAVIATE_API_KEYS`                         | API-Keys (komma-separiert)               | `keyA,keyB` |
| `WEAVIATE_API_USERS`                        | Users zu Keys (1:1-Reihenfolge)          | `userA,userB` |
| `AUTHORIZATION_ENABLE_RBAC`                 | RBAC aktivieren                          | `"true"` |
| `WEAVIATE_ROOT_USERS`                       | Root-User (Admin)                        | `userA` |

**Module (optional)**

| Variable                   | Zweck                                 | Empfehlung |
|---------------------------|---------------------------------------|-------------|
| `ENABLE_API_BASED_MODULES`| API-basierte Module erlauben          | `"true"` |
| `ENABLE_MODULES`          | Aktivierte Module                     | `text2vec-ollama,generative-ollama` |

> ℹ️ **Hinweis zu Modulen:** Modell & Endpoint (z. B. Ollama `http://ollama:11434`) werden **pro Collection im Client** gesetzt, nicht via `.env`.

---

### 📁 Volumes & Mounts

| Mount                                      | Beschreibung                              |
|--------------------------------------------|-------------------------------------------|
| `weaviate_data:/var/lib/weaviate`          | Persistentes Volume für Weaviate-Daten    |

> Backups: Das Volume `weaviate_data` regelmäßig sichern & **Restore testen**.

---

### 🌐 Ports

| Port   | Dienst   | Beschreibung                  |
|--------|----------|-------------------------------|
| `8080` | Weaviate | REST/GraphQL API (HTTP)       |

> **gRPC (50051)** wird **nicht** exponiert (empfohlen). Nur öffnen, wenn explizit benötigt.

---

### 🛡️ Sicherheitshinweise

Diese Konfiguration ist **secure-by-default** und entspricht den Grundprinzipien einer gehärteten Bereitstellung:

| Kategorie | Empfehlung |
|------------|-------------|
| **Authentifizierung** | API-Key-Authentifizierung aktiv; anonyme Zugriffe sind deaktiviert. |
| **Autorisierung (RBAC)** | Rollenbasiertes Zugriffskonzept aktiv; nur definierte Root-User mit Vollzugriff. |
| **Netzwerkzugriff** | Dienst idealerweise nur lokal (127.0.0.1) binden; externer Zugriff ausschließlich über TLS-Proxy. |
| **API-Keys** | Lange, zufällig generierte Keys (>32 Zeichen) nutzen und regelmäßig rotieren. |
| **Volumes** | Persistente Daten (`weaviate_data`) regelmäßig sichern und Zugriff beschränken. |
| **Updates** | Keine `latest`-Images verwenden; immer feste Versionen (z. B. `1.34.0`). |
| **Module** | Nur benötigte Module aktivieren (`text2vec-ollama`, `generative-ollama` etc.). |

> 💡 Für Produktionsumgebungen wird empfohlen, Weaviate hinter einem Reverse Proxy (z. B. Traefik oder Nginx mit HTTPS) zu betreiben und API-Zugriffe über IP-Allowlists oder VPN zu schützen.

---

### 🧊 Container-Härtung (optional, empfohlen)

Die folgenden Einstellungen reduzieren die Angriffsfläche des Containers, ohne die Architektur zu verändern:

| Maßnahme | Zweck |
|---------|------|
| `security_opt: no-new-privileges:true` | Verhindert Privilegienerweiterungen im Prozess. |
| `cap_drop: ["ALL"]` | Entfernt alle Linux-Capabilities (Least Privilege). |
| `read_only: true` + `tmpfs: /tmp` | Root-Filesystem schreibgeschützt; temporäre Writes über /tmp. |
| `mem_limit` / `cpus` | Ressourcen begrenzen; schützt vor DoS/Runaway-Queries. |

**Compose-Beispiel (Auszug):**
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

> 💡 Hinweis: Das Daten-Volume (weaviate_data → ${WEAVIATE_DATA_PATH}) bleibt beschreibbar. Falls zusätzliche Schreibpfade nötig sind, gezielt weitere tmpfs-Mounts setzen.

---

## 🧭 TLS & Reverse Proxy

Für eine sichere Bereitstellung von Weaviate wird das System hinter einem
**Traefik Reverse Proxy mit TLS-Termination** betrieben.  
Das vollständige Setup – inklusive Zertifikaten, Header-Härtung,
Domain-Konfiguration und API-Key-Absicherung – befindet sich im separaten
Ordner:

➡️ **[reverse-proxy-traefik](./reverse-proxy-traefik)**

Dort ist die komplette, gehärtete Konfiguration dokumentiert:

- TLS (self-signed oder produktiv)
- sicheres Routing (`websecure`)
- API-Key-Authentifizierung & RBAC
- sichere Header (`secure-headers`)
- Container-Härtung
- Hostname-basierte Routen für Weaviate & Traefik Dashboard
- Healthchecks & lokale Bindung (`127.0.0.1`)

Dieses Proxy-Setup schützt die Weaviate-Instanz zuverlässig vor direktem
externem Zugriff und stellt einen Production-ähnlichen Betrieb sicher.

Im Unterordner **[example-clients-python](./reverse-proxy-traefik/example-clients-python)** sind Python-Client-Beispiele zum Zugriff auf die Datenbank enthalten.

---


## 🎛️ Start & Verwaltung

### ▶️ Starten

```bash
# einmalig: .env bereitstellen/prüfen
docker compose --env-file .env pull
docker compose --env-file .env up -d
```

### ⏹️ Stoppen

```bash
docker compose --env-file .env down
```

### 🧾 Logs anzeigen

```bash
docker compose --env-file .env logs -f weaviate
```

### 🧹 Daten entfernen (optional)

```bash
# Achtung: löscht persistente Daten
docker volume rm <projektname>_weaviate_data
```

---

## 🧪 Funktionsprüfung (Healthcheck)

**Readiness-Endpoint abrufen (mit API-Key):**
```bash
curl -i "http://localhost:${WEAVIATE_PORT}/v1/.well-known/ready"   -H "x-api-key: example-key-12345"
```

- Erwartet: `HTTP/1.1 200 OK`  
- Bei `401/403`: API-Key oder Reihenfolge Keys↔Users in `.env` prüfen.

**Hinweis zu Modulen (optional):**  
Wenn `ENABLE_MODULES` gesetzt ist (z. B. `text2vec-ollama,generative-ollama`), werden **Endpunkt & Modell** pro **Collection** im Client festgelegt, z. B.:

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

© 2025 – Sichere Datenbankkonfigurationen
