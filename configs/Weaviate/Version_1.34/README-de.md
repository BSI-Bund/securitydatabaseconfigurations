# Weaviate 1.34.0 – Docker Compose

[English](README.md) · [Datenbankübersicht](../README-de.md) · [BSI-Alignment](../../README-de.md#bsi-alignment)

Diese Variante stellt eine einzelne Weaviate-Instanz mit lokaler HTTP-API bereit. Die [Traefik-Variante](reverse-proxy-traefik/README-de.md) ist ein eigenständiges Setup mit separatem Daten-Volume. Wegen gleicher Standardports beide Varianten nicht unverändert gleichzeitig starten.

- [Vorbereitung](#vorbereitung)
- [Start und wirksame Einstellungen](#start-und-wirksame-einstellungen)
- [Verbindung prüfen](#verbindung-prüfen)
- [Parameterreferenz](#parameterreferenz)
- [Daten und Betrieb](#daten-und-betrieb)
- [Referenzen](#referenzen)

## Vorbereitung

Docker mit Compose wird benötigt. Alle Befehle werden in diesem README-Verzeichnis ausgeführt.

```bash
cp .env.example .env
```

In `.env` die Beispiel-API-Keys durch eigene Werte ersetzen. `WEAVIATE_API_KEYS` und `WEAVIATE_API_USERS` werden anhand ihrer Reihenfolge einander zugeordnet. Nur die in `WEAVIATE_ROOT_USERS` genannten Identitäten besitzen automatisch Root-Rechte; für weitere Nutzer passende RBAC-Rollen vergeben.

Die Basisvorlage aktiviert in `.env.example` bereits `text2vec-ollama` und `generative-ollama`, enthält jedoch keinen Ollama-Service. Für einen einfachen REST-Test ohne Modellanbindung in `.env` setzen:

```dotenv
ENABLE_API_BASED_MODULES=false
ENABLE_MODULES=
```

Für eine Modellanbindung stattdessen erreichbare Endpoints und Modelle pro Collection konfigurieren. Die [Traefik-Anleitung](reverse-proxy-traefik/README-de.md) beschreibt eine Variante mit optionalem Ollama-Service.

## Start und wirksame Einstellungen

```bash
docker compose config --quiet
docker compose pull
docker compose up -d
docker compose ps
```

Die [Compose-Datei](docker-compose.yml) verwendet das Image `cr.weaviate.io/semitechnologies/weaviate:${WEAVIATE_VERSION}` und bindet die HTTP-API ausschließlich an `127.0.0.1:${WEAVIATE_PORT}`. Mit den Vorlagenwerten ist das `http://127.0.0.1:8080`. gRPC-Port `50051` ist in dieser Variante nicht veröffentlicht.

Die Vorlage aktiviert API-Key-Authentifizierung und RBAC und deaktiviert anonymen API-Zugriff. Die folgenden Container-Einstellungen sind **bereits gesetzt**: `no-new-privileges`, `cap_drop: [ALL]`, schreibgeschütztes Root-Dateisystem, beschreibbares Daten-Volume, temporäres `/tmp`, Speicherlimit `4g` und CPU-Limit `2.0`. Ressourcen und benötigte Schreibpfade an den Workload anpassen.

Die Verbindung dieser Basisvariante nutzt HTTP. Für Zugriffe über nicht vertrauenswürdige Netze ist eine passende TLS-Anbindung erforderlich; siehe [Traefik](reverse-proxy-traefik/README-de.md). Die gesetzten Härtungsoptionen ersetzen keine Prüfung der gesamten Betriebsumgebung.

## Verbindung prüfen

Compose liest `.env` zur Konfiguration; die Variablen werden dadurch nicht automatisch in die aufrufende Shell exportiert. Die folgenden Befehle verwenden deshalb den konkreten Standardport. Bei geändertem `WEAVIATE_PORT` entsprechend anpassen.

```bash
curl --fail-with-body http://127.0.0.1:8080/v1/.well-known/ready
export WEAVIATE_API_KEY='REPLACE_WITH_KEY_FROM_ENV'
curl --fail-with-body http://127.0.0.1:8080/v1/meta -H "Authorization: Bearer ${WEAVIATE_API_KEY}"
```

Den Platzhalter durch einen konfigurierten API-Key ersetzen. Der Readiness-Endpunkt prüft die Betriebsbereitschaft und belegt keine funktionierende Authentifizierung. Den authentifizierten API-Aufruf zusätzlich prüfen; bei `401` oder `403` API-Key, Benutzerzuordnung und RBAC-Rechte prüfen.

## Parameterreferenz

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

## Daten und Betrieb

`weaviate_data` wird an `${WEAVIATE_DATA_PATH}` gemountet, standardmäßig `/var/lib/weaviate`. Das Volume ist persistent, aber kein Backup. Ein konsistentes Sicherungsverfahren und Restore-Tests für die eigene Umgebung einrichten.

```bash
docker compose logs --tail 100 weaviate
docker compose stop
docker compose start
docker compose down
```

`down` erhält das Daten-Volume. Änderungen an `.env` mit `docker compose up -d` übernehmen und danach die wirksamen Einstellungen prüfen.

## Referenzen

- [Weaviate: Authentifizierung und Bearer-Header](https://docs.weaviate.io/deploy/configuration/authentication)
- [Gemeinsame TLS-Anleitung](../../../docs/TLS-de.md)
