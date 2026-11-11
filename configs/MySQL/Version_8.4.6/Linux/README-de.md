# MySQL – Linux mit Docker Compose

[English](README.md) · [Datenbankübersicht](../../README-de.md) · [BSI-Alignment](../../../README-de.md#bsi-alignment)

Diese Vorlage kombiniert **MySQL 8.4.6** und Adminer. Die Datenbankkonfiguration liegt in [`my.cnf`](my.cnf), die Compose-Datei in [`mysql-compose/docker-compose.yml`](mysql-compose/docker-compose.yml).

- [Vorbereitung](#vorbereitung)
- [Start und Anmeldung](#start-und-anmeldung)
- [Konfiguration prüfen](#konfiguration-prüfen)
- [Parameterreferenz](#parameterreferenz)
  - [Sicherheit & Netzwerk](#sicherheit--netzwerk)
  - [TLS/SSL](#tlsssl)
  - [Speicher & Performance](#speicher--performance)
  - [Zeichensätze](#zeichensätze)
  - [Protokollierung](#protokollierung)
  - [Binärlog](#binärlog)
  - [mysqldump](#mysqldump)
- [Dateien und Betrieb](#dateien-und-betrieb)
- [Referenzen](#referenzen)

## Vorbereitung

Voraussetzungen sind Docker mit Compose und ausreichend Arbeitsspeicher für die konfigurierten Puffer. Die Vorlage setzt `innodb_buffer_pool_size=4G`; diesen Wert vor dem Start an den verfügbaren Speicher anpassen.

Alle folgenden Compose-Befehle werden im Verzeichnis `mysql-compose/` ausgeführt. Ausgehend von diesem README-Verzeichnis:

```bash
cd mysql-compose
cp .env.example .env
mkdir -p ssl
```

1. In `.env` sämtliche Beispielpasswörter ersetzen und bei Bedarf `DB_PORT` anpassen.
2. Nach der [TLS-Anleitung](../../../../docs/TLS-de.md) Zertifikate bereitstellen: `ssl/ca-cert.pem`, `ssl/server-cert.pem` und `ssl/server-key.pem`. Die erzeugten Dateien gegebenenfalls passend umbenennen; den privaten CA-Schlüssel nicht kopieren.
3. Die Zertifikats-SANs müssen `localhost` und den Compose-Servicenamen `mysql` abdecken, damit sowohl der Host-Client als auch Adminer den Servernamen prüfen können.
4. Die Mounts sind bereits enthalten. Das Startskript kopiert nur die drei benötigten PEM-Dateien aus dem schreibgeschützten `ssl/` in ein privates tmpfs-Verzeichnis und setzt Eigentümer und Rechte für `mysql`. Der private Schlüssel erhält Modus `0600`; das Logverzeichnis wird im persistenten Volume `mysql_logs` mit passenden Rechten angelegt.
5. Das öffentliche CA-Zertifikat `ssl/ca-cert.pem` muss auch für den Adminer-Container lesbar sein, beispielsweise mit Modus `0644`. Die privaten Schlüssel verbleiben zugriffsbeschränkt. Danach die Konfiguration prüfen:

```bash
docker compose config --quiet
```

TLS ist in `my.cnf` bereits mit expliziten Zertifikatspfaden und `require_secure_transport=ON` konfiguriert. Ohne die vorherige Zertifikatseinbindung ist die Vorlage nicht startfertig.

Das festgelegte MySQL-8.4.6-Image verwendet beim Bootstrap eine temporäre Client-Optionsdatei. Deshalb darf `MYSQL_ROOT_PASSWORD` keine doppelten Anführungszeichen, Backslashes oder Zeilenumbrüche enthalten. Das Startskript prüft dies vor der Initialisierung; ein langes zufällig erzeugtes Passwort, beispielsweise aus `openssl rand -hex 32`, vermeidet diese Einschränkung. Sie betrifft das Bootstrap-Root-Passwort, nicht das Anwendungspasswort.

## Start und Anmeldung

```bash
docker compose up -d
docker compose ps
docker compose logs --tail 100 mysql
```

Die Host-Ports sind auf `127.0.0.1` beschränkt: Datenbank `${DB_PORT:-3306}`, Adminer `8080`. `bind_address=0.0.0.0` betrifft die Interfaces **im Container** und wird für Verbindungen aus anderen Containern benötigt.

Die Variablen `MYSQL_USER` und `MYSQL_PASSWORD` legen beim ersten Start ein Anwendungskonto für `MYSQL_DATABASE` an. `MYSQL_ROOT_PASSWORD` gehört zum Administrationskonto. Initialisierungsskripte unter `initdb/` werden nur bei einem leeren Daten-Volume ausgeführt; Änderungen an `.env` ändern keine bestehenden Benutzerpasswörter.

Für eine administrative Prüfung über den lokalen Socket:

```bash
docker compose exec mysql mysql -uroot -p
```

Adminer ist unter `http://127.0.0.1:8080` erreichbar; `mysql` ist als Server vorbelegt. Mit dem Anwendungskonto anmelden. Die enthaltene Erweiterung `adminer-tls.php` aktiviert TLS mit CA- und Servernamensprüfung für die Datenbankverbindung. Die lokale Adminer-Weboberfläche selbst verwendet HTTP.

## Konfiguration prüfen

Die Tabellen unten enthalten Empfehlungen; die tatsächlich gesetzten Werte stehen in `my.cnf`. Im DBMS unter anderem `SHOW VARIABLES LIKE 'require_secure_transport';`, `SHOW VARIABLES LIKE 'ssl_ca';` und `SHOW GRANTS;` prüfen. Die Datei `initdb/check_config.sql` enthält weitere lesende Prüfungen und kann aus einer administrativen Sitzung aufgerufen werden.

Für den TLS-Test einen Client mit den oben erzeugten CA-Dateien verwenden und den Zertifikatsnamen prüfen. Ein Socket-Login und ein erfolgreicher Healthcheck belegen keine verschlüsselte TCP-Verbindung.

Für einen TCP-Test vom Host mit installiertem MySQL-Client im Compose-Verzeichnis ausführen. Port und Konto an `.env` anpassen; der Zertifikats-SAN muss `localhost` enthalten:

```bash
mysql --protocol=TCP --host=localhost --port=3306 --user=appuser --password --ssl-mode=VERIFY_IDENTITY --ssl-ca=ssl/ca-cert.pem
```

In dieser Verbindung `SHOW SESSION STATUS LIKE 'Ssl_cipher';` prüfen.

## Parameterreferenz

### Sicherheit & Netzwerk

| Option              | Bedeutung                        | Empfehlung |
|---------------------|----------------------------------|------------|
| `bind_address`      | Bind-IP                          | `127.0.0.1` oder VPN-IP; (`0.0.0.0` im Container; Host-Port nur auf `127.0.0.1`) |
| `skip_networking`   | TCP/IP deaktivieren              | `0`; nur `1`, wenn ausschließlich Socket |
| `skip_name_resolve` | DNS-Lookups vermeiden            | `1`; nutze IPs in `CREATE USER` |
| `max_connections`   | Maximale Verbindungen            | 100–500 nach Bedarf |
| `local_infile`      | `LOAD DATA LOCAL INFILE`         | `0` (deaktiviert) |
| `secure_file_priv`  | Ordner für Import/Export         | Dedizierten Pfad setzen oder `NULL` (sperren) |

### TLS/SSL

| Option                      | Bedeutung                    | Empfehlung |
|-----------------------------|------------------------------|------------|
| `ssl-ca` / `ssl-cert` / `ssl-key` | CA/Server-Zertifikate | Pfade setzen, Rechte `600`, Owner `mysql:mysql` |
| `require_secure_transport`  | Nur TLS/Socket-Verbindungen  | `ON` nach TLS-Einrichtung |

### Speicher & Performance

| Option                       | Bedeutung                    | Empfehlung |
|------------------------------|------------------------------|------------|
| `innodb_buffer_pool_size`    | Hauptcache InnoDB            | An verfügbaren RAM und Workload anpassen |
| `innodb_redo_log_capacity`   | Redo-Log-Gesamtgröße (neu)   | 1–4 GB je nach Schreiblast |
| `innodb_file_per_table`      | Separater Tablespace         | `1` |
| `innodb_flush_log_at_trx_commit` | Haltbarkeit vs. Performance | `1` (ACID), `2` bei Bedarf |
| `innodb_flush_method`        | I/O-Strategie                | `O_DIRECT` optional |

### Zeichensätze

| Option                  | Bedeutung            | Empfehlung |
|-------------------------|----------------------|------------|
| `character_set_server`  | Standardzeichensatz  | `utf8mb4` |
| `collation_server`      | Sortierung           | `utf8mb4_0900_ai_ci` |

### Protokollierung

| Option                       | Bedeutung                       | Empfehlung |
|------------------------------|---------------------------------|------------|
| `log_error`                  | Fehlerlog                       | Datei oder Container-Logs |
| `slow_query_log`             | Langsame Abfragen               | `1` |
| `slow_query_log_file`        | Pfad Slow-Query-Log             | z. B. `/var/log/mysql/mysql-slow.log` |
| `long_query_time`            | Schwelle „langsam“             | 1–2 s |
| `log_queries_not_using_indexes` | Abfragen ohne Index loggen  | Vorsichtig aktivieren |
| `general_log`                | Alle Statements (Debug)         | `0` in Prod |
| `general_log_file`           | Pfad für General Query Log     | z.B. `/var/log/mysql/mysql-general.log` |

### Binärlog

| Option                    | Bedeutung               | Empfehlung |
|---------------------------|-------------------------|------------|
| `log-bin` / `log_bin`     | Binärlog aktivieren     | Pfad setzen, Rotation beachten |
| `log-bin-index` / `log_bin_index` | Indexdatei      | Pfad setzen |
| `sync_binlog`             | Binlog-Sicherheit       | `1` |
| `binlog_expire_logs_seconds` | Aufbewahrung         | 7–14 Tage (604800–1209600) |

### mysqldump

| Option            | Bedeutung                  | Empfehlung |
|-------------------|----------------------------|------------|
| `quick`           | Zeilenweises Streaming     | Aktivieren |
| `quote-names`     | Backticks um Objekt-Namen  | Aktivieren |
| `max_allowed_packet` | Max. Paketgröße         | `64M` oder höher bei großen Dumps |
| *(CLI)*           | Konsistenter Dump          | `--single-transaction` (nicht in `my.cnf`) |

Bei Zertifikatswechseln die Quelldateien in `ssl/` ersetzen und `docker compose restart mysql` ausführen, damit die geschützten Laufzeitkopien neu erstellt werden. Anschließend die TLS-Verbindung erneut prüfen.

## Dateien und Betrieb

| Datei oder Mount | Zweck |
|-----------------|-------|
| `../my.cnf:/etc/mysql/conf.d/my.cnf:ro` | Serverkonfiguration |
| `./initdb:/docker-entrypoint-initdb.d:ro` | Initialisierung beim ersten Start |
| `mysql_data:/var/lib/mysql` | Persistente Daten |
| `./ssl:/run/tls-source:ro` | Zertifikatsquelle; private Laufzeitkopie unter `/etc/mysql/ssl` |
| `mysql_logs:/var/log/mysql` | Persistente Datenbanklogs |

Die Datenbank schreibt Fehler-, Slow-Query- und Binärlogs nach `/var/log/mysql`. `docker compose logs` zeigt die Container-Ausgabe; es ersetzt nicht die Auswertung dieser Dateien.

```bash
docker compose stop
docker compose start
docker compose down
```

`down` entfernt Container und Netzwerk; das Daten-Volume bleibt erhalten. Backups müssen separat geplant, geschützt und durch Restore-Tests geprüft werden. Die Init-Skripte und Binärlogs sind kein vollständiger Backup-Prozess. Bei mehreren Setups die festen Container-Namen und die standardmäßig gleichen Host-Ports anpassen.

## Referenzen

- [MySQL Docker-Image](https://hub.docker.com/_/mysql)
- [Adminer-Erweiterungen](https://www.adminer.org/en/plugins/)
- [Gemeinsame TLS-Anleitung](../../../../docs/TLS-de.md)
