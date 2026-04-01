# <img src="https://cdn.worldvectorlogo.com/logos/mariadb.svg" alt="MariaDB Logo" width="26"/> MariaDB – Linux (Docker Compose)

- [🚀 Getting started with the Docker Compose setup](#-getting-started-with-the-docker-compose-setup)
  - [⚙️ Services](#️-services)
    - [🗄️ mariadb](#-mariadb)
    - [🧰 adminer](#-adminer)
  - [🧾 Environment variables](#-environment-variables)
- [📑 Parameter reference (short)](#-parameter-reference-short)
    - [🔒 Security & network](#-security--network)
    - [🔐 TLS/SSL](#-tlsssl)
    - [💾 Storage & performance](#-storage--performance)
    - [🌐 Character sets](#-character-sets)
    - [📊 Logging](#-logging)
    - [🔁 binary log](#-binary-log)
    - [📦 mysqldump](#-mysqldump)
  - [🧩 Secure configuration notes](#-secure-configuration-notes)
  - [📁 Volumes & mounts](#-volumes--mounts)
  - [🌐 Ports](#-ports)
- [🎛️ Start & operations](#️-start--operations)

---

## 🚀 Getting started with the Docker Compose setup

This setup provides a **MariaDB 11.8 instance** plus an **Adminer web UI**.  
It is based on official images:
- [MariaDB on Docker Hub](https://hub.docker.com/_/mariadb)
- [Adminer on Docker Hub](https://hub.docker.com/_/adminer)

Configuration:

```bash
docker-compose.yml  # uses values from .env
```

---

### ⚙️ Services

#### 🗄️ mariadb

- Image `mariadb:11.8`
- Starts with custom `my.cnf`
- Initializes with SQL scripts in `./initdb/`
- Persistent data in `mariadb_data`
- Health check validates root login

#### 🧰 adminer

- Web UI for MariaDB
- Runs on port **8080**
- Automatically connects to `mariadb`

---

### 🧾 Environment variables

Example values live in `mariadb-compose/.env.example`. Copy and adjust before starting:

```bash
cd mariadb-compose
cp .env.example .env
```

---

### 📑 Parameter reference (short)

#### 🔒 Security & network

| Option              | Meaning                        | Recommendation |
|---------------------|--------------------------------|----------------|
| `bind_address`      | Bind IP                        | `127.0.0.1` or VPN IP (`0.0.0.0` localhost by docker compose file)|
| `skip_networking`   | Disable TCP/IP                 | `0`; only `1` if socket-only |
| `skip_name_resolve` | Avoid DNS lookups              | `1` |
| `max_connections`   | Max clients                    | 100–500 depending on workload |
| `local_infile`      | `LOAD DATA LOCAL INFILE`       | `0` (disable) |
| `secure_file_priv`  | Folder for import/export       | Set dedicated path or `NULL` |
| `symbolic-links`    | Symlink usage                  | `0` (disable) |

#### 🔐 TLS/SSL

| Option    | Meaning               | Recommendation |
|-----------|-----------------------|----------------|
| `ssl-ca`  | CA certificate        | e.g., `/etc/mysql/ssl/ca-cert.pem` |
| `ssl-cert`| Server certificate    | e.g., `/etc/mysql/ssl/server-cert.pem` |
| `ssl-key` | Server key            | e.g., `/etc/mysql/ssl/server-key.pem` |

Creation of TLS certificate, see [README](../../../../README.md#-tls-configuration)

> Enforce TLS via SQL: `ALTER USER 'app'@'%' REQUIRE SSL;`

#### 💾 Storage & performance

| Option                       | Meaning                  | Recommendation |
|------------------------------|--------------------------|----------------|
| `innodb_buffer_pool_size`    | InnoDB buffer            | 50–80% of RAM |
| `innodb_log_file_size`       | Redo log size            | 128–512 MB |
| `innodb_file_per_table`      | Separate tablespace      | `1` |
| `innodb_flush_log_at_trx_commit` | Durability vs performance | `1` (ACID), `2` if needed |
| `innodb_flush_method`        | I/O handling             | `O_DIRECT` recommended |
| `aria_pagecache_buffer_size` | Aria cache               | ~128 MB (workload-dependent) |
| `aria_log_file_size`         | Aria log size            | ~64 MB |

#### 🌐 Character sets

| Option                  | Meaning            | Recommendation |
|-------------------------|--------------------|----------------|
| `character_set_server`  | Default charset    | `utf8mb4` |
| `collation_server`      | Collation          | `utf8mb4_general_ci` |

#### 📊 Logging

| Option                       | Meaning                     | Recommendation |
|------------------------------|-----------------------------|----------------|
| `log_error`                  | Error log                   | Set |
| `slow_query_log`             | Slow queries                | Enable |
| `slow_query_log_file`        | Slow query log path         | e.g., `/var/log/mysql/mysql-slow.log` |
| `long_query_time`            | Slow threshold              | 1–2 s |
| `log_queries_not_using_indexes` | Inefficient queries     | Enable cautiously |
| `general_log`                | All queries (debug)         | `0` in prod |
| `general_log_file`           | Path for general query log    | e.g. `/var/log/mysql/mysql-general.log` |

#### 🔁 binary log

| Option                  | Meaning              | Recommendation |
|-------------------------|----------------------|----------------|
| `log_bin`               | Enable binlog        | Set path |
| `log_bin_index`         | Index file           | Set path |
| `binlog_format`         | Binlog format        | `MIXED` or `ROW` |
| `sync_binlog`           | Synchronization      | `1` |
| `expire_logs_days`      | Binlog retention     | 7–14 days |
| `binlog_expire_logs_seconds` | Binlog retention (new) | 7–14 days (604800–1209600) |

#### 📦 mysqldump

| Option            | Meaning                  | Recommendation |
|-------------------|--------------------------|----------------|
| `quick`           | Stream row by row        | Enable |
| `quote-names`     | Backtick identifiers     | Enable |
| `max_allowed_packet` | Packet size for dumps | `64M` or higher |

---

### 🧩 Secure configuration notes

- Separate `[client]` and `[mysqld]`; put TLS options in `[mysqld]`.
- Enable TLS, certificates owned by `mysql:mysql`, mode `0600`; enforce TLS via `REQUIRE SSL`.
- Set `local_infile=0`, `secure_file_priv`, and `symbolic-links=0` for extra safety.
- Give app users minimal privileges; avoid day-to-day work as `root`.
- Test backups and restores; plan binlog retention.
- Check paths/permissions per distribution/AppArmor/SELinux.

---

### 📁 Volumes & mounts

| Mount                                          | Description                                  |
|-----------------------------------------------|----------------------------------------------|
| `mariadb_data:/var/lib/mysql`                  | Persistent data                              |
| `./initdb:/docker-entrypoint-initdb.d:ro`      | Initial SQL scripts (first start only)       |
| `../mariadb.cnf:/etc/mysql/conf.d/my.cnf:ro`   | Custom configuration                         |
| `./conf.d/:/etc/mysql/conf.d/:ro` *(optional)* | Additional configurations                    |

---

### 🌐 Ports

| Port   | Service | Description     |
|--------|---------|-----------------|
| `3306` | MariaDB | Database access |
| `8080` | Adminer | Web interface   |

---

## 🎛️ Start & operations

### ▶️ Start

```bash
docker compose up -d
```

### ⏹️ Stop

```bash
docker compose down
```

### 🧾 Show logs

```bash
docker compose logs -f
```

### 🧹 Remove the database volume (optional)

```bash
docker volume rm <project>_mariadb_data
```

### 💻 Access the MariaDB console

```bash
docker compose exec mariadb mariadb -uroot -p
```

Or via Adminer in the browser: [http://localhost:8080](http://localhost:8080)

---

© 2025 – Secure database configurations

