# MariaDB – Windows

[English](README.md) · [Datenbankübersicht](../../README-de.md) · [BSI-Alignment](../../../README-de.md#bsi-alignment)

- [Installation und aktive Konfiguration](#installation-und-aktive-konfiguration)
- [Anmeldung und Benutzer](#anmeldung-und-benutzer)
- [TLS einrichten](#tls-einrichten)
- [Konfiguration prüfen](#konfiguration-prüfen)
- [Parameterreferenz](#parameterreferenz)
  - [Sicherheit & Netzwerk](#sicherheit--netzwerk)
  - [TLS/SSL](#tlsssl)
  - [Speicher & Performance](#speicher--performance)
  - [Zeichensätze](#zeichensätze)
  - [Protokollierung](#protokollierung)
  - [Binärlog](#binärlog)
  - [mysqldump](#mysqldump)
- [Betrieb](#betrieb)

## Installation und aktive Konfiguration

[MariaDB-MSI und Installationsanleitung](https://mariadb.com/docs/server/server-management/install-and-upgrade-mariadb/installing-mariadb/installing-mariadb-msi-packages-on-windows) verwenden. Die folgenden Pfade sind die Beispiele aus der mitgelieferten [`my.ini`](my.ini); tatsächliche Installations- und Dienstpfade prüfen.

| Zweck | Beispielpfad |
|-------|--------------|
| Binärdateien | `C:\Program Files\MariaDB 11.8\bin` |
| Aktive Konfiguration, im Dienst zu prüfen | `C:\Program Files\MariaDB 11.8\data\my.ini` |
| Initialisiertes Datenverzeichnis | `C:\Program Files\MariaDB 11.8\data` |
| Logverzeichnis der Vorlage | `C:\Program Files\MariaDB 11.8\data\mysql` |

Das Datenverzeichnis muss bereits durch die Installation initialisiert sein. Das Anlegen eines leeren Ordners ersetzt keine DBMS-Initialisierung. Vorhandene Datenverzeichnisse nicht durch eine neue Initialisierung überschreiben.

1. Den tatsächlichen Windows-Dienstnamen feststellen; unten wird `MariaDB` als Beispiel verwendet.
2. Mit `sc.exe qc MariaDB` prüfen, welche Konfiguration der Dienst lädt. Die mitgelieferte `my.ini` allein durch ihre Ablage im Repository wird nicht aktiv.
3. Pfade und Speicherwerte in der aktiven Konfiguration anpassen. Log- und gegebenenfalls Import-/Export-Verzeichnisse anlegen; dem Dienstkonto die benötigten Rechte geben.
4. Dienst nach der Anpassung neu starten und das konfigurierte Fehlerlog prüfen.

```powershell
sc.exe qc MariaDB
net stop MariaDB
net start MariaDB
sc.exe query MariaDB
```

Dienständerungen benötigen eine PowerShell mit Administratorrechten. Ein zweiter manuell gestarteter Server darf nicht dasselbe Datenverzeichnis wie der laufende Dienst verwenden.

## Anmeldung und Benutzer

Die Client-Befehle können in einer normalen PowerShell ausgeführt werden; der Aufrufoperator `&` führt den in Anführungszeichen angegebenen Programmpfad aus.

```powershell
& "C:\Program Files\MariaDB 11.8\bin\mariadb.exe" --host=127.0.0.1 --user=root --password
```

Das Passwort wird interaktiv abgefragt. Administrationskonten nur für Einrichtung und Wartung verwenden; Anwendungen erhalten eigene, eingeschränkte Konten.

Für die Beispielkonten zunächst Passwörter und die erlaubten Hosts in [`init_scripts/init_users.sql`](init_scripts/init_users.sql) anpassen. Dann aus einer administrativen Client-Sitzung die Datei ausführen, beispielsweise mit `SOURCE C:/Pfad/zum/Repository/configs/MariaDB/Version_11/Windows/init_scripts/init_users.sql;`. Das Skript legt `appdb`, `app_admin` und `app_reader` an; es initialisiert kein leeres Datenverzeichnis.

Alternativ `init_scripts\init_mariadb.bat` aufrufen. Das Skript führt ausschließlich die daneben liegende `init_users.sql` über den Client gegen den laufenden Dienst aus; es startet oder beendet keine Server. Das Administrationspasswort wird interaktiv abgefragt. Bei abweichender Installation `MARIADB_BIN`, `MARIADB_HOST`, `MARIADB_PORT` und `MARIADB_ADMIN` setzen. Fehlende Dateien und SQL-/Verbindungsfehler führen zu einem Exitcode ungleich null.

## TLS einrichten

Die Server-TLS-Zeilen in `my.ini` sind auskommentiert. Die Vorlage erzwingt daher noch keine von dir konfigurierte TLS-Verbindung. Nach der [gemeinsamen TLS-Anleitung](../../../../docs/TLS-de.md) CA-, Serverzertifikat und Serverschlüssel erzeugen, unter den in `ssl-ca`, `ssl-cert` und `ssl-key` genannten Namen ablegen und die Serverzeilen im Abschnitt `[mysqld]` aktivieren. Client-Zertifikatsoptionen gehören in einen passenden Client-Abschnitt.

Dem Dienstkonto Leserechte auf den privaten Serverschlüssel geben, danach die Transportanforderung (`require_secure_transport=ON` beziehungsweise passende Kontoregeln) setzen und den Dienst neu starten. Auf dem Client CA- und Namensprüfung aktivieren. Die genaue Prüfung hängt vom MariaDB- beziehungsweise MySQL-Client ab; `SHOW SESSION STATUS LIKE 'Ssl_cipher';` zeigt die Verschlüsselung der aktuellen Verbindung.

## Konfiguration prüfen

Die nachfolgende Referenz enthält Empfehlungen. Die tatsächlich wirksamen Werte mit `SHOW VARIABLES` prüfen, insbesondere Dateipfade, Netzwerkbindung, TLS und Speicherwerte. Ein erfolgreicher Dienststart allein bestätigt diese Einstellungen nicht.

## Parameterreferenz

### Sicherheit & Netzwerk

| Option              | Bedeutung                    | Empfehlung |
|---------------------|------------------------------|------------|
| `bind_address`      | Bind-IP                      | `127.0.0.1` (oder VPN-IP) |
| `skip_networking`   | TCP/IP deaktivieren          | `0`; nur `1`, wenn ausschließlich lokal |
| `skip_name_resolve` | DNS-Lookups vermeiden        | `1` |
| `max_connections`   | Maximale Clients             | 100–500 je nach Workload |
| `local_infile`      | `LOAD DATA LOCAL INFILE`     | `0` (deaktiviert) |
| `secure_file_priv` | Import/Export-Verzeichnis | Dediziertes Verzeichnis festlegen; in der Vorlage auskommentiert |
| `symbolic-links`    | Symlinks in Tabellen         | `0` (deaktiviert) |

### TLS/SSL

| Option    | Bedeutung          | Empfehlung |
|-----------|--------------------|------------|
| `ssl-ca`  | CA-Zertifikat      | `C:/mariadb/ssl/ca-cert.pem` |
| `ssl-cert`| Server-Zertifikat  | `C:/mariadb/ssl/server-cert.pem` |
| `ssl-key` | Server-Schlüssel   | `C:/mariadb/ssl/server-key.pem` |

> TLS-Zwang per SQL: `ALTER USER 'app_admin'@'%' REQUIRE SSL;`

### Speicher & Performance

| Option                       | Bedeutung                | Empfehlung |
|------------------------------|--------------------------|------------|
| `innodb_buffer_pool_size`    | RAM für InnoDB           | An verfügbaren RAM und Workload anpassen |
| `innodb_log_file_size`       | Redo-Log-Größe           | 128–512 MB |
| `innodb_file_per_table`      | Separater Tablespace     | `1` |
| `innodb_flush_log_at_trx_commit` | Transaktionssicherheit | `1` (ACID), `2` bei Performancebedarf |
| `innodb_flush_method`        | I/O-Handling             | Unter Windows nicht pauschal übernehmen |
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
| `slow_query_log_file`        | Datei für langsame Abfragen   | z. B. `C:/Program Files/.../mysql-slow.log` |
| `long_query_time`            | Schwelle „langsam“            | 1–2 s |
| `log_queries_not_using_indexes` | Ineffiziente Abfragen      | Aktivieren (bewusst) |
| `general_log`                | Alle Anfragen (Debug)         | `0` in Prod |
| `general_log_file`           | Pfad für General Query Log    | z.B. `C:/Program Files/MariaDB 11.8/data/mysql/mysql-general.log` |

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

## Betrieb

Backups, Aufbewahrung und Restore-Tests separat einrichten. Binärlogs ermöglichen zusammen mit einer geeigneten Sicherung ein Recovery-Konzept; ihre Aktivierung allein ist kein Backup. Logs nach den Pfaden in der aktiven `my.ini` auswerten. Für Prozessinformationen `tasklist /FI "IMAGENAME eq mysqld.exe"` verwenden; regulär über den Dienst stoppen.
