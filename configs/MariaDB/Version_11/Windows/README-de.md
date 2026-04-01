# <img src="https://cdn.worldvectorlogo.com/logos/mariadb.svg" alt="MariaDB Logo" width="26"/> MariaDB – Windows

- [💾 Hinweise zur Installation unter Windows](#-hinweise-zur-installation-unter-windows)
  - [📁 Anlegen des Datenverzeichnisses](#-anlegen-des-datenverzeichnisses)
  - [🚀 MariaDB starten (Beispiel)](#-mariadb-starten-beispiel)
- [📑 Parameter-Referenz (Kurz)](#-parameter-referenz-kurz)
  - [🔒 Sicherheit & Netzwerk](#-sicherheit--netzwerk)
  - [🔐 TLS/SSL](#-tlsssl)
  - [💾 Speicher & Performance](#-speicher--performance)
  - [🌐 Zeichensätze](#-zeichensätze)
  - [📊 Protokollierung](#-protokollierung)
  - [🔁 Binärlog](#-binärlog)
  - [📦 mysqldump](#-mysqldump)
- [🧩 Hinweise zur sicheren Konfiguration](#-hinweise-zur-sicheren-konfiguration)
- [🧩 MariaDB Init-Skript (`init_mariadb.bat`)](#-mariadb-init-skript-init_mariadbbat)
  - [⚙️ Ablauf des Skripts](#️-ablauf-des-skripts)
  - [🎯 Zweck](#-zweck)
  - [⚠️ Hinweise](#%EF%B8%8F-hinweise)
- [🛠️ MariaDB Windows-Befehle](#-mariadb-windows-befehle)
  - [1️⃣ MariaDB-Dienst starten und stoppen](#1️⃣-mariadb-dienst-starten-und-stoppen)
  - [2️⃣ Dienstinformationen anzeigen](#2️⃣-dienstinformationen-anzeigen)
  - [3️⃣ MariaDB-Serverprozess prüfen und beenden](#3️⃣-mariadb-serverprozess-pruefen-und-beenden)
  - [4️⃣ MariaDB-Dienst löschen oder neu installieren](#4️⃣-mariadb-dienst-loeschen-oder-neu-installieren)
  - [🔹 Hinweise / Tipps](#-hinweise--tipps)

---

## 💾 Hinweise zur Installation unter Windows

Für die Installation wird der **MariaDB Community Installer** von der offiziellen Downloadseite heruntergeladen:  
➡️ [https://mariadb.org/download/](https://mariadb.org/download/)

Nach der Installation befindet sich der Standardpfad der MariaDB-Binärdateien üblicherweise unter:  
`C:\Program Files\MariaDB 11.8\bin\`

Die Konfigurationsdatei (`my.ini`) liegt in der Regel unter:  
`C:\Program Files\MariaDB 11.8\data\my.ini`

### 📁 Anlegen des Datenverzeichnisses

Falls das Datenverzeichnis manuell angelegt werden soll:

```bash
cd C:\
md "\data\mariadb"
```

Das Datenverzeichnis kann in der Konfigurationsdatei (`my.ini`) über den Parameter `datadir` angegeben werden, z. B.:

```ini
[mysqld]
datadir=C:\data\mariadb
```

### 🚀 MariaDB starten (Beispiel)

Zum Starten von MariaDB mit einem benutzerdefinierten Datenverzeichnis:

```bash
"C:\Program Files\MariaDB 11.8\bin\mysqld.exe" --defaults-file="C:\Program Files\MariaDB 11.8\data\my.ini"
```

Oder interaktiv über den MariaDB-Client:

```bash
"C:\Program Files\MariaDB 11.8\bin\mysql.exe" -u root -p
```

Weitere Informationen:
➡️ [Offizielle MariaDB-Dokumentation – Installation unter Windows](https://mariadb.com/kb/en/installing-mariadb-msi-packages-on-windows/)

---

# 📑 Parameter-Referenz (Kurz)

## 🔒 Sicherheit & Netzwerk

| Option              | Bedeutung                    | Empfehlung |
|---------------------|------------------------------|------------|
| `bind_address`      | Bind-IP                      | `127.0.0.1` (oder VPN-IP) |
| `skip_networking`   | TCP/IP deaktivieren          | `0`; nur `1`, wenn ausschließlich lokal |
| `skip_name_resolve` | DNS-Lookups vermeiden        | `1` |
| `max_connections`   | Maximale Clients             | 100–500 je nach Workload |
| `local_infile`      | `LOAD DATA LOCAL INFILE`     | `0` (deaktiviert) |
| `secure_file_priv`  | Import/Export-Verzeichnis    | Dedizierten Pfad setzen oder `NULL` |
| `symbolic-links`    | Symlinks in Tabellen         | `0` (deaktiviert) |

## 🔐 TLS/SSL

| Option    | Bedeutung          | Empfehlung |
|-----------|--------------------|------------|
| `ssl-ca`  | CA-Zertifikat      | `C:/mariadb/ssl/ca-cert.pem` |
| `ssl-cert`| Server-Zertifikat  | `C:/mariadb/ssl/server-cert.pem` |
| `ssl-key` | Server-Schlüssel   | `C:/mariadb/ssl/server-key.pem` |

Erstellung TLS Zertifikat siehe [README](../../../../README-de.md#-tls-konfiguration)

> TLS-Zwang per SQL: `ALTER USER 'app'@'%' REQUIRE SSL;`

## 💾 Speicher & Performance

| Option                       | Bedeutung                | Empfehlung |
|------------------------------|--------------------------|------------|
| `innodb_buffer_pool_size`    | RAM für InnoDB           | 50–80 % RAM |
| `innodb_log_file_size`       | Redo-Log-Größe           | 128–512 MB |
| `innodb_file_per_table`      | Separater Tablespace     | `1` |
| `innodb_flush_log_at_trx_commit` | Transaktionssicherheit | `1` (ACID), `2` bei Performancebedarf |
| `innodb_flush_method`        | I/O-Handling             | `O_DIRECT` empfohlen |
| `aria_pagecache_buffer_size` | Aria-Cache               | ~128 MB (Workload-abhängig) |
| `aria_log_file_size`         | Aria-Loggröße            | ~64 MB |

## 🌐 Zeichensätze

| Option                  | Bedeutung            | Empfehlung |
|-------------------------|----------------------|------------|
| `character_set_server`  | Standardzeichensatz  | `utf8mb4` |
| `collation_server`      | Sortierung           | `utf8mb4_general_ci` |

## 📊 Protokollierung

| Option                       | Bedeutung                     | Empfehlung |
|------------------------------|-------------------------------|------------|
| `log_error`                  | Fehlerlog                     | Setzen |
| `slow_query_log`             | Langsame Abfragen             | Aktivieren |
| `slow_query_log_file`        | Datei für langsame Abfragen   | z. B. `C:/Program Files/.../mysql-slow.log` |
| `long_query_time`            | Schwelle „langsam“            | 1–2 s |
| `log_queries_not_using_indexes` | Ineffiziente Abfragen      | Aktivieren (bewusst) |
| `general_log`                | Alle Anfragen (Debug)         | `0` in Prod |
| `general_log_file`           | Pfad für General Query Log    | z.B. `C:/Program Files/MariaDB 11.8/data/mysql/mysql-general.log` |

## 🔁 Binärlog

| Option                  | Bedeutung              | Empfehlung |
|-------------------------|------------------------|------------|
| `log_bin`               | Binärlog aktivieren    | Pfad setzen |
| `log_bin_index`         | Indexdatei             | Pfad setzen |
| `binlog_format`         | Binärlog-Format        | `MIXED` oder `ROW` |
| `sync_binlog`           | Synchronisation        | `1` |
| `expire_logs_days`      | Binlog-Aufbewahrung    | 7–14 Tage |
| `binlog_expire_logs_seconds` | Binlog-Aufbewahrung (neu) | 7–14 Tage (604800–1209600) |

## 📦 mysqldump

| Option            | Bedeutung                   | Empfehlung |
|-------------------|-----------------------------|------------|
| `quick`           | Zeilenweiser Export         | Aktivieren |
| `quote-names`     | Sonderzeichen in Backticks  | Aktivieren |
| `max_allowed_packet` | Paketgröße bei Dumps     | `64M` oder höher |

---

## 🧩 Hinweise zur sicheren Konfiguration

- `[client]` und `[mysqld]` trennen; TLS-Optionen in `[mysqld]`.
- Zertifikate mit Owner des MariaDB-Diensts, Rechte restriktiv (Windows ACLs); TLS-Zwang via `REQUIRE SSL`.
- `local_infile=0`, `secure_file_priv` setzen und `symbolic-links=0` für mehr Schutz.
- Applikations-User mit Minimalrechten; nicht mit `root` arbeiten.
- Backups & Wiederherstellung testen; Binlog-Aufbewahrung planen.
- Pfade und Rechte je Windows-Installation prüfen.

---

## 🧩 MariaDB Init-Skript (`init_mariadb.bat`)

Dieses Skript automatisiert die **Erstinitialisierung einer MariaDB-Instanz unter Windows**.  
Es richtet Benutzer, Berechtigungen und Standarddatenbanken ein, bevor der Dienst regulär läuft.

### ⚙️ Ablauf des Skripts

1. Dienst stoppen (`MariaDB`), um Port-Konflikte zu vermeiden.  
2. Dienst starten, kurze Wartezeit.  
3. Temporären MariaDB-Server mit angegebener `my.ini` starten.  
4. `init_users.sql` ausführen (Benutzer/Passwörter/DB/Rechte).  
5. Temporären Server sauber per `mysqladmin shutdown` beenden.  
6. Dienst erneut starten – Initialisierung abgeschlossen.

### 🎯 Zweck

- Schnelle, reproduzierbare und sichere Erstkonfiguration  
- Anlage von Benutzern, Datenbanken und Berechtigungen vor dem Produktivbetrieb

### ⚠️ Hinweise

- Skript mit Administratorrechten ausführen (Dienststart/-stopp).  
- `ROOT_PASS` im Skript setzen.  
- Pfad zur Config (`CONFIG_FILE`) und zum Init-SQL (`INIT_SQL`) prüfen.

---

## 🛠️ MariaDB Windows-Befehle

Diese Übersicht zeigt Befehle zur Verwaltung von MariaDB auf Windows.

### 1️⃣ MariaDB-Dienst starten und stoppen

| Befehl              | Beschreibung                                                                  |
| ------------------- | ----------------------------------------------------------------------------- |
| `net start MariaDB` | Startet den Windows-Dienst `MariaDB`. Der Dienst läuft danach im Hintergrund. |
| `net stop MariaDB`  | Stoppt den Windows-Dienst `MariaDB` sauber.                                   |

> ⚠️ Administratorrechte erforderlich.

### 2️⃣ Dienstinformationen anzeigen

| Befehl                  | Beschreibung                                                                          |
| ----------------------- | ------------------------------------------------------------------------------------- |
| `sc qc MariaDB`         | Zeigt die **Konfiguration des Dienstes** an (Installationspfad, Starttyp, Parameter). |
| `sc query MariaDB`      | Zeigt den **aktuellen Status** des Dienstes an (RUNNING, STOPPED etc.).               |
| `sc query type= service \| findstr /I MariaDB` | Filtert alle Dienste nach „MariaDB“, zeigt nur relevante Zeilen an. |

### 3️⃣ MariaDB-Serverprozess prüfen und beenden

| Befehl                                   | Beschreibung                                                       |
| ---------------------------------------- | ------------------------------------------------------------------ |
| `tasklist /FI "IMAGENAME eq mysqld.exe"` | Prüft, ob der MariaDB-Serverprozess `mysqld.exe` läuft.            |
| `taskkill /IM mysqld.exe /F`             | Beendet den laufenden MariaDB-Serverprozess **sofort erzwingend**. |

> ⚠️ Nur nutzen, wenn der Dienst nicht verwendet wird.

### 4️⃣ MariaDB-Dienst löschen oder neu installieren

| Befehl                                                                                                 | Beschreibung                                                                                |
| ------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------- |
| `sc delete MariaDB`                                                                                    | Löscht den registrierten MariaDB-Dienst aus Windows. Die Datenbankdateien bleiben erhalten. |
| `"C:\Program Files\MariaDB 11.8\bin\mysqld.exe" --install MariaDB --defaults-file="C:\Pfad\zu\my.ini"` | Installiert einen neuen Windows-Dienst `MariaDB` mit der angegebenen Config-Datei.          |

> ⚠️ Administratorrechte erforderlich. Der Pfad zur `my.ini` muss korrekt sein.

### 🔹 Hinweise / Tipps

- Dienst vs. Prozess: Dienst → `net start/stop`, `sc query/qc`; Prozess → `mysqld.exe`, Kontrolle via `tasklist`/`taskkill`.  
- Administratorrechte für Dienstaktionen erforderlich.  
- Logs prüfen: z. B. `C:\Program Files\MariaDB 11.8\data\` bzw. konfiguriertes Logverzeichnis.  
- TLS aktivieren, sobald Zertifikate vorliegen; `REQUIRE SSL` nutzen.  
- `secure_file_priv` setzen, um Dateiimporte/-exporte zu beschränken.

© 2025 – Sichere Datenbankkonfigurationen

