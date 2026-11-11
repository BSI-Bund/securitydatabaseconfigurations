# MariaDB – Linux mit Docker Compose

[English](README.md) · [Datenbankübersicht](../../README-de.md) · [BSI-Alignment](../../../README-de.md#bsi-alignment)

Diese Vorlage kombiniert **MariaDB 11.8** und Adminer. Die Datenbankkonfiguration liegt in [`mariadb.cnf`](mariadb.cnf), die Compose-Datei in [`mariadb-compose/docker-compose.yml`](mariadb-compose/docker-compose.yml).

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

Alle folgenden Compose-Befehle werden im Verzeichnis `mariadb-compose/` ausgeführt. Ausgehend von diesem README-Verzeichnis:

```bash
cd mariadb-compose
cp .env.example .env
mkdir -p ssl
```

1. In `.env` sämtliche Beispielpasswörter ersetzen und bei Bedarf `DB_PORT` anpassen.
2. Nach der [TLS-Anleitung](../../../../docs/TLS-de.md) Zertifikate bereitstellen: `ssl/ca-cert.pem`, `ssl/server-cert.pem` und `ssl/server-key.pem`. Die erzeugten Dateien gegebenenfalls passend umbenennen; den privaten CA-Schlüssel nicht kopieren.
3. Die Zertifikats-SANs müssen `localhost` und den Compose-Servicenamen `mariadb` abdecken, damit sowohl der Host-Client als auch Adminer den Servernamen prüfen können.
4. Die Mounts sind bereits enthalten. Das Startskript kopiert nur die drei benötigten PEM-Dateien aus dem schreibgeschützten `ssl/` in ein privates tmpfs-Verzeichnis und setzt Eigentümer und Rechte für `mysql`. Der private Schlüssel erhält Modus `0600`; das Logverzeichnis wird im persistenten Volume `mariadb_logs` mit passenden Rechten angelegt.
5. Das öffentliche CA-Zertifikat `ssl/ca-cert.pem` muss auch für den Adminer-Container lesbar sein, beispielsweise mit Modus `0644`. Die privaten Schlüssel verbleiben zugriffsbeschränkt. Danach die Konfiguration prüfen:

```bash
docker compose config --quiet
```

TLS ist in `mariadb.cnf` bereits mit expliziten Zertifikatspfaden und `require_secure_transport=ON` konfiguriert. Ohne die vorherige Zertifikatseinbindung ist die Vorlage nicht startfertig.

## Start und Anmeldung

```bash
docker compose up -d
docker compose ps
docker compose logs --tail 100 mariadb
```

Die Host-Ports sind auf `127.0.0.1` beschränkt: Datenbank `${DB_PORT:-3306}`, Adminer `8080`. `bind_address=0.0.0.0` betrifft die Interfaces **im Container** und wird für Verbindungen aus anderen Containern benötigt.

Die Variablen `MARIADB_USER` und `MARIADB_PASSWORD` legen beim ersten Start ein Anwendungskonto für `MARIADB_DATABASE` an. `MARIADB_ROOT_PASSWORD` gehört zum Administrationskonto. Initialisierungsskripte unter `initdb/` werden nur bei einem leeren Daten-Volume ausgeführt; Änderungen an `.env` ändern keine bestehenden Benutzerpasswörter.

Für eine administrative Prüfung über den lokalen Socket:

```bash
docker compose exec mariadb mariadb -uroot -p
```

Adminer ist unter `http://127.0.0.1:8080` erreichbar; `mariadb` ist als Server vorbelegt. Mit dem Anwendungskonto anmelden. Die enthaltene Erweiterung `adminer-tls.php` aktiviert TLS mit CA- und Servernamensprüfung für die Datenbankverbindung. Die lokale Adminer-Weboberfläche selbst verwendet HTTP.

## Konfiguration prüfen

Die Tabellen unten enthalten Empfehlungen; die tatsächlich gesetzten Werte stehen in `mariadb.cnf`. Im DBMS unter anderem `SHOW VARIABLES LIKE 'require_secure_transport';`, `SHOW VARIABLES LIKE 'ssl_ca';` und `SHOW GRANTS;` prüfen. Die Datei `initdb/check_config.sql` enthält weitere lesende Prüfungen und kann aus einer administrativen Sitzung aufgerufen werden.

Für den TLS-Test einen Client mit den oben erzeugten CA-Dateien verwenden und den Zertifikatsnamen prüfen. Ein Socket-Login und ein erfolgreicher Healthcheck belegen keine verschlüsselte TCP-Verbindung.

Für einen TCP-Test vom Host mit installiertem MariaDB-Client im Compose-Verzeichnis ausführen. Port und Konto an `.env` anpassen; der Zertifikats-SAN muss `localhost` enthalten:

```bash
mariadb --protocol=TCP --host=localhost --port=3306 --user=appuser --password --ssl --ssl-verify-server-cert --ssl-ca=ssl/ca-cert.pem
```

In dieser Verbindung `SHOW SESSION STATUS LIKE 'Ssl_cipher';` prüfen.

## Parameterreferenz

### Sicherheit & Netzwerk

| Option              | Bedeutung                        | Empfehlung |
|---------------------|----------------------------------|------------|
| `bind_address`      | Bind-IP                          | `127.0.0.1` oder VPN-IP (`0.0.0.0` im Container; Host-Port nur auf `127.0.0.1`)|
| `skip_networking`   | TCP/IP deaktivieren              | `0`; nur `1`, wenn ausschließlich Socket |
| `skip_name_resolve` | DNS-Lookups vermeiden            | `1` |
| `max_connections`   | Maximale Clients                 | 100–500 je nach Workload |
| `local_infile`      | `LOAD DATA LOCAL INFILE`         | `0` (deaktiviert) |
| `secure_file_priv`  | Ordner für Import/Export         | Dediziertes Verzeichnis festlegen; in der Vorlage auskommentiert |
| `symbolic-links`    | Symlink-Nutzung                  | `0` (deaktiviert) |

### TLS/SSL

| Option    | Bedeutung            | Empfehlung |
|-----------|----------------------|------------|
| `ssl-ca`  | CA-Zertifikat        | z. B. `/etc/mysql/ssl/ca-cert.pem` |
| `ssl-cert`| Server-Zertifikat    | z. B. `/etc/mysql/ssl/server-cert.pem` |
| `ssl-key` | Server-Schlüssel     | z. B. `/etc/mysql/ssl/server-key.pem` |

> TLS-Zwang per SQL: `ALTER USER 'appuser'@'%' REQUIRE SSL;`

### Speicher & Performance

| Option                       | Bedeutung                | Empfehlung |
|------------------------------|--------------------------|------------|
| `innodb_buffer_pool_size`    | RAM für InnoDB           | An verfügbaren RAM und Workload anpassen |
| `innodb_log_file_size`       | Redo-Log-Größe           | 128–512 MB |
| `innodb_file_per_table`      | Separater Tablespace     | `1` |
| `innodb_flush_log_at_trx_commit` | Transaktionssicherheit | `1` (ACID), `2` bei Performancebedarf |
| `innodb_flush_method`        | I/O-Handling             | `O_DIRECT` empfohlen |
| `aria_pagecache_buffer_size` | Aria-Cache               | ~128 MB (Workload-abhängig) |
| `aria_log_file_size`         | Aria-Loggröße            | ~64 MB |

### Zeichensätze

| Option                  | Bedeutung            | Empfehlung |
|-------------------------|----------------------|------------|
| `character_set_server`  | Standardzeichensatz  | `utf8mb4` |
| `collation_server`      | Sortierung           | `utf8mb4_general_ci` |

### Protokollierung

| Option                       | Bedeutung                     | Empfehlung |
|------------------------------|-------------------------------|------------|
| `log_error`                  | Fehlerlog                     | Setzen |
| `slow_query_log`             | Langsame Abfragen             | Aktivieren |
| `slow_query_log_file`        | Datei für langsame Abfragen   | z. B. `/var/log/mysql/mysql-slow.log` |
| `long_query_time`            | Schwelle „langsam“            | 1–2 s |
| `log_queries_not_using_indexes` | Ineffiziente Abfragen      | Aktivieren (bewusst) |
| `general_log`                | Alle Anfragen (Debug)         | `0` in Prod |
| `general_log_file`           | Pfad für General Query Log     | z.B. `/var/log/mysql/mysql-general.log` |

### Binärlog

| Option                  | Bedeutung              | Empfehlung |
|-------------------------|------------------------|------------|
| `log_bin`               | Binärlog aktivieren    | Pfad setzen |
| `log_bin_index`         | Indexdatei             | Pfad setzen |
| `binlog_format`         | Binärlog-Format        | `MIXED` oder `ROW` |
| `sync_binlog`           | Synchronisation        | `1` |
| `expire_logs_days`      | Binlog-Aufbewahrung    | 7–14 Tage |
| `binlog_expire_logs_seconds` | Binlog-Aufbewahrung (neu) | 7–14 Tage (604800–1209600) |

### mysqldump

| Option            | Bedeutung                   | Empfehlung |
|-------------------|-----------------------------|------------|
| `quick`           | Zeilenweiser Export         | Aktivieren |
| `quote-names`     | Sonderzeichen in Backticks  | Aktivieren |
| `max_allowed_packet` | Paketgröße bei Dumps     | `64M` oder höher |

Bei Zertifikatswechseln die Quelldateien in `ssl/` ersetzen und `docker compose restart mariadb` ausführen, damit die geschützten Laufzeitkopien neu erstellt werden. Anschließend die TLS-Verbindung erneut prüfen.

## Dateien und Betrieb

| Datei oder Mount | Zweck |
|-----------------|-------|
| `../mariadb.cnf:/etc/mysql/conf.d/my.cnf:ro` | Serverkonfiguration |
| `./initdb:/docker-entrypoint-initdb.d:ro` | Initialisierung beim ersten Start |
| `mariadb_data:/var/lib/mysql` | Persistente Daten |
| `./ssl:/run/tls-source:ro` | Zertifikatsquelle; private Laufzeitkopie unter `/etc/mysql/ssl` |
| `mariadb_logs:/var/log/mysql` | Persistente Datenbanklogs |

Die Datenbank schreibt Fehler-, Slow-Query- und Binärlogs nach `/var/log/mysql`. `docker compose logs` zeigt die Container-Ausgabe; es ersetzt nicht die Auswertung dieser Dateien.

```bash
docker compose stop
docker compose start
docker compose down
```

`down` entfernt Container und Netzwerk; das Daten-Volume bleibt erhalten. Backups müssen separat geplant, geschützt und durch Restore-Tests geprüft werden. Die Init-Skripte und Binärlogs sind kein vollständiger Backup-Prozess. Bei mehreren Setups die festen Container-Namen und die standardmäßig gleichen Host-Ports anpassen.

## Referenzen

- [MariaDB Docker-Image](https://hub.docker.com/_/mariadb)
- [Adminer-Erweiterungen](https://www.adminer.org/en/plugins/)
- [Gemeinsame TLS-Anleitung](../../../../docs/TLS-de.md)
