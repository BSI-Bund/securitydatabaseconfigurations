# <img src="https://www.vectorlogo.zone/logos/mysql/mysql-icon.svg" alt="MySQL Logo" width="26"/> MySQL – Windows

- [💾 Hinweise zur Installation unter Windows](#-hinweise-zur-installation-unter-windows)
  - [📁 Anlegen des Datenverzeichnisses](#-anlegen-des-datenverzeichnisses)
  - [🚀 MySQL starten (Beispiel)](#-mysql-starten-beispiel)
- [📑 Parameter-Referenz (Kurz)](#-parameter-referenz-kurz)
  - [🔒 Netzwerk & Zugriff](#-netzwerk--zugriff)
  - [🔐 TLS/SSL](#-tlsssl)
  - [💾 InnoDB – Performance & Haltbarkeit](#-innodb--performance--haltbarkeit)
  - [🌐 Zeichensätze](#-zeichensätze)
  - [📊 Logging & Diagnose](#-logging--diagnose)
  - [🔁 Binärlog](#-binärlog)
  - [📦 mysqldump](#-mysqldump)
- [🧩 Hinweise zur sicheren Konfiguration](#-hinweise-zur-sicheren-konfiguration)
- [🛠️ MySQL Windows-Befehle](#-mysql-windows-befehle)
  - [1️⃣ MySQL-Dienst starten und stoppen](#1️⃣-mysql-dienst-starten-und-stoppen)
  - [2️⃣ Dienstinformationen anzeigen](#2️⃣-dienstinformationen-anzeigen)
  - [3️⃣ MySQL-Serverprozess prüfen und beenden](#3️⃣-mysql-serverprozess-pruefen-und-beenden)
  - [4️⃣ MySQL-Dienst löschen oder neu installieren](#4️⃣-mysql-dienst-loeschen-oder-neu-installieren)
  - [🔹 Hinweise / Tipps](#-hinweise--tipps)

---

## 💾 Hinweise zur Installation unter Windows

Installation über den **MySQL Installer for Windows**:  
➡️ [https://dev.mysql.com/downloads/installer/](https://dev.mysql.com/downloads/installer/)

Standardpfade nach Installation:

- Binärdateien: `C:\Program Files\MySQL\MySQL Server 8.4\bin\`
- Konfigurationsdatei: `C:\Program Files\MySQL\MySQL Server 8.4\my.ini`
- Datenverzeichnis: `C:\ProgramData\MySQL\MySQL Server 8.4\Data`
- Log-Verzeichnis (empfohlen): `C:\Program Files\MySQL\MySQL Server 8.4\logs\`

> Ordner `logs` ggf. manuell anlegen; Dienstbenutzer braucht Schreibrechte.

### 📁 Anlegen des Datenverzeichnisses

```powershell
cd C:\
md "C:\ProgramData\MySQL\MySQL Server 8.4\Data"
```

`my.ini` Beispiel:

```ini
[mysqld]
datadir = C:/ProgramData/MySQL/MySQL Server 8.4/Data
```

### 🚀 MySQL starten (Beispiel)

```powershell
cd "C:\Program Files\MySQL\MySQL Server 8.4\bin"
mysqld --defaults-file="C:\Program Files\MySQL\MySQL Server 8.4\my.ini" --console
```

MySQL-Client:

```powershell
"C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe" -u root -p
```

Weitere Infos: [MySQL 8.4 Reference Manual – Installing on Windows](https://dev.mysql.com/doc/refman/8.4/en/windows-installation.html)

---

# 📑 Parameter-Referenz (Kurz)

## 🔒 Netzwerk & Zugriff

| Option                  | Bedeutung                      | Empfehlung |
|-------------------------|--------------------------------|------------|
| `bind_address`          | Interface-Bindung              | `127.0.0.1` (oder VPN-IP) |
| `skip_networking`       | TCP/IP deaktivieren            | `0`; nur `1` für Named-Pipe-only |
| `skip_name_resolve`     | DNS-Lookups vermeiden          | `1`; nutze IPs in `CREATE USER` |
| `max_connections`       | Gleichzeitige Verbindungen     | 100–500 je nach Workload |
| `local_infile`          | Client-Datei-Upload per SQL    | `0` (hart absichern) |
| `secure_file_priv`      | Whitelist-Ordner für INFILE    | Dedizierten Ordner setzen oder `NULL` |
| `lower_case_table_names`| Case-Semantik (Windows)        | `1` (Pflicht) |

## 🔐 TLS/SSL

| Option                      | Bedeutung                  | Empfehlung |
|-----------------------------|----------------------------|------------|
| `ssl-ca` / `ssl-cert` / `ssl-key` | CA/Server-Zertifikate | Pfade setzen; Rechte restriktiv |
| `require_secure_transport`  | Nur sichere Verbindungen   | `ON` nach TLS-Einrichtung |

Erstellung TLS Zertifikat siehe [README](../../../../README-de.md#-tls-konfiguration)

## 💾 InnoDB – Performance & Haltbarkeit

| Option                          | Wirkung                         | Empfehlung |
|---------------------------------|---------------------------------|------------|
| `innodb_buffer_pool_size`       | Hauptcache                      | 50–80 % RAM |
| `innodb_redo_log_capacity`      | Redo-Log-Gesamtgröße (≥8.0)     | 1–4 GB je nach Schreiblast |
| `innodb_file_per_table`         | Separate Tablespaces            | `1` |
| `innodb_flush_log_at_trx_commit`| Haltbarkeit vs. Throughput      | `1` (ACID), `2` bei Performancebedarf |

## 🌐 Zeichensätze

| Option                 | Empfehlung          |
|------------------------|---------------------|
| `character_set_server` | `utf8mb4`           |
| `collation_server`     | `utf8mb4_0900_ai_ci`|

## 📊 Logging & Diagnose

| Option                       | Zweck                          | Empfehlung |
|------------------------------|--------------------------------|------------|
| `log_error`                  | Fehlerprotokoll                | Immer setzen |
| `slow_query_log`             | Langsame Abfragen              | Aktiv; `long_query_time=1–2s` |
| `slow_query_log_file`        | Pfad Slow-Query-Log            | z. B. `C:/Program Files/.../mysql-slow.log` |
| `long_query_time`            | Schwelle „langsam“             | 1–2 s |
| `log_queries_not_using_indexes` | Index-Miss-Erkennung        | Aktiv in Tuning-Phasen |
| `general_log`                | Alle Abfragen loggen           | In Prod: `0` |
| `general_log_file`           | Pfad für General Query Log     | z.B. `C:/Program Files/MySQL/MySQL Server 8.4/logs/mysql-general.log` |

## 🔁 Binärlog

| Option                      | Empfehlung / Hinweis          |
|-----------------------------|-------------------------------|
| `log-bin`, `log-bin-index`  | Binärlog für PITR/Replikation |
| `binlog_format`             | `ROW` empfohlen                |
| `sync_binlog`               | `1` für Haltbarkeit            |
| `binlog_expire_logs_seconds`| 7–14 Tage                     |

## 📦 mysqldump

| Option              | Wirkung                 | Empfehlung     |
|---------------------|-------------------------|----------------|
| `quick`             | Streamt zeilenweise     | Aktivieren     |
| `quote-names`       | Maskiert Identifier     | Aktivieren     |
| `max_allowed_packet`| Größere Rows/Blobs      | ≥ `64M`        |

---

## 🧩 Hinweise zur sicheren Konfiguration

- TLS konfigurieren, dann `require_secure_transport=ON` setzen.  
- `local_infile=0` und `secure_file_priv` kombinieren, um Datei-IO zu kontrollieren.  
- Starke Passwörter, Minimalrechte für App-User; kein Alltagsbetrieb als `root`.  
- Binlog-Rotation (`binlog_expire_logs_seconds`) und Backups regelmäßig prüfen.  
- Pfade (Logs/SSL/Data) an Installation anpassen; Rechte für Dienstbenutzer setzen.

---

## 🛠️ MySQL Windows-Befehle

### 1️⃣ MySQL-Dienst starten und stoppen

| Befehl            | Beschreibung                                                                |
|-------------------|----------------------------------------------------------------------------|
| `net start MySQL` | Startet den Windows-Dienst `MySQL`. Der Server läuft danach im Hintergrund. |
| `net stop MySQL`  | Stoppt den Windows-Dienst `MySQL` sauber.                                   |

> ⚠️ Administratorrechte erforderlich.

### 2️⃣ Dienstinformationen anzeigen

| Befehl                                       | Beschreibung                                                                          |
|----------------------------------------------|---------------------------------------------------------------------------------------|
| `sc qc MySQL`                                | Zeigt die Konfiguration des Dienstes.                                                 |
| `sc query MySQL`                             | Zeigt den Status (RUNNING/STOPPED).                                                   |
| `sc query type= service \| findstr /I MySQL` | Filtert Dienste nach „MySQL“.                                                         |

### 3️⃣ MySQL-Serverprozess prüfen und beenden

| Befehl                                   | Beschreibung                                              |
|------------------------------------------|-----------------------------------------------------------|
| `tasklist /FI "IMAGENAME eq mysqld.exe"` | Prüft, ob `mysqld.exe` läuft.                             |
| `taskkill /IM mysqld.exe /F`             | Beendet den MySQL-Serverprozess erzwingend (nur im Notfall). |

### 4️⃣ MySQL-Dienst löschen oder neu installieren

| Befehl                                                                                                         | Beschreibung                                                                            |
|---------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| `sc delete MySQL`                                                                                              | Löscht den registrierten MySQL-Dienst. Daten/Config bleiben erhalten.                   |
| `"C:\Program Files\MySQL\MySQL Server 8.4\bin\mysqld.exe" --install MySQL --defaults-file="C:\Pfad\zu\my.ini"` | Installiert neuen Dienst `MySQL` mit angegebener Konfigurationsdatei.                   |

> ⚠️ Administratorrechte erforderlich; Pfad zur `my.ini` muss korrekt sein.

### 🔹 Hinweise / Tipps

- Dienststeuerung via `net`/`sc`; Prozesskontrolle via `tasklist`/`taskkill`.  
- Fehlerlogs prüfen: `C:\Program Files\MySQL\MySQL Server 8.4\logs\error.log` (falls konfiguriert).  
- TLS aktivieren, `secure_file_priv` setzen, Root-Zugriff schützen.

---

© 2025 – Sichere Datenbankkonfigurationen

