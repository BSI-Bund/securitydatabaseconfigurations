# <img src="https://www.vectorlogo.zone/logos/mysql/mysql-icon.svg" alt="MySQL Logo" width="26"/> MySQL – Linux (Docker Compose)

- [🚀 Getting started with the Docker Compose setup](#-getting-started-with-the-docker-compose-setup)
  - [⚙️ Services](#️-services)
    - [🗄️ mysql](#-mysql)
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
- [🎛️ Start & management](#-start--management)

---

## 🚀 Getting started with the Docker Compose setup

This setup provides a **MySQL 8.4.6 instance** plus an **Adminer web UI**.  
It is based on official images:
- [MySQL on Docker Hub](https://hub.docker.com/_/mysql)
- [Adminer on Docker Hub](https://hub.docker.com/_/adminer)

Configuration:

```bash
docker-compose.yml  # uses values from .env
```

---

### ⚙️ Services

#### 🗄️ mysql

- Image `mysql:8.4.6`
- Starts with custom `my.cnf`
- Initializes with SQL scripts in `./initdb/`
- Persistent data in the `mysql_data` volume
- Healthcheck verifies root login

#### 🧰 adminer

- Web UI for MySQL
- Runs on port **8080**
- Automatically connects to `mysql`

---

### 🧾 Environment variables

Example values live in `mysql-compose/.env.example`. Copy and adjust before starting:

```bash
cd mysql-compose
cp .env.example .env
```

---

### 📑 Parameter reference (short)

#### 🔒 Security & network

| Option              | Meaning                        | Recommendation |
|---------------------|--------------------------------|----------------|
| `bind_address`      | Bind IP                        | `127.0.0.1` or VPN IP; (`0.0.0.0` localhost by docker compose file) |
| `skip_networking`   | Disable TCP/IP                 | `0`; only `1` if socket-only |
| `skip_name_resolve` | Avoid DNS lookups              | `1`; use IPs in `CREATE USER` |
| `max_connections`   | Max connections                | 100–500 as needed |
| `local_infile`      | `LOAD DATA LOCAL INFILE`       | `0` (disable) |
| `secure_file_priv`  | Folder for import/export       | Set dedicated path or `NULL` (block) |

#### 🔐 TLS/SSL

| Option                      | Meaning                    | Recommendation |
|-----------------------------|----------------------------|----------------|
| `ssl-ca` / `ssl-cert` / `ssl-key` | CA/server certificates | Set paths, permissions `600`, owner `mysql:mysql` |
| `require_secure_transport`  | TLS/socket-only connections | `ON` after TLS setup |

Creation of TLS certificate, see [README](../../../../README.md#-tls-configuration)

#### 💾 Storage & performance

| Option                       | Meaning                     | Recommendation |
|------------------------------|-----------------------------|----------------|
| `innodb_buffer_pool_size`    | InnoDB main cache           | 50–80% of RAM |
| `innodb_redo_log_capacity`   | Total redo log size (new)   | 1–4 GB depending on write load |
| `innodb_log_file_size`       | Legacy redo log size        | 128–512 MB (if used) |
| `innodb_file_per_table`      | Separate tablespace         | `1` |
| `innodb_flush_log_at_trx_commit` | Durability vs. performance | `1` (ACID), `2` if needed |
| `innodb_flush_method`        | I/O strategy                | `O_DIRECT` optional |

#### 🌐 Character sets

| Option                  | Meaning            | Recommendation |
|-------------------------|--------------------|----------------|
| `character_set_server`  | Default charset    | `utf8mb4` |
| `collation_server`      | Sort order         | `utf8mb4_0900_ai_ci` |

#### 📊 Logging

| Option                       | Meaning                       | Recommendation |
|------------------------------|-------------------------------|----------------|
| `log_error`                  | Error log                     | File or container logs |
| `slow_query_log`             | Slow queries                  | `1` |
| `slow_query_log_file`        | Slow query log path           | e.g. `/var/log/mysql/mysql-slow.log` |
| `long_query_time`            | Slow threshold                | 1–2 s |
| `log_queries_not_using_indexes` | Log queries without indexes | Enable with care |
| `general_log`                | All statements (debug)        | `0` in prod |
| `general_log_file`           | Path for general query log    | e.g. `/var/log/mysql/mysql-general.log` |

#### 🔁 binary log

| Option                    | Meaning               | Recommendation |
|---------------------------|-----------------------|----------------|
| `log-bin` / `log_bin`     | Enable binary log     | Set path, plan rotation |
| `log-bin-index` / `log_bin_index` | Index file    | Set path |
| `sync_binlog`             | Binlog safety         | `1` |
| `binlog_expire_logs_seconds` | Retention           | 7–14 days (604800–1209600) |
| `expire_logs_days`        | Legacy retention      | 7–14 days |

#### 📦 mysqldump

| Option            | Meaning                  | Recommendation |
|-------------------|--------------------------|----------------|
| `quick`           | Stream row by row        | Enable |
| `quote-names`     | Backtick object names    | Enable |
| `max_allowed_packet` | Max packet size       | `64M` or higher for large dumps |
| *(CLI)*           | Consistent dump          | `--single-transaction` (CLI, not `my.cnf`) |

---

### 🧩 Secure configuration notes

- Separate `[client]` and `[mysqld]`; put TLS options in `[mysqld]`.
- Certificates with correct CN/SAN, owner `mysql:mysql`, mode `0600`; set `require_secure_transport=ON` after TLS.
- Combine `local_infile=0` with `secure_file_priv` to control data import/export.
- Avoid daily work as `root`; give app users minimal privileges.
- Test backups regularly; plan binlog retention and rotation.
- In containers, publish ports deliberately, use health checks, keep logs on `stdout/stderr` or mount log paths.

---

### 📁 Volumes & mounts

| Mount                                      | Description                                  |
|--------------------------------------------|----------------------------------------------|
| `mysql_data:/var/lib/mysql`                | Persistent data                              |
| `./initdb:/docker-entrypoint-initdb.d:ro`  | Initial SQL scripts (first start only)       |
| `./my.cnf:/etc/mysql/conf.d/my.cnf:ro`     | Custom configuration                         |
| `./conf.d/:/etc/mysql/conf.d/:ro` *(opt.)* | Additional configurations                    |

---

### 🌐 Ports

| Port   | Service | Description     |
|--------|---------|-----------------|
| `3306` | MySQL   | Database access |
| `8080` | Adminer | Web interface   |

---

## 🎛️ Start & management

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
docker volume rm <project>_mysql_data
```

### 💻 Access the MySQL console

```bash
docker compose exec mysql mysql -uroot -p
```

Or via Adminer in the browser: [http://localhost:8080](http://localhost:8080)

---

© 2025 – Secure database configurations

