# <img src="https://cdn.worldvectorlogo.com/logos/mariadb.svg" alt="MariaDB Logo" width="26"/> MariaDB – Linux (Docker Compose)

- [🚀 Hinweise zum Start mit Docker Compose Setup](#-hinweise-zum-start-mit-docker-compose-setup)
  - [⚙️ Services](#-services)
    - [🗄️ mariadb](#-mariadb)
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

Dieses Setup stellt eine **MariaDB 11.8 Instanz** inklusive **Adminer-Weboberfläche** bereit.  
Es basiert auf offiziellen Images:
- [MariaDB auf Docker Hub](https://hub.docker.com/_/mariadb)
- [Adminer auf Docker Hub](https://hub.docker.com/_/adminer)

Die Konfiguration erfolgt über:

```bash
docker-compose.yml  # nutzt Werte aus .env
```

---

### ⚙️ Services

#### 🗄️ mariadb

- Image `mariadb:11.8`
- Start mit benutzerdefinierter `my.cnf`
- Initialisierung über SQL-Skripte in `./initdb/`
- Persistente Daten im Volume `mariadb_data`
- Healthcheck prüft Root-Login

#### 🧰 adminer

- Weboberfläche für MariaDB
- Läuft auf Port **8080**
- Verbindet sich automatisch mit `mariadb`

---

### 🧾 Umgebungsvariablen

Beispielwerte liegen in `mariadb-compose/.env.example`. Vor dem Start kopieren und anpassen:

```bash
cd mariadb-compose
cp .env.example .env
```

---

### 📑 Parameter-Referenz (Kurz)

#### 🔒 Sicherheit & Netzwerk

| Option              | Bedeutung                        | Empfehlung |
|---------------------|----------------------------------|------------|
| `bind_address`      | Bind-IP                          | `127.0.0.1` oder VPN-IP (`0.0.0.0` localhost über Docker Compose File)|
| `skip_networking`   | TCP/IP deaktivieren              | `0`; nur `1`, wenn ausschließlich Socket |
| `skip_name_resolve` | DNS-Lookups vermeiden            | `1` |
| `max_connections`   | Maximale Clients                 | 100–500 je nach Workload |
| `local_infile`      | `LOAD DATA LOCAL INFILE`         | `0` (deaktiviert) |
| `secure_file_priv`  | Ordner für Import/Export         | Dedizierten Pfad setzen oder `NULL` |
| `symbolic-links`    | Symlink-Nutzung                  | `0` (deaktiviert) |

#### 🔐 TLS/SSL

| Option    | Bedeutung            | Empfehlung |
|-----------|----------------------|------------|
| `ssl-ca`  | CA-Zertifikat        | z. B. `/etc/mysql/ssl/ca-cert.pem` |
| `ssl-cert`| Server-Zertifikat    | z. B. `/etc/mysql/ssl/server-cert.pem` |
| `ssl-key` | Server-Schlüssel     | z. B. `/etc/mysql/ssl/server-key.pem` |

Erstellung TLS Zertifikat siehe [README](../../../../README-de.md#-tls-konfiguration)


> TLS-Zwang per SQL: `ALTER USER 'app'@'%' REQUIRE SSL;`

#### 💾 Speicher & Performance

| Option                       | Bedeutung                | Empfehlung |
|------------------------------|--------------------------|------------|
| `innodb_buffer_pool_size`    | RAM für InnoDB           | 50–80 % RAM |
| `innodb_log_file_size`       | Redo-Log-Größe           | 128–512 MB |
| `innodb_file_per_table`      | Separater Tablespace     | `1` |
| `innodb_flush_log_at_trx_commit` | Transaktionssicherheit | `1` (ACID), `2` bei Performancebedarf |
| `innodb_flush_method`        | I/O-Handling             | `O_DIRECT` empfohlen |
| `aria_pagecache_buffer_size` | Aria-Cache               | ~128 MB (Workload-abhängig) |
| `aria_log_file_size`         | Aria-Loggröße            | ~64 MB |

#### 🌐 Zeichensätze

| Option                  | Bedeutung            | Empfehlung |
|-------------------------|----------------------|------------|
| `character_set_server`  | Standardzeichensatz  | `utf8mb4` |
| `collation_server`      | Sortierung           | `utf8mb4_general_ci` |

#### 📊 Protokollierung

| Option                       | Bedeutung                     | Empfehlung |
|------------------------------|-------------------------------|------------|
| `log_error`                  | Fehlerlog                     | Setzen |
| `slow_query_log`             | Langsame Abfragen             | Aktivieren |
| `slow_query_log_file`        | Datei für langsame Abfragen   | z. B. `/var/log/mysql/mysql-slow.log` |
| `long_query_time`            | Schwelle „langsam“            | 1–2 s |
| `log_queries_not_using_indexes` | Ineffiziente Abfragen      | Aktivieren (bewusst) |
| `general_log`                | Alle Anfragen (Debug)         | `0` in Prod |
| `general_log_file`           | Pfad für General Query Log     | z.B. `/var/log/mysql/mysql-general.log` |

#### 🔁 Binärlog

| Option                  | Bedeutung              | Empfehlung |
|-------------------------|------------------------|------------|
| `log_bin`               | Binärlog aktivieren    | Pfad setzen |
| `log_bin_index`         | Indexdatei             | Pfad setzen |
| `binlog_format`         | Binärlog-Format        | `MIXED` oder `ROW` |
| `sync_binlog`           | Synchronisation        | `1` |
| `expire_logs_days`      | Binlog-Aufbewahrung    | 7–14 Tage |
| `binlog_expire_logs_seconds` | Binlog-Aufbewahrung (neu) | 7–14 Tage (604800–1209600) |

#### 📦 mysqldump

| Option            | Bedeutung                   | Empfehlung |
|-------------------|-----------------------------|------------|
| `quick`           | Zeilenweiser Export         | Aktivieren |
| `quote-names`     | Sonderzeichen in Backticks  | Aktivieren |
| `max_allowed_packet` | Paketgröße bei Dumps     | `64M` oder höher |

---

### 🧩 Hinweise zur sicheren Konfiguration

- Trenne `[client]` und `[mysqld]`; TLS-Optionen in `[mysqld]`.
- TLS aktivieren, Zertifikate mit Owner `mysql:mysql`, Rechte `0600`; TLS-Zwang via `REQUIRE SSL`.
- `local_infile=0`, `secure_file_priv` setzen und `symbolic-links=0` für mehr Schutz.
- Applikations-User mit Minimalrechten; nicht mit `root` arbeiten.
- Backups & Wiederherstellung testen; Binlog-Aufbewahrung planen.
- Pfade und Rechte je Distribution/AppArmor/SELinux prüfen.

---

### 📁 Volumes & Mounts

| Mount                                          | Beschreibung                                 |
|-----------------------------------------------|----------------------------------------------|
| `mariadb_data:/var/lib/mysql`                  | Persistente Daten                            |
| `./initdb:/docker-entrypoint-initdb.d:ro`      | Initiale SQL-Skripte (nur beim ersten Start) |
| `../mariadb.cnf:/etc/mysql/conf.d/my.cnf:ro`   | Eigene Konfiguration                         |
| `./conf.d/:/etc/mysql/conf.d/:ro` *(optional)* | Zusätzliche Konfigurationen                  |

---

### 🌐 Ports

| Port   | Dienst  | Beschreibung     |
|--------|---------|------------------|
| `3306` | MariaDB | Datenbankzugriff |
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
docker volume rm <projektname>_mariadb_data
```

### 💻 Zugriff auf die MariaDB-Konsole

```bash
docker compose exec mariadb mariadb -uroot -p
```

Oder über Adminer im Browser: [http://localhost:8080](http://localhost:8080)

---

© 2025 – Sichere Datenbankkonfigurationen

