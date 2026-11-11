# Weaviate 1.34.0 mit Traefik und TLS

[English](README.md) · [Weaviate-Basisvariante](../README-de.md) · [BSI-Alignment](../../../README-de.md#bsi-alignment)

Dieses eigenständige Compose-Setup stellt Weaviate über Traefik v3.5 per HTTPS bereit. Es verwendet das eigene Daten-Volume `weaviate_data_proxy`; Daten der Basisvariante werden nicht automatisch übernommen.

- [Vorbereitung und Netzwerkzugriff](#vorbereitung-und-netzwerkzugriff)
- [Zertifikat und Hostnamen](#zertifikat-und-hostnamen)
- [Start und TLS-Prüfung](#start-und-tls-prüfung)
- [Optionale Modellanbindung mit Ollama](#optionale-modellanbindung-mit-ollama)
- [Python-Beispiele](#python-beispiele)
- [Betrieb und Daten](#betrieb-und-daten)
- [Referenzen](#referenzen)

## Vorbereitung und Netzwerkzugriff

Voraussetzungen: Docker mit Compose, OpenSSL 3 für das folgende Zertifikatsbeispiel und freie Host-Ports. Alle Befehle beziehen sich auf dieses README-Verzeichnis und eine POSIX-Shell.

```bash
cp .env.example .env
```

In `.env` die API-Keys ersetzen und die Zuordnung zu `WEAVIATE_API_USERS` prüfen. `WEAVIATE_ROOT_USERS` bestimmt die Root-Identitäten; weiteren Nutzern passende Rollen zuweisen.

Die [Compose-Datei](docker-compose.yml) veröffentlicht die folgenden Zugänge:

| Zugang | Host-Bindung der Vorlage | Transport |
|--------|--------------------------|-----------|
| Weaviate REST | `127.0.0.1:8080` | HTTP, direkter lokaler Zugang |
| Weaviate gRPC | `127.0.0.1:50051` | Unverschlüsselt, standardmäßig veröffentlicht |
| Traefik | `127.0.0.1:80` und `127.0.0.1:443` | HTTP-Weiterleitung auf HTTPS; TLS-Termination |
| Ollama, nur mit Profil `ollama` | `127.0.0.1:11434` | HTTP |

Die Traefik-Port-Mappings sind bereits auf `127.0.0.1:80:80` und `127.0.0.1:443:443` begrenzt. **Dashboard und unsicherer API-Zugang sind deaktiviert; es gibt keine Dashboard-Route.** Für gewollten Remote-Zugriff ausschließlich die benötigten API-Freigaben und Firewall-Regeln anpassen.

Der direkte lokale HTTP-/gRPC-Zugang bleibt parallel verfügbar. TLS endet bei Traefik; die interne Verbindung zu Weaviate verwendet HTTP. Die im Compose gesetzten Container-Härtungsoptionen gelten für Weaviate, nicht pauschal für alle Services. Das Routing wird in `dynamic/tls.yml` über den File-Provider festgelegt; Traefik benötigt keinen Docker-Socket und keinen Docker-Provider. `WEAVIATE_DOMAIN` und `WEAVIATE_PORT` werden dem Traefik-Container für die dynamische Vorlage übergeben.

## Zertifikat und Hostnamen

Die Domainnamen in `.env`, den Zertifikats-SANs und der Client-Verbindung müssen übereinstimmen. Für die unveränderten Beispieldomains:

```bash
mkdir -p certs
openssl req -x509 -newkey rsa:4096 -noenc -keyout certs/local.key -out certs/local.crt -days 365 -subj "/CN=weaviate.docker.localhost" -addext "basicConstraints=critical,CA:FALSE" -addext "keyUsage=critical,digitalSignature,keyEncipherment" -addext "extendedKeyUsage=serverAuth" -addext "subjectAltName=DNS:weaviate.docker.localhost"
chmod 600 certs/local.key
```

Das ist ein lokales selbstsigniertes Serverzertifikat. `certs/local.crt` wird bei den Tests ausdrücklich als vertrauenswürdig angegeben; es ersetzt keine Zertifikatsverwaltung für andere Umgebungen. Die Datei [`dynamic/tls.yml`](dynamic/tls.yml) bindet `local.crt` und `local.key` ein und definiert die Header-Middleware. Außerdem enthält sie Router und Backend-Service; die Domain und der Backend-Port werden beim Laden aus den Traefik-Umgebungsvariablen eingesetzt.

Die Beispieldomains müssen auf den lokalen Host zeigen. Falls die lokale Namensauflösung dies nicht bereits erledigt, folgende Einträge in `/etc/hosts` beziehungsweise unter Windows in `C:\Windows\System32\drivers\etc\hosts` ergänzen:

```text
127.0.0.1 weaviate.docker.localhost
```

## Start und TLS-Prüfung

```bash
docker compose config --quiet
docker compose pull
docker compose up -d
docker compose ps
```

Die `.env.example` dieser Proxy-Variante deaktiviert Embedding-Module. Für die folgenden REST-Prüfungen ist Ollama nicht nötig. Den API-Key-Platzhalter durch den in `.env` gesetzten Wert ersetzen:

```bash
export WEAVIATE_API_KEY='REPLACE_WITH_KEY_FROM_ENV'
curl --fail-with-body --cacert certs/local.crt https://weaviate.docker.localhost/v1/.well-known/ready
curl --fail-with-body --cacert certs/local.crt https://weaviate.docker.localhost/v1/meta -H "Authorization: Bearer ${WEAVIATE_API_KEY}"
curl --fail-with-body --cacert certs/local.crt https://weaviate.docker.localhost/v1/schema -H "Authorization: Bearer ${WEAVIATE_API_KEY}"
```

Die Befehle prüfen das Serverzertifikat; `-k` wird nicht benötigt. Readiness bestätigt nur Betriebsbereitschaft. Der authentifizierte Aufruf muss zusätzlich erfolgreich sein. Die Compose-Healthchecks prüfen den lokalen HTTP-Endpunkt und belegen keine funktionierende TLS- oder API-Key-Prüfung.

## Optionale Modellanbindung mit Ollama

Der Service `ollama` ist bereits mit einem Compose-Profil definiert. In `.env` zunächst setzen:

```dotenv
ENABLE_API_BASED_MODULES=true
ENABLE_MODULES=text2vec-ollama,generative-ollama
```

Dann starten und Modelle laden:

```bash
docker compose --profile ollama up -d
docker compose exec ollama ollama pull nomic-embed-text
docker compose exec ollama ollama pull llama3.2
```

Der Endpoint **aus Weaviate** ist `http://ollama:11434`. Der Endpoint **für den Client auf dem Host** ist `http://127.0.0.1:11434`. Modellnamen und Endpoints werden pro Collection konfiguriert. Das Ollama-Image ist in dieser Vorlage mit `latest` referenziert; vor reproduzierbarem Einsatz einen passenden Versionsstand festlegen.

## Python-Beispiele

- [REST-Beispiel](example-clients-python/weaviate-rest-minimal.py): erstellt `Question`, lädt Beispieldaten aus dem Internet und schreibt Objekte.
- [Ollama-Beispiel](example-clients-python/weaviate-ollama-client.py): prüft Modelle, erstellt beziehungsweise verwendet `QuestionOllama`, fügt ein Objekt ein und führt eine generative Suche aus.

Beide vorhandenen Skripte verbinden sich direkt mit dem lokalen HTTP-Endpunkt, das Ollama-Beispiel zusätzlich mit lokalem gRPC. Sie prüfen den Traefik-TLS-Zugang nicht. `API_KEY` in den Skripten vor dem Aufruf an den eigenen Wert anpassen. Die Beispiele verändern Daten und können bei wiederholtem Aufruf weitere Objekte erzeugen.

In einer Python-Umgebung aus diesem README-Verzeichnis, nach der für das jeweilige Beispiel nötigen Vorbereitung:

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install requests 'weaviate-client>=4,<5'
python example-clients-python/weaviate-rest-minimal.py
python example-clients-python/weaviate-ollama-client.py
```

Das Ollama-Beispiel setzt aktivierte Module und geladene Modelle voraus. Eine zum Server passende Version des Python-Clients verwenden; die Installation oben begrenzt lediglich die Hauptversion auf 4.

## Betrieb und Daten

```bash
docker compose logs --tail 100 weaviate-db-proxy traefik
docker compose stop
docker compose start
docker compose down
```

`down` erhält die Daten-Volumes. Backups, Aufbewahrung und Restore-Tests separat einrichten. Basis- und Proxy-Variante verwenden unterschiedliche Weaviate-Volumes und kollidieren ohne Portanpassung auf den lokalen Standardports.

## Referenzen

- [Weaviate-Authentifizierung](https://docs.weaviate.io/deploy/configuration/authentication)
- [Traefik: Dashboard und Zugriffsschutz](https://doc.traefik.io/traefik/v3.5/operations/dashboard/)
- [Traefik: File-Provider](https://doc.traefik.io/traefik/reference/install-configuration/providers/others/file/)
- [Gemeinsame TLS-Anleitung](../../../../docs/TLS-de.md)
