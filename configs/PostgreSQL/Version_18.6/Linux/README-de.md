# PostgreSQL - Linux (Docker Compose)

[English](README.md) · [Datenbankübersicht](../../README-de.md) · [BSI-Alignment](../../../README-de.md#bsi-alignment)

**Versionszuordnung:** Die unveränderte Vorlage gilt für die geprüften Versionen **18.6 und 18.7**. Der Ordner `Version_18.6` bezeichnet die Vorlagenbasis. `POSTGRES_VERSION` wählt das Image; Standard ist `18.7`. Weitere Versionen müssen nach der [gemeinsamen Versionsregel](../../../README-de.md#versionen-und-konfigurationsordner) geprüft werden. Der Windows-Prüfstand steht separat in der [Datenbankübersicht](../../README-de.md#versionsgültigkeit-und-prüfstand).

- [Sicherheitsstatus](#sicherheitsstatus)
- [Start](#start)
- [TLS-Modus](#tls-modus)
- [Services](#services)
  - [postgres](#postgres)
  - [adminer](#adminer)
- [Adminer-Login](#adminer-login)
- [Umgebungsvariablen](#umgebungsvariablen)
- [Parameterreferenz](#parameterreferenz)
  - [Netzwerk und Authentifizierung](#netzwerk-und-authentifizierung)
  - [TLS](#tls)
  - [Speicher und Dauerhaftigkeit](#speicher-und-dauerhaftigkeit)
  - [Logging und Diagnose](#logging-und-diagnose)
  - [Laufzeitlimits](#laufzeitlimits)
- [Backup und Restore](#backup-und-restore)
- [BSI-Alignment](#bsi-alignment)
- [Volumes und Ports](#volumes-und-ports)
- [Betrieb](#betrieb)
- [Referenzen](#referenzen)

## Sicherheitsstatus

Die Basisvariante ist für abgegrenzte lokale Tests vorgesehen. Für produktive TCP-Verbindungen die TLS-Variante verwenden und die gemeinsamen Freigabekriterien erfüllen. Enthalten sind:

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

Für bestehende 18.x-Instanzen die [Herstellerhinweise zu 18.7](https://www.postgresql.org/docs/release/18.7/) vor dem Image-Wechsel lesen. Dort werden unter anderem gegebenenfalls nötiges `REINDEX`, eine neue Vollsicherung bei inkrementellen Backups und Anforderungen an C-Erweiterungen beschrieben. Die Laufzeittests dieser Vorlage belegen Neuinstallation sowie Backup/Restore, keine allgemeine Upgrade-Freigabe für Bestandsdaten.

Der erste Befehlsblock wechselt aus diesem README-Verzeichnis einmalig nach `postgres-compose/`. Alle weiteren Shell-Befehle dieser Anleitung werden dort ausgeführt. `.env` vor dem Start bearbeiten und sämtliche Beispiel-Secrets ersetzen.

Dieses Setup stellt standardmäßig PostgreSQL 18.7 und eine Adminer-Weboberfläche für lokale Administration bereit.
Es basiert auf offiziellen Images:

- [PostgreSQL auf Docker Hub](https://hub.docker.com/_/postgres)
- [Adminer auf Docker Hub](https://hub.docker.com/_/adminer)

```bash
cd postgres-compose
cp .env.example .env
docker compose up -d
```

Das Standardsetup ist bewusst ohne Zertifikate startfähig. PostgreSQL wird am Host nur auf `127.0.0.1:${DB_PORT:-5432}` veröffentlicht.

Die Init-Skripte laufen nur bei einem leeren Daten-Volume. Änderungen an `.env` ändern keine bereits angelegten Datenbanken oder Rollenpasswörter; bestehende Rollenpasswörter in einer administrativen SQL-Sitzung ändern.

---

## TLS-Modus

PostgreSQL kann TLS- und Nicht-TLS-Verbindungen auf demselben Port annehmen. Um TLS für TCP-Clients zu erzwingen, muss TLS in `postgresql.conf` aktiviert und in `pg_hba.conf` mit `hostssl` geregelt werden.

Für lokale Tests:

```bash
./scripts/up-local-tls.sh
```

Dieses Skript erzeugt lokale Zertifikate, falls sie fehlen, startet die TLS-Compose-Variante, wartet auf den Healthy-Status, prüft eine TLS-Verbindung und prüft, dass Nicht-TLS-TCP-Zugriff abgelehnt wird.

Der Test verwendet Datenbankname und Anwendungspasswort aus der wirksamen Container-Konfiguration, also auch nach Anpassung von `.env`. Für ein anderes Prüfkonto `POSTGRES_TLS_TEST_USER` und `POSTGRES_TLS_TEST_PASSWORD` setzen.

Adminer kann im TLS-Modus weiter genutzt werden. Der Server bleibt `postgres`; als Login sind `app_admin` oder `app_reader` vorgesehen. Der Override erzwingt für Adminers Datenbankverbindung `verify-full` und bindet nur das öffentliche CA-Zertifikat in Adminer ein. Das Serverzertifikat muss deshalb auch den SAN `DNS:postgres` enthalten. PostgreSQL akzeptiert TCP-Verbindungen dann nur verschlüsselt. Die Adminer-Weboberfläche selbst bleibt ausschließlich für lokale Tests per HTTP auf `127.0.0.1:8080` erreichbar.

Manueller TLS-Ablauf:

```bash
./scripts/generate-local-tls.sh
docker compose -f docker-compose.yml -f docker-compose.tls.yml up -d
```

Die TLS-Variante nutzt:

- `../postgresql-tls.conf`
- `../pg_hba-tls.conf`
- `./ssl/server.crt`
- `./ssl/server.key`
- `./ssl/ca.crt`

Nur diese drei Zertifikats-/Schlüsseldateien werden einzeln in den Datenbankcontainer gemountet. Der Generator speichert die private Entwicklungs-CA separat unter `${XDG_DATA_HOME:-$HOME/.local/share}/db-sec-conf/postgresql-dev-ca`; mit `CA_DIR` kann ein anderes geschütztes Verzeichnis außerhalb des Repositorys gewählt werden. Eine bestehende CA dort wird wiederverwendet. Ältere `ssl/ca.key`-Dateien außerhalb des bereitgestellten Zertifikatsverzeichnisses sichern; sie werden vom TLS-Override nicht eingebunden.

Client-Beispiel mit Zertifikatsprüfung:

```bash
PGPASSWORD='S3cur3P@ss!' psql "host=localhost port=5432 dbname=appdb user=app_admin sslmode=verify-full sslrootcert=ssl/ca.crt"
```

Für produktionsnahe Deployments die lokal generierte CA und das Serverzertifikat durch Zertifikate der eigenen CA ersetzen. `server.key` muss auf den PostgreSQL-Service-User beschränkt bleiben.

---

## Services

### postgres

- Image `postgres:18.7`
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

Die Tabelle zeigt die Vorlagenwerte. Für den Login die tatsächlich in `.env` gesetzten Werte verwenden:

| Feld | Schreibzugriff | Nur Lesen |
|------|----------------|-----------|
| System | `PostgreSQL` | `PostgreSQL` |
| Server | `postgres` | `postgres` |
| Benutzer | `app_admin` | `app_reader` |
| Passwort | `S3cur3P@ss!` | `Read0nly!` |
| Datenbank | `appdb` | `appdb` |

Der Benutzer `postgres` ist ein Superuser. Er wird vom Container zum Initialisieren, für Backup/Restore und für administrative Prüfungen benötigt, sollte aber nicht für normalen Anwendungs- oder Adminer-Zugriff genutzt werden.

Hinweis: Wenn Adminer oben `postgres` anzeigt, ist damit der Compose-Service/Servername gemeint. Der angemeldete Datenbankbenutzer steht separat in der URL bzw. im Login-Formular.

`app_admin` und `app_reader` sind Rollen mit `LOGIN`, also Datenbankbenutzer. `app_admin` erhält `CREATE` im Schema `public`, `SELECT`/`INSERT`/`UPDATE`/`DELETE` auf vorhandenen Tabellen sowie Sequenzrechte. `app_reader` erhält `SELECT`. `app_admin` besitzt keine allgemeinen Administrationsrechte; `ALTER` und `DROP` setzen im Regelfall Objekteigentum voraus. Die vom Bootstrap-Konto angelegte Tabelle `public.users` gehört weiterhin diesem Konto.

---

## Umgebungsvariablen

Beispielwerte liegen in `postgres-compose/.env.example`. Alle Secrets vor Nutzung ändern:

```dotenv
POSTGRES_VERSION=18.7
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

Zertifikatserstellung ist auch in der [TLS-Anleitung](../../../../docs/TLS-de.md) beschrieben.

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

RPO bezeichnet den maximal akzeptablen Datenverlust, RTO die angestrebte Wiederherstellungszeit. Der Restore überschreibt die im Archiv gespeicherte Datenbank. Anwendungen vorher anhalten und den von `backup.sh` ausgegebenen Pfad einsetzen:

```bash
./scripts/backup.sh
CONFIRM_RESTORE=appdb ./scripts/restore.sh backups/appdb-YYYYMMDDTHHMMSSZ.XXXXXX
```

`backup.sh` legt für jeden Lauf ein eigenes Verzeichnis mit Modus `0700` an. Darin liegen mit Modus `0600`:

- `database.dump`: logischer Custom-Format-Dump der Anwendungsdatenbank einschließlich Datenbankdefinition
- `globals.sql`: Rollen und globale Objekte aus `pg_dumpall --globals-only`
- `SHA256SUMS`: Prüfsummen beider Dateien; wird erst nach erfolgreichem Abschluss bereitgestellt

Gleichzeitige Aufrufe verwenden getrennte Verzeichnisse. Bei einem fehlgeschlagenen Backup wird das unvollständige Verzeichnis entfernt. Die Hilfsskripte unterstützen Datenbanknamen aus Buchstaben, Ziffern und Unterstrichen.

`restore.sh` nimmt das Sicherungsverzeichnis oder dessen `database.dump` entgegen. Vor dem Beenden von Verbindungen und Überschreiben der Datenbank prüft es die SHA-256-Prüfsumme des Dumps, liest das vollständige Archiv ohne SQL-Ausführung und vergleicht dessen Datenbanknamen mit `POSTGRES_DB` und `CONFIRM_RESTORE`. Für diese Prüfung wird eine private temporäre Kopie des Dumps auf dem Host angelegt; entsprechend freien Speicher vorsehen. Auch ältere flache Dumps bleiben mit ihrer ursprünglichen `SHA256SUMS-<Zeitstempel>.txt` nutzbar.

Der anschließende Restore verwendet die Datenbankdefinition aus dem Archiv und stellt damit auch Eigentümer, Datenbankrechte, Kommentar und datenbankspezifische Einstellungen wieder her. Wiederherstellung unter einem anderen Datenbanknamen ist über diesen Helfer nicht vorgesehen. Benötigte Rollen müssen in der Zielinstanz vorhanden sein; die Softwaredateien verwendeter Erweiterungen und andere externe Abhängigkeiten müssen bereitstehen. Globale Objekte werden nicht automatisch eingespielt; die passende `globals.sql` separat prüfen und bei Bedarf einspielen.

Nur Sicherungen aus vertrauenswürdiger Quelle verwenden: Prüfsummen erkennen Beschädigungen, authentifizieren aber den Absender nicht. Eine erfolgreiche Vorabprüfung ersetzt keinen Restore-Test mit den eigenen Daten und Abhängigkeiten. SQL-Fehler nach Beginn der Wiederherstellung können zum Abbruch führen; es gibt keinen automatischen vollständigen Rollback.

Backup-Frequenz, Aufbewahrung, Verschlüsselung, externe Ablage, Restore-Tests und RPO/RTO bleiben Betriebsaufgaben. Die Hilfsskripte richten weder Verschlüsselung noch Zeitplanung ein. Für Point-in-Time-Recovery zusätzlich WAL-Archivierung einrichten.

---

## BSI-Alignment

Für dieses Setup gilt das [gemeinsame BSI-Alignment für alle Datenbankvorlagen](../../../README-de.md#bsi-alignment). Die [zentrale Umsetzungsübersicht](../../../README-de.md#umsetzung-je-datenbank) beschreibt die Zuordnung für alle DBMS; die konkrete PostgreSQL-Konfiguration und die erforderlichen Betriebsaufgaben stehen in dieser README.

---

## Volumes und Ports

| Mount / Port | Beschreibung |
|--------------|--------------|
| `postgres_data:/var/lib/postgresql` | Persistentes Daten-Elternverzeichnis für PostgreSQL-18-Images |
| `./initdb:/docker-entrypoint-initdb.d:ro` | Initiale SQL-Skripte, nur beim ersten Start |
| `../postgresql.conf:/etc/postgresql/postgresql.conf:ro` | Basis-Serverkonfiguration |
| `../pg_hba.conf:/etc/postgresql/pg_hba.conf:ro` | Basis-Authentifizierungsregeln |
| `./ssl/{server.crt,server.key,ca.crt}` | Drei einzelne schreibgeschützte Datei-Mounts unter `/etc/postgresql/ssl/`, nur TLS-Modus |
| `127.0.0.1:5432` | PostgreSQL-Zugriff vom Host |
| `127.0.0.1:8080` | Adminer-Zugriff vom Host |

---

## Betrieb

Der folgende `up`-Befehl startet die Basisvariante ohne TLS. Für den TLS-Modus weiter unten das Startskript verwenden; ein einfaches `docker compose up -d` würde wieder die Basisdefinition anwenden. `pg_isready` prüft Erreichbarkeit, nicht eine erfolgreiche Anmeldung oder TLS-Namensprüfung.

```bash
docker compose up -d
docker compose logs -f
docker compose exec -e PGPASSWORD='S3cur3P@ss!' postgres psql -U app_admin -d appdb
docker compose exec -e PGPASSWORD='ChangeMe!Root123' postgres psql -U postgres -d appdb -f /docker-entrypoint-initdb.d/check_config.sql
docker compose down
```

PostgreSQL-, Image-, Host- und Plattform-Updates regelmäßig verfolgen und Upgrades vorab testen. Umfang, Weiterleitung und Aufbewahrung der Datenbanklogs für die eigene Umgebung festlegen.

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
- [PostgreSQL: libpq-TLS-Umgebungsvariablen](https://www.postgresql.org/docs/18/libpq-envars.html)
- [PostgreSQL Objektrechte und Eigentum](https://www.postgresql.org/docs/18/sql-grant.html)
- [PostgreSQL Verbindungseinstellungen](https://www.postgresql.org/docs/18/runtime-config-connection.html)
- [PostgreSQL Resource-Einstellungen](https://www.postgresql.org/docs/18/runtime-config-resource.html)
- [PostgreSQL WAL-Einstellungen](https://www.postgresql.org/docs/18/runtime-config-wal.html)
- [PostgreSQL Logging-Einstellungen](https://www.postgresql.org/docs/18/runtime-config-logging.html)
- [PostgreSQL Client-Timeout-Einstellungen](https://www.postgresql.org/docs/18/runtime-config-client.html)
- [Postgres Docker Official Image Dokumentation](https://github.com/docker-library/docs/blob/master/postgres/README.md)

© 2026 - Sichere Datenbankkonfigurationen
