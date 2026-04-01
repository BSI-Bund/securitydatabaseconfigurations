# <img src="https://www.vectorlogo.zone/logos/mysql/mysql-icon.svg" alt="MySQL Logo" width="26"/> MySQL – Windows

- [💾 Windows installation notes](#-windows-installation-notes)
  - [📁 Create the data directory](#-create-the-data-directory)
  - [🚀 Start MySQL (example)](#-start-mysql-example)
- [📑 Parameter reference (short)](#-parameter-reference-short)
  - [🔒 Network & access](#-network--access)
  - [🔐 TLS/SSL](#-tlsssl)
  - [💾 InnoDB – performance & durability](#-innodb--performance--durability)
  - [🌐 Character sets](#-character-sets)
  - [📊 Logging & diagnostics](#-logging--diagnostics)
  - [🔁 binary log](#-binary-log)
  - [📦 mysqldump](#-mysqldump)
- [🧩 Secure configuration notes](#-secure-configuration-notes)
- [🛠️ MySQL Windows commands](#-mysql-windows-commands)
  - [1️⃣ Start and stop the MySQL service](#1️⃣-start-and-stop-the-mysql-service)
  - [2️⃣ Show service information](#2️⃣-show-service-information)
  - [3️⃣ Check and stop the MySQL server process](#3️⃣-check-and-stop-the-mysql-server-process)
  - [4️⃣ Delete or reinstall the MySQL service](#4️⃣-delete-or-reinstall-the-mysql-service)
  - [🔹 Tips](#-tips)

---

## 💾 Windows installation notes

Install via the **MySQL Installer for Windows**:  
➡️ [https://dev.mysql.com/downloads/installer/](https://dev.mysql.com/downloads/installer/)

Default paths after installation:

- Binaries: `C:\Program Files\MySQL\MySQL Server 8.4\bin\`
- Config file: `C:\Program Files\MySQL\MySQL Server 8.4\my.ini`
- Data directory: `C:\ProgramData\MySQL\MySQL Server 8.4\Data`
- Log directory (recommended): `C:\Program Files\MySQL\MySQL Server 8.4\logs\`

> Create the `logs` folder manually if needed; the service account needs write access.

### 📁 Create the data directory

```powershell
cd C:\
md "C:\ProgramData\MySQL\MySQL Server 8.4\Data"
```

`my.ini` example:

```ini
[mysqld]
datadir = C:/ProgramData/MySQL/MySQL Server 8.4/Data
```

### 🚀 Start MySQL (example)

```powershell
cd "C:\Program Files\MySQL\MySQL Server 8.4\bin"
mysqld --defaults-file="C:\Program Files\MySQL\MySQL Server 8.4\my.ini" --console
```

MySQL client:

```powershell
"C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe" -u root -p
```

More info: [MySQL 8.4 Reference Manual – Installing on Windows](https://dev.mysql.com/doc/refman/8.4/en/windows-installation.html)

---

# 📑 Parameter reference (short)

## 🔒 Network & access

| Option                  | Meaning                       | Recommendation |
|-------------------------|--------------------------------|----------------|
| `bind_address`          | Interface binding             | `127.0.0.1` (or VPN IP) |
| `skip_networking`       | Disable TCP/IP                | `0`; only `1` for named-pipe only |
| `skip_name_resolve`     | Avoid DNS lookups             | `1`; use IPs in `CREATE USER` |
| `max_connections`       | Concurrent connections        | 100–500 depending on workload |
| `local_infile`          | Client file upload via SQL    | `0` (lock down hard) |
| `secure_file_priv`      | Whitelist folder for INFILE   | Set dedicated folder or `NULL` |
| `lower_case_table_names`| Case semantics (Windows)      | `1` (required) |

## 🔐 TLS/SSL

| Option                      | Meaning                     | Recommendation |
|-----------------------------|-----------------------------|----------------|
| `ssl-ca` / `ssl-cert` / `ssl-key` | CA/server certificates | Set paths; restrict permissions |
| `require_secure_transport`  | Only allow secure transport | `ON` after TLS setup |

Creation of TLS certificate, see [README](../../../../README.md#-tls-configuration)

## 💾 InnoDB – performance & durability

| Option                          | Effect                          | Recommendation |
|---------------------------------|---------------------------------|----------------|
| `innodb_buffer_pool_size`       | Main cache                      | 50–80% of RAM |
| `innodb_redo_log_capacity`      | Total redo log size (≥8.0)      | 1–4 GB depending on write load |
| `innodb_file_per_table`         | Separate tablespaces            | `1` |
| `innodb_flush_log_at_trx_commit`| Durability vs. throughput       | `1` (ACID), `2` if you need throughput |

## 🌐 Character sets

| Option                 | Recommendation        |
|------------------------|-----------------------|
| `character_set_server` | `utf8mb4`             |
| `collation_server`     | `utf8mb4_0900_ai_ci`  |

## 📊 Logging & diagnostics

| Option                       | Purpose                       | Recommendation |
|------------------------------|-------------------------------|----------------|
| `log_error`                  | Error log                     | Always set |
| `slow_query_log`             | Slow queries                  | Enable; `long_query_time=1–2s` |
| `slow_query_log_file`        | Slow query log path           | e.g. `C:/Program Files/.../mysql-slow.log` |
| `long_query_time`            | Slow threshold                | 1–2 s |
| `log_queries_not_using_indexes` | Detect index misses        | Enable during tuning |
| `general_log`                | Log all queries               | Prod: `0` |
| `general_log_file`           | Path for general query log    | e.g. `C:/Program Files/MySQL/MySQL Server 8.4/logs/mysql-general.log` |

## 🔁 binary log

| Option                      | Recommendation / note         |
|-----------------------------|-------------------------------|
| `log-bin`, `log-bin-index`  | Binary log for PITR/replication |
| `binlog_format`             | `ROW` recommended             |
| `sync_binlog`               | `1` for durability            |
| `binlog_expire_logs_seconds`| 7–14 days                     |

## 📦 mysqldump

| Option              | Effect                  | Recommendation |
|---------------------|-------------------------|----------------|
| `quick`             | Streams row by row      | Enable |
| `quote-names`       | Escapes identifiers     | Enable |
| `max_allowed_packet`| Larger rows/blobs       | ≥ `64M` |

---

## 🧩 Secure configuration notes

- Configure TLS, then set `require_secure_transport=ON`.  
- Combine `local_infile=0` with `secure_file_priv` to control file IO.  
- Strong passwords, minimum privileges for app users; do not run daily work as `root`.  
- Keep binlog rotation (`binlog_expire_logs_seconds`) and backups in check.  
- Adapt paths (logs/SSL/data) to your installation; set permissions for the service account.

---

## 🛠️ MySQL Windows commands

### 1️⃣ Start and stop the MySQL service

| Command           | Description                                                                  |
|-------------------|------------------------------------------------------------------------------|
| `net start MySQL` | Starts the Windows service `MySQL`. The server then runs in the background.  |
| `net stop MySQL`  | Stops the Windows service `MySQL` cleanly.                                   |

> ⚠️ Administrator rights required.

### 2️⃣ Show service information

| Command                                       | Description                                                                          |
|-----------------------------------------------|--------------------------------------------------------------------------------------|
| `sc qc MySQL`                                 | Shows the service configuration.                                                     |
| `sc query MySQL`                              | Shows the status (RUNNING/STOPPED).                                                  |
| `sc query type= service \| findstr /I MySQL`  | Filters services by “MySQL”.                                                         |

### 3️⃣ Check and stop the MySQL server process

| Command                                   | Description                                               |
|-------------------------------------------|-----------------------------------------------------------|
| `tasklist /FI "IMAGENAME eq mysqld.exe"`  | Checks whether `mysqld.exe` is running.                  |
| `taskkill /IM mysqld.exe /F`              | Force-stops the MySQL server process (only in emergencies). |

### 4️⃣ Delete or reinstall the MySQL service

| Command                                                                                                          | Description                                                                            |
|------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------|
| `sc delete MySQL`                                                                                                 | Removes the registered MySQL service. Data/config remain.                              |
| `"C:\Program Files\MySQL\MySQL Server 8.4\bin\mysqld.exe" --install MySQL --defaults-file="C:\Pfad\zu\my.ini"`    | Installs a new service `MySQL` with the given config file.                             |

> ⚠️ Administrator rights required; the `my.ini` path must be correct.

### 🔹 Tips

- Control services via `net`/`sc`; control processes via `tasklist`/`taskkill`.  
- Check error logs: `C:\Program Files\MySQL\MySQL Server 8.4\logs\error.log` (if configured).  
- Enable TLS, set `secure_file_priv`, lock down root access.

---

© 2025 – Secure database configurations

