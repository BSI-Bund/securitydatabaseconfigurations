# <img src="https://www.vectorlogo.zone/logos/mysql/mysql-icon.svg" alt="MySQL Logo" width="26"/> MySQL – Linux (Docker Compose)

- [🚀 Hinweise zum Start mit Docker Compose Setup](#-hinweise-zum-start-mit-docker-compose-setup)
  - [⚙️ Services](#-services)
    - [🗄️ mysql](#-mysql)
    - [🧰 adminer](#-adminer)
  - [🧾 Umgebungsvariablen](#-umgebungsvariablen)
  - [📑 Parameter-Referenz (Kurz)](#-parameter-referenz-kurz)
    - [🔒 Sicherheit & Netzwerk](#-sicherheit--netzwerk)
    - [🔐 TLS/SSL](#-tlsssl)
    - [💾 Speicher & Performance](#-speicher--performance)
    - [🌐 Zeichensätze](#-zeichensätze)
    - [📊 Protokollierung](#-protokollierung)
    - [🔁 Binärlog](#-binärlog)
    - [📦 mysqldump](#-mysqldump)
  - [🧩 Hinweise zur sicheren Konfiguration](#-hinweise-zur-sicheren-konfiguration)
  - [📁 Volumes & Mounts](#-volumes--mounts)
  - [🌐 Ports](#-ports)
- [🎛️ Start & Verwaltung](#-start--verwaltung)

---

## 🚀 Hinweise zum Start mit Docker Compose Setup

Dieses Setup stellt eine **MySQL 8.4.6 Instanz** inklusive **Adminer-Weboberfläche** bereit.  
Es basiert auf offiziellen Images:
- [MySQL auf Docker Hub](https://hub.docker.com/_/mysql)
- [Adminer auf Docker Hub](https://hub.docker.com/_/adminer)

Die Konfiguration erfolgt über:

```bash
docker-compose.yml  # nutzt Werte aus .env
```

---

### ⚙️ Services

#### 🗄️ mysql

- Image `mysql:8.4.6`
- Start mit benutzerdefinierter `my.cnf`
- Initialisierung über SQL-Skripte in `./initdb/`
- Persistente Daten im Volume `mysql_data`
- Healthcheck prüft Root-Login

#### 🧰 adminer

- Weboberfläche für MySQL
- Läuft auf Port **8080**
- Verbindet sich automatisch mit `mysql`

---

### 🧾 Umgebungsvariablen

Beispielwerte liegen in `mysql-compose/.env.example`. Vor dem Start kopieren und anpassen:

```bash
cd mysql-compose
cp .env.example .env
```

---

### 📑 Parameter-Referenz (Kurz)

#### 🔒 Sicherheit & Netzwerk

| Option              | Bedeutung                        | Empfehlung |
|---------------------|----------------------------------|------------|
| `bind_address`      | Bind-IP                          | `127.0.0.1` oder VPN-IP; (`0.0.0.0` localhost über Docker Compose File) |
| `skip_networking`   | TCP/IP deaktivieren              | `0`; nur `1`, wenn ausschließlich Socket |
| `skip_name_resolve` | DNS-Lookups vermeiden            | `1`; nutze IPs in `CREATE USER` |
| `max_connections`   | Maximale Verbindungen            | 100–500 nach Bedarf |
| `local_infile`      | `LOAD DATA LOCAL INFILE`         | `0` (deaktiviert) |
| `secure_file_priv`  | Ordner für Import/Export         | Dedizierten Pfad setzen oder `NULL` (sperren) |

#### 🔐 TLS/SSL

| Option                      | Bedeutung                    | Empfehlung |
|-----------------------------|------------------------------|------------|
| `ssl-ca` / `ssl-cert` / `ssl-key` | CA/Server-Zertifikate | Pfade setzen, Rechte `600`, Owner `mysql:mysql` |
| `require_secure_transport`  | Nur TLS/Socket-Verbindungen  | `ON` nach TLS-Einrichtung |

Erstellung TLS Zertifikat siehe [README](../../../../README-de.md#-tls-konfiguration)

#### 💾 Speicher & Performance

| Option                       | Bedeutung                    | Empfehlung |
|------------------------------|------------------------------|------------|
| `innodb_buffer_pool_size`    | Hauptcache InnoDB            | 50–80 % RAM |
| `innodb_redo_log_capacity`   | Redo-Log-Gesamtgröße (neu)   | 1–4 GB je nach Schreiblast |
| `innodb_log_file_size`       | Legacy Redo-Log-Größe        | 128–512 MB (falls genutzt) |
| `innodb_file_per_table`      | Separater Tablespace         | `1` |
| `innodb_flush_log_at_trx_commit` | Haltbarkeit vs. Performance | `1` (ACID), `2` bei Bedarf |
| `innodb_flush_method`        | I/O-Strategie                | `O_DIRECT` optional |

#### 🌐 Zeichensätze

| Option                  | Bedeutung            | Empfehlung |
|-------------------------|----------------------|------------|
| `character_set_server`  | Standardzeichensatz  | `utf8mb4` |
| `collation_server`      | Sortierung           | `utf8mb4_0900_ai_ci` |

#### 📊 Protokollierung

| Option                       | Bedeutung                       | Empfehlung |
|------------------------------|---------------------------------|------------|
| `log_error`                  | Fehlerlog                       | Datei oder Container-Logs |
| `slow_query_log`             | Langsame Abfragen               | `1` |
| `slow_query_log_file`        | Pfad Slow-Query-Log             | z. B. `/var/log/mysql/mysql-slow.log` |
| `long_query_time`            | Schwelle „langsam“             | 1–2 s |
| `log_queries_not_using_indexes` | Abfragen ohne Index loggen  | Vorsichtig aktivieren |
| `general_log`                | Alle Statements (Debug)         | `0` in Prod |
| `general_log_file`           | Pfad für General Query Log     | z.B. `/var/log/mysql/mysql-general.log` |

#### 🔁 Binärlog

| Option                    | Bedeutung               | Empfehlung |
|---------------------------|-------------------------|------------|
| `log-bin` / `log_bin`     | Binärlog aktivieren     | Pfad setzen, Rotation beachten |
| `log-bin-index` / `log_bin_index` | Indexdatei      | Pfad setzen |
| `sync_binlog`             | Binlog-Sicherheit       | `1` |
| `binlog_expire_logs_seconds` | Aufbewahrung         | 7–14 Tage (604800–1209600) |
| `expire_logs_days`        | Legacy-Aufbewahrung     | 7–14 Tage |

#### 📦 mysqldump

| Option            | Bedeutung                  | Empfehlung |
|-------------------|----------------------------|------------|
| `quick`           | Zeilenweises Streaming     | Aktivieren |
| `quote-names`     | Backticks um Objekt-Namen  | Aktivieren |
| `max_allowed_packet` | Max. Paketgröße         | `64M` oder höher bei großen Dumps |
| *(CLI)*           | Konsistenter Dump          | `--single-transaction` (nicht in `my.cnf`) |

---

### 🧩 Hinweise zur sicheren Konfiguration

- Trenne `[client]` und `[mysqld]`; TLS-Optionen in `[mysqld]`.
- Zertifikate mit korrektem CN/SAN, Owner `mysql:mysql`, Rechte `0600`; `require_secure_transport=ON` nach TLS.
- `local_infile=0` und `secure_file_priv` kombinieren, um Daten-Import/Export zu kontrollieren.
- Keine Arbeiten mit `root` im Alltag; Applikations-User mit Minimalrechten.
- Backups regelmäßig testen; Binlog-Aufbewahrung und Rotation planen.
- In Containern Ports bewusst veröffentlichen, Healthchecks nutzen, Logs auf `stdout/stderr` lassen oder Pfade mounten.

---

### 📁 Volumes & Mounts

| Mount                                      | Beschreibung                                 |
|--------------------------------------------|----------------------------------------------|
| `mysql_data:/var/lib/mysql`                | Persistente Daten                            |
| `./initdb:/docker-entrypoint-initdb.d:ro`  | Initiale SQL-Skripte (nur beim ersten Start) |
| `./my.cnf:/etc/mysql/conf.d/my.cnf:ro`     | Eigene Konfiguration                         |
| `./conf.d/:/etc/mysql/conf.d/:ro` *(opt.)* | Weitere Konfigurationen                      |

---

### 🌐 Ports

| Port   | Dienst  | Beschreibung     |
|--------|---------|------------------|
| `3306` | MySQL   | Datenbankzugriff |
| `8080` | Adminer | Weboberfläche    |

---

## 🎛️ Start & Verwaltung

### ▶️ Starten

```bash
docker compose up -d
```

### ⏹️ Stoppen

```bash
docker compose down
```

### 🧾 Logs anzeigen

```bash
docker compose logs -f
```

### 🧹 Datenbankvolume entfernen (optional)

```bash
docker volume rm <projektname>_mysql_data
```

### 💻 Zugriff auf die MySQL-Konsole

```bash
docker compose exec mysql mysql -uroot -p
```

Oder über Adminer im Browser: [http://localhost:8080](http://localhost:8080)

---

© 2025 – Sichere Datenbankkonfigurationen

