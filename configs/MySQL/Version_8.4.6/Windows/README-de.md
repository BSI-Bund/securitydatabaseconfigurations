# MySQL – Windows

[English](README.md) · [Datenbankübersicht](../../README-de.md) · [BSI-Alignment](../../../README-de.md#bsi-alignment)

- [Installation und aktive Konfiguration](#installation-und-aktive-konfiguration)
- [Anmeldung und Benutzer](#anmeldung-und-benutzer)
- [TLS einrichten](#tls-einrichten)
- [Konfiguration prüfen](#konfiguration-prüfen)
- [Parameterreferenz](#parameterreferenz)
  - [Netzwerk & Zugriff](#netzwerk--zugriff)
  - [TLS/SSL](#tlsssl)
  - [InnoDB – Performance & Haltbarkeit](#innodb--performance--haltbarkeit)
  - [Zeichensätze](#zeichensätze)
  - [Logging & Diagnose](#logging--diagnose)
  - [Binärlog](#binärlog)
  - [mysqldump](#mysqldump)
- [Betrieb](#betrieb)

## Installation und aktive Konfiguration

[MySQL-8.4-MSI mit MySQL Configurator](https://dev.mysql.com/doc/refman/8.4/en/windows-installation.html) verwenden. Die folgenden Pfade sind die Beispiele aus der mitgelieferten [`my.ini`](my.ini); tatsächliche Installations- und Dienstpfade prüfen.

| Zweck | Beispielpfad |
|-------|--------------|
| Binärdateien | `C:\Program Files\MySQL\MySQL Server 8.4\bin` |
| Aktive Konfiguration, im Dienst zu prüfen | `C:\Program Files\MySQL\MySQL Server 8.4\my.ini` |
| Initialisiertes Datenverzeichnis | `C:\ProgramData\MySQL\MySQL Server 8.4\Data` |
| Logverzeichnis der Vorlage | `C:\Program Files\MySQL\MySQL Server 8.4\logs` |

Das Datenverzeichnis muss bereits durch die Installation initialisiert sein. Das Anlegen eines leeren Ordners ersetzt keine DBMS-Initialisierung. Vorhandene Datenverzeichnisse nicht durch eine neue Initialisierung überschreiben.

1. Den tatsächlichen Windows-Dienstnamen feststellen; unten wird `MySQL` als Beispiel verwendet.
2. Mit `sc.exe qc MySQL` prüfen, welche Konfiguration der Dienst lädt. Die mitgelieferte `my.ini` allein durch ihre Ablage im Repository wird nicht aktiv.
3. Pfade und Speicherwerte in der aktiven Konfiguration anpassen. Log- und gegebenenfalls Import-/Export-Verzeichnisse anlegen; dem Dienstkonto die benötigten Rechte geben.
4. Dienst nach der Anpassung neu starten und das konfigurierte Fehlerlog prüfen.

```powershell
sc.exe qc MySQL
net stop MySQL
net start MySQL
sc.exe query MySQL
```

Dienständerungen benötigen eine PowerShell mit Administratorrechten. Ein zweiter manuell gestarteter Server darf nicht dasselbe Datenverzeichnis wie der laufende Dienst verwenden.

## Anmeldung und Benutzer

Die Client-Befehle können in einer normalen PowerShell ausgeführt werden; der Aufrufoperator `&` führt den in Anführungszeichen angegebenen Programmpfad aus.

```powershell
& "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe" --host=127.0.0.1 --user=root --password
```

Das Passwort wird interaktiv abgefragt. Administrationskonten nur für Einrichtung und Wartung verwenden; Anwendungen erhalten eigene, eingeschränkte Konten.

Unter Windows enthält dieser Ordner kein Init-Skript. Datenbank, Anwendungsnutzer und Rechte sind in einer administrativen SQL-Sitzung passend zur Anwendung einzurichten. Die Linux-Compose-Variablen erzeugen hier keine Konten.

## TLS einrichten

Die Server-TLS-Zeilen in `my.ini` sind auskommentiert. Die Vorlage erzwingt daher noch keine von dir konfigurierte TLS-Verbindung. Nach der [gemeinsamen TLS-Anleitung](../../../../docs/TLS-de.md) CA-, Serverzertifikat und Serverschlüssel erzeugen, unter den in `ssl-ca`, `ssl-cert` und `ssl-key` genannten Namen ablegen und die Serverzeilen im Abschnitt `[mysqld]` aktivieren. Client-Zertifikatsoptionen gehören in einen passenden Client-Abschnitt.

Dem Dienstkonto Leserechte auf den privaten Serverschlüssel geben, danach die Transportanforderung (`require_secure_transport=ON` beziehungsweise passende Kontoregeln) setzen und den Dienst neu starten. Auf dem Client CA- und Namensprüfung aktivieren. Die genaue Prüfung hängt vom MariaDB- beziehungsweise MySQL-Client ab; `SHOW SESSION STATUS LIKE 'Ssl_cipher';` zeigt die Verschlüsselung der aktuellen Verbindung.

## Konfiguration prüfen

Die nachfolgende Referenz enthält Empfehlungen. Die tatsächlich wirksamen Werte mit `SHOW VARIABLES` prüfen, insbesondere Dateipfade, Netzwerkbindung, TLS und Speicherwerte. Ein erfolgreicher Dienststart allein bestätigt diese Einstellungen nicht.

## Parameterreferenz

### Netzwerk & Zugriff

| Option                  | Bedeutung                      | Empfehlung |
|-------------------------|--------------------------------|------------|
| `bind_address`          | Interface-Bindung              | `127.0.0.1` (oder VPN-IP) |
| `skip_networking`       | TCP/IP deaktivieren            | `0`; nur `1` für Named-Pipe-only |
| `skip_name_resolve`     | DNS-Lookups vermeiden          | `1`; nutze IPs in `CREATE USER` |
| `max_connections`       | Gleichzeitige Verbindungen     | 100–500 je nach Workload |
| `local_infile`          | Client-Datei-Upload per SQL    | `0` (hart absichern) |
| `secure_file_priv`      | Whitelist-Ordner für INFILE    | Dedizierten Ordner setzen oder `NULL` |
| `lower_case_table_names`| Case-Semantik (Windows)        | `1` (Pflicht) |

### TLS/SSL

| Option                      | Bedeutung                  | Empfehlung |
|-----------------------------|----------------------------|------------|
| `ssl-ca` / `ssl-cert` / `ssl-key` | CA/Server-Zertifikate | Pfade setzen; Rechte restriktiv |
| `require_secure_transport`  | Nur sichere Verbindungen   | `ON` nach TLS-Einrichtung |

### InnoDB – Performance & Haltbarkeit

| Option                          | Wirkung                         | Empfehlung |
|---------------------------------|---------------------------------|------------|
| `innodb_buffer_pool_size`       | Hauptcache                      | An verfügbaren RAM und Workload anpassen |
| `innodb_redo_log_capacity`      | Redo-Log-Gesamtgröße (≥8.0)     | 1–4 GB je nach Schreiblast |
| `innodb_file_per_table`         | Separate Tablespaces            | `1` |
| `innodb_flush_log_at_trx_commit`| Haltbarkeit vs. Throughput      | `1` (ACID), `2` bei Performancebedarf |

### Zeichensätze

| Option                 | Empfehlung          |
|------------------------|---------------------|
| `character_set_server` | `utf8mb4`           |
| `collation_server`     | `utf8mb4_0900_ai_ci`|

### Logging & Diagnose

| Option                       | Zweck                          | Empfehlung |
|------------------------------|--------------------------------|------------|
| `log_error`                  | Fehlerprotokoll                | Immer setzen |
| `slow_query_log`             | Langsame Abfragen              | Aktiv; `long_query_time=1–2s` |
| `slow_query_log_file`        | Pfad Slow-Query-Log            | z. B. `C:/Program Files/.../mysql-slow.log` |
| `long_query_time`            | Schwelle „langsam“             | 1–2 s |
| `log_queries_not_using_indexes` | Index-Miss-Erkennung        | Aktiv in Tuning-Phasen |
| `general_log`                | Alle Abfragen loggen           | In Prod: `0` |
| `general_log_file`           | Pfad für General Query Log     | z.B. `C:/Program Files/MySQL/MySQL Server 8.4/logs/mysql-general.log` |

### Binärlog

| Option                      | Empfehlung / Hinweis          |
|-----------------------------|-------------------------------|
| `log-bin`, `log-bin-index`  | Binärlog für PITR/Replikation |
| `binlog_format`             | `ROW` empfohlen                |
| `sync_binlog`               | `1` für Haltbarkeit            |
| `binlog_expire_logs_seconds`| 7–14 Tage                     |

### mysqldump

| Option              | Wirkung                 | Empfehlung     |
|---------------------|-------------------------|----------------|
| `quick`             | Streamt zeilenweise     | Aktivieren     |
| `quote-names`       | Maskiert Identifier     | Aktivieren     |
| `max_allowed_packet`| Größere Rows/Blobs      | ≥ `64M`        |

## Betrieb

Backups, Aufbewahrung und Restore-Tests separat einrichten. Binärlogs ermöglichen zusammen mit einer geeigneten Sicherung ein Recovery-Konzept; ihre Aktivierung allein ist kein Backup. Logs nach den Pfaden in der aktiven `my.ini` auswerten. Für Prozessinformationen `tasklist /FI "IMAGENAME eq mysqld.exe"` verwenden; regulär über den Dienst stoppen.
