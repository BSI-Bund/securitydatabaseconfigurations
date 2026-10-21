# <img src="https://www.vectorlogo.zone/logos/postgresql/postgresql-icon.svg" alt="PostgreSQL Logo" width="26"/> PostgreSQL - Linux (Docker Compose)

- [Sicherheitsstatus](#sicherheitsstatus)
- [Start](#start)
- [TLS-Modus](#tls-modus)
- [Services](#services)
- [Adminer-Login](#adminer-login)
- [Umgebungsvariablen](#umgebungsvariablen)
- [Parameterreferenz](#parameterreferenz)
- [Backup und Restore](#backup-und-restore)
- [BSI-Alignment](#bsi-alignment)
- [Volumes und Ports](#volumes-und-ports)
- [Betrieb](#betrieb)
- [Referenzen](#referenzen)

---

## Sicherheitsstatus

Dies ist eine sichere Baseline, aber keine Produktionsgarantie. Enthalten sind:

- Host-Port-Bindings nur auf localhost in Docker Compose
- SCRAM-SHA-256 für Passwortauthentifizierung
- getrennte Anwendungsrollen im Init-Skript
- explizite Regeln in `pg_hba.conf`
- konservative Einstellungen für Dauerhaftigkeit
- Logging für Verbindungen, Trennungen, DDL, langsame Queries und Lock-Wartezeiten
- eine optionale TLS-Compose-Variante

Das offizielle PostgreSQL-18-Image speichert Daten in einem hauptversionsspezifischen Pfad; dieses Compose-Setup mountet `/var/lib/postgresql` und setzt `PGDATA=/var/lib/postgresql/18/docker`, damit das dazu passt.

`POSTGRES_USER` ist der Bootstrap-Superuser des offiziellen PostgreSQL-Images und nicht für den normalen Anwendungszugriff gedacht. Für Adminer und Anwendungstests sind die Rollen `app_admin` und `app_reader` vorgesehen.

Vor produktiver Nutzung: Beispielpasswörter ersetzen, Netzwerkbereiche enger fassen, CA-signierte Zertifikate bereitstellen, Backup/WAL-Archivierung definieren, Restore testen und die gesamte Betriebsumgebung prüfen. Keine Beispielkonfiguration kann alle Sicherheitsanforderungen jeder Umgebung vollständig abdecken; Secret-Management, Verschlüsselung ruhender Daten, OS-Hardening, Firewall-Regeln, Patch-Management und Anwendungsschutz bleiben Teil des Deployments.

---

## Start

Dieses Setup stellt PostgreSQL 18.6 und eine Adminer-Weboberfläche für lokale Administration bereit.
Es basiert auf offiziellen Images:

- [PostgreSQL auf Docker Hub](https://hub.docker.com/_/postgres)
- [Adminer auf Docker Hub](https://hub.docker.com/_/adminer)

```bash
cd postgres-compose
cp .env.example .env
docker compose up -d
```

Das Standardsetup ist bewusst ohne Zertifikate startfähig. PostgreSQL wird am Host nur auf `127.0.0.1:${DB_PORT:-5432}` veröffentlicht.

---

## TLS-Modus

PostgreSQL kann TLS- und Nicht-TLS-Verbindungen auf demselben Port annehmen. Um TLS für TCP-Clients zu erzwingen, muss TLS in `postgresql.conf` aktiviert und in `pg_hba.conf` mit `hostssl` geregelt werden.

Für lokale Tests:

```bash
cd postgres-compose
./scripts/up-local-tls.sh
```

Dieses Skript erzeugt lokale Zertifikate, falls sie fehlen, startet die TLS-Compose-Variante, wartet auf den Healthy-Status, prüft eine TLS-Verbindung und prüft, dass Nicht-TLS-TCP-Zugriff abgelehnt wird.

Adminer kann im TLS-Modus weiter genutzt werden. Der Server bleibt `postgres`; als Login sind `app_admin` oder `app_reader` vorgesehen. PostgreSQL akzeptiert TCP-Verbindungen dann nur verschlüsselt. Die Adminer-Weboberfläche selbst bleibt lokal per HTTP auf `127.0.0.1:8080` erreichbar.

Manueller TLS-Ablauf:

```bash
cd postgres-compose
./scripts/generate-local-tls.sh
docker compose -f docker-compose.yml -f docker-compose.tls.yml up -d
```

Die TLS-Variante nutzt:

- `../postgresql-tls.conf`
- `../pg_hba-tls.conf`
- `./ssl/server.crt`
- `./ssl/server.key`
- `./ssl/ca.crt`

Client-Beispiel mit Zertifikatsprüfung:

```bash
PGPASSWORD='S3cur3P@ss!' psql "host=localhost port=5432 dbname=appdb user=app_admin sslmode=verify-full sslrootcert=ssl/ca.crt"
```

Für produktionsnahe Deployments die lokal generierte CA und das Serverzertifikat durch Zertifikate der eigenen CA ersetzen. `server.key` muss auf den PostgreSQL-Service-User beschränkt bleiben.

---

## Services

### postgres

- Image `postgres:18.6`
- Startet mit eigener `postgresql.conf` und `pg_hba.conf`
- Initialisiert mit Skripten aus `./initdb/`
- Speichert Daten im Volume `postgres_data`
- Nutzt `pg_isready` für Healthchecks

### adminer

- Weboberfläche für lokale Administration
- Läuft auf `127.0.0.1:8080`
- Zeigt auf den Service `postgres`
- Anmeldung mit `app_admin` oder `app_reader`; `postgres` nur für Bootstrap/Wartung
- Ist keine Production-Hardening-Maßnahme

---

## Adminer-Login

Empfohlene Login-Daten für das lokale Beispiel:

| Feld | Schreibzugriff | Nur Lesen |
|------|----------------|-----------|
| System | `PostgreSQL` | `PostgreSQL` |
| Server | `postgres` | `postgres` |
| Benutzer | `app_admin` | `app_reader` |
| Passwort | `S3cur3P@ss!` | `Read0nly!` |
| Datenbank | `appdb` | `appdb` |

Der Benutzer `postgres` ist ein Superuser. Er wird vom Container zum Initialisieren, für Backup/Restore und für administrative Prüfungen benötigt, sollte aber nicht für normalen Anwendungs- oder Adminer-Zugriff genutzt werden.

Hinweis: Wenn Adminer oben `postgres` anzeigt, ist damit der Compose-Service/Servername gemeint. Der angemeldete Datenbankbenutzer steht separat in der URL bzw. im Login-Formular.

---

## Umgebungsvariablen

Beispielwerte liegen in `postgres-compose/.env.example`. Alle Secrets vor Nutzung ändern:

```bash
POSTGRES_VERSION=18.6
TZ=Europe/Berlin
DB_PORT=5432
ADMINER_PORT=8080
POSTGRES_USER=postgres
POSTGRES_PASSWORD=ChangeMe!Root123
POSTGRES_DB=appdb
POSTGRES_APP_ADMIN_PASSWORD=S3cur3P@ss!
POSTGRES_APP_READER_PASSWORD=Read0nly!
PGDATA=/var/lib/postgresql/18/docker
```

---

## Parameterreferenz

### Netzwerk und Authentifizierung

| Option | Bedeutung | Empfehlung |
|--------|-----------|------------|
| `listen_addresses` | Interfaces, auf denen PostgreSQL lauscht | `*` im Container plus localhost-only Portbindung am Host |
| `port` | PostgreSQL-Port | `5432`, sofern die Umgebung nichts anderes verlangt |
| `max_connections` | Gleichzeitige Verbindungen | Mit 100 starten; für größere Workloads Pooling nutzen |
| `password_encryption` | Passwort-Hashverfahren | `scram-sha-256` |
| `pg_hba.conf` | Client-Authentifizierungsregeln | Explizite Netze erlauben; `scram-sha-256` verwenden |
| `pg_hba-tls.conf` | TLS-only Client-Authentifizierungsregeln | `hostssl` nutzen; versehentliches `hostnossl` ablehnen |

### TLS

| Option | Bedeutung | Empfehlung |
|--------|-----------|------------|
| `ssl` | Aktiviert TLS | `on` im TLS-Modus |
| `ssl_cert_file` | Serverzertifikat | `/etc/postgresql/ssl/server.crt` |
| `ssl_key_file` | Privater Serverschlüssel | `/etc/postgresql/ssl/server.key`, restriktive Berechtigungen |
| `ssl_ca_file` | CA-Zertifikat | `/etc/postgresql/ssl/ca.crt` |
| `ssl_min_protocol_version` | Minimale TLS-Version | `TLSv1.2` oder strenger, falls Clients es unterstützen |

Zertifikatserstellung ist auch in der Repository-[README](../../../../README-de.md#-tls-konfiguration) beschrieben.

### Speicher und Dauerhaftigkeit

| Option | Bedeutung | Empfehlung |
|--------|-----------|------------|
| `data_directory` | Datenbankdateien | `/var/lib/postgresql/18/docker` für das PostgreSQL-18-Docker-Image |
| `shared_buffers` | PostgreSQL-Buffer-Cache | Startwert ca. 25% RAM auf dedizierten Servern |
| `effective_cache_size` | Planner-Schätzung für Cache | Etwa 50-75% des verfügbaren Speichers |
| `work_mem` | Speicher pro Sort-/Hash-Operation | Vorsichtig tunen; multipliziert sich pro Operation |
| `fsync` | Schreibt WAL/Daten sicher auf Datenträger | `on` |
| `synchronous_commit` | Commit-Dauerhaftigkeit | `on` als sichere Vorgabe |
| `full_page_writes` | Crash-Sicherheit | `on` |
| `wal_level` | WAL-Detailgrad | `replica` für Backup-/Replikationsbereitschaft |

### Logging und Diagnose

| Option | Bedeutung | Empfehlung |
|--------|-----------|------------|
| `log_destination` | Log-Ziel | `stderr` in Containern |
| `logging_collector` | Datei-Logsammler | In Containern `off`; Docker-Logs nutzen |
| `log_connections` / `log_disconnections` | Sitzungsnachvollziehbarkeit | `all` / `on` |
| `log_checkpoints` | Checkpoint-Diagnose | `on` |
| `log_autovacuum_min_duration` | Autovacuum-Diagnose | `10min` als Basis |
| `log_min_error_statement` | Statements, die Fehler auslösen | `error` als Basis; auf sensible Query-Daten prüfen |
| `log_min_duration_statement` | Slow-Query-Schwelle | Startwert `1000` ms |
| `log_statement` | Statement-Logging | `ddl` für Schemaänderungen |
| `log_lock_waits` | Diagnose für Lock-Wartezeiten | `on` |

### Laufzeitlimits

| Option | Bedeutung | Empfehlung |
|--------|-----------|------------|
| `idle_in_transaction_session_timeout` | Beendet untätige offene Transaktionen | `10min` als Basis |
| `statement_timeout` | Laufzeitlimit für Abfragen | Pro Anwendung/Workload setzen |
| `lock_timeout` | Wartezeitlimit für Locks | Pro Anwendung/Workload setzen |

---

## Backup und Restore

Das Compose-Beispiel enthält Hilfsskripte für logische Backups:

```bash
cd postgres-compose
./scripts/backup.sh
CONFIRM_RESTORE=appdb ./scripts/restore.sh backups/appdb-YYYYMMDDTHHMMSSZ.dump
```

`backup.sh` erstellt:

- einen `pg_dump` im Custom-Format für die konfigurierte Anwendungsdatenbank
- eine `pg_dumpall --globals-only`-Datei für Rollen und globale Objekte
- eine SHA-256-Checksum-Datei

Das unterstützt einen einfachen Backup-Ablauf, ersetzt aber kein vollständiges Recovery-Konzept. Backup-Frequenz, Aufbewahrung, Verschlüsselung, externe Ablage, Restore-Tests und RPO/RTO müssen festgelegt werden. Für Point-in-Time-Recovery muss WAL-Archivierung ergänzt werden.

---

## BSI-Alignment

Diese Baseline ist an den BSI-Eckpunkten für Datenbanksysteme, dem BSI-Praxisleitfaden für sichere Datenbanksysteme und APP.4.3 ausgerichtet. Abgedeckt sind insbesondere Basishärtung, geregelte Einrichtung, verschlüsselte Datenbankanbindung, Monitoring/Logging und Backup-/Restore-Vorbereitung.

Für produktionsnahe Nutzung sollte die Konfiguration mit Schutzbedarf, Netzwerkfreigaben, Secret-Management, Backup/Restore und den vorhandenen Betriebsprozessen abgeglichen werden.

Siehe [BSI-Alignment-Hinweise](../BSI-Alignment-de.md) für die Checkliste.

---

## Volumes und Ports

| Mount / Port | Beschreibung |
|--------------|--------------|
| `postgres_data:/var/lib/postgresql` | Persistentes Daten-Elternverzeichnis für PostgreSQL-18-Images |
| `./initdb:/docker-entrypoint-initdb.d:ro` | Initiale SQL-Skripte, nur beim ersten Start |
| `../postgresql.conf:/etc/postgresql/postgresql.conf:ro` | Basis-Serverkonfiguration |
| `../pg_hba.conf:/etc/postgresql/pg_hba.conf:ro` | Basis-Authentifizierungsregeln |
| `./ssl:/etc/postgresql/ssl:ro` | TLS-Zertifikate, nur TLS-Modus |
| `127.0.0.1:5432` | PostgreSQL-Zugriff vom Host |
| `127.0.0.1:8080` | Adminer-Zugriff vom Host |

---

## Betrieb

```bash
docker compose up -d
docker compose logs -f
docker compose exec -e PGPASSWORD='S3cur3P@ss!' postgres psql -U app_admin -d appdb
docker compose exec -e PGPASSWORD='ChangeMe!Root123' postgres psql -U postgres -d appdb -f /docker-entrypoint-initdb.d/check_config.sql
docker compose down
```

TLS-Start mit einem Befehl:

```bash
./scripts/up-local-tls.sh
TLS=1 ./scripts/down.sh
```

Optionales Entfernen des Volumes:

```bash
docker volume rm <project>_postgres_data
```

---

## Referenzen

- [PostgreSQL 18 SSL/TLS-Dokumentation](https://www.postgresql.org/docs/18/ssl-tcp.html)
- [PostgreSQL `pg_hba.conf`-Dokumentation](https://www.postgresql.org/docs/18/auth-pg-hba-conf.html)
- [PostgreSQL Passwortauthentifizierung und SCRAM](https://www.postgresql.org/docs/18/auth-password.html)
- [PostgreSQL Rollenattribute](https://www.postgresql.org/docs/18/role-attributes.html)
- [PostgreSQL Verbindungseinstellungen](https://www.postgresql.org/docs/18/runtime-config-connection.html)
- [PostgreSQL Resource-Einstellungen](https://www.postgresql.org/docs/18/runtime-config-resource.html)
- [PostgreSQL WAL-Einstellungen](https://www.postgresql.org/docs/18/runtime-config-wal.html)
- [PostgreSQL Logging-Einstellungen](https://www.postgresql.org/docs/18/runtime-config-logging.html)
- [PostgreSQL Client-Timeout-Einstellungen](https://www.postgresql.org/docs/18/runtime-config-client.html)
- [Postgres Docker Official Image Dokumentation](https://github.com/docker-library/docs/blob/master/postgres/README.md)

© 2026 - Sichere Datenbankkonfigurationen
