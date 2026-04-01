# <img src="https://cdn.worldvectorlogo.com/logos/mariadb.svg" alt="MariaDB Logo" width="26"/> MariaDB – Windows

- [💾 Windows installation notes](#-windows-installation-notes)
  - [📁 Create the data directory](#-create-the-data-directory)
  - [🚀 Start MariaDB (example)](#-start-mariadb-example)
- [📑 Parameter reference (short)](#-parameter-reference-short)
  - [🔒 Security & network](#-security--network)
  - [🔐 TLS/SSL](#-tlsssl)
  - [💾 Storage & performance](#-storage--performance)
  - [🌐 Character sets](#-character-sets)
  - [📊 Logging](#-logging)
  - [🔁 binary log](#-binary-log)
  - [📦 mysqldump](#-mysqldump)
- [🧩 Secure configuration notes](#-secure-configuration-notes)
- [🧩 MariaDB init script (`init_mariadb.bat`)](#-mariadb-init-script-init_mariadbbat)
  - [⚙️ Script flow](#️-script-flow)
  - [🎯 Purpose](#-purpose)
  - [⚠️ Notes](#️-notes)
- [🛠️ MariaDB Windows commands](#-mariadb-windows-commands)
  - [1️⃣ Start and stop the MariaDB service](#1️⃣-start-and-stop-the-mariadb-service)
  - [2️⃣ Show service information](#2️⃣-show-service-information)
  - [3️⃣ Check and stop the MariaDB server process](#3️⃣-check-and-stop-the-mariadb-server-process)
  - [4️⃣ Delete or reinstall the MariaDB service](#4️⃣-delete-or-reinstall-the-mariadb-service)
  - [🔹 Tips](#-tips)

---

## 💾 Windows installation notes

Install via the **MariaDB Community Installer** from:  
➡️ [https://mariadb.org/download/](https://mariadb.org/download/)

After installation the default binary path is usually:  
`C:\Program Files\MariaDB 11.8\bin\`

The config file (`my.ini`) is typically at:  
`C:\Program Files\MariaDB 11.8\data\my.ini`

### 📁 Create the data directory

If you need to create it manually:

```bash
cd C:\
md "\data\mariadb"
```

You can set the data directory in `my.ini` via `datadir`, e.g.:

```ini
[mysqld]
datadir=C:\data\mariadb
```

### 🚀 Start MariaDB (example)

Start MariaDB with a custom data directory:

```bash
"C:\Program Files\MariaDB 11.8\bin\mysqld.exe" --defaults-file="C:\Program Files\MariaDB 11.8\data\my.ini"
```

Or interactively via the MariaDB client:

```bash
"C:\Program Files\MariaDB 11.8\bin\mysql.exe" -u root -p
```

More info:
➡️ [Official MariaDB docs – Windows installation](https://mariadb.com/kb/en/installing-mariadb-msi-packages-on-windows/)

---

# 📑 Parameter reference (short)

## 🔒 Security & network

| Option              | Meaning                     | Recommendation |
|---------------------|-----------------------------|----------------|
| `bind_address`      | Bind IP                     | `127.0.0.1` (or VPN IP) |
| `skip_networking`   | Disable TCP/IP              | `0`; only `1` if local-only |
| `skip_name_resolve` | Avoid DNS lookups           | `1` |
| `max_connections`   | Max clients                 | 100–500 depending on workload |
| `local_infile`      | `LOAD DATA LOCAL INFILE`    | `0` (disable) |
| `secure_file_priv`  | Import/export directory     | Set dedicated path or `NULL` |
| `symbolic-links`    | Symlinks in tables          | `0` (disable) |

## 🔐 TLS/SSL

| Option    | Meaning           | Recommendation |
|-----------|-------------------|----------------|
| `ssl-ca`  | CA certificate    | `C:/mariadb/ssl/ca-cert.pem` |
| `ssl-cert`| Server certificate| `C:/mariadb/ssl/server-cert.pem` |
| `ssl-key` | Server key        | `C:/mariadb/ssl/server-key.pem` |

Creation of TLS certificate, see [README](../../../../README.md#-tls-configuration)

> Enforce TLS via SQL: `ALTER USER 'app'@'%' REQUIRE SSL;`

## 💾 Storage & performance

| Option                       | Meaning                  | Recommendation |
|------------------------------|--------------------------|----------------|
| `innodb_buffer_pool_size`    | InnoDB buffer            | 50–80% of RAM |
| `innodb_log_file_size`       | Redo log size            | 128–512 MB |
| `innodb_file_per_table`      | Separate tablespace      | `1` |
| `innodb_flush_log_at_trx_commit` | Durability vs performance | `1` (ACID), `2` if needed |
| `innodb_flush_method`        | I/O handling             | `O_DIRECT` recommended |
| `aria_pagecache_buffer_size` | Aria cache               | ~128 MB (workload-dependent) |
| `aria_log_file_size`         | Aria log size            | ~64 MB |

## 🌐 Character sets

| Option                  | Meaning            | Recommendation |
|-------------------------|--------------------|----------------|
| `character_set_server`  | Default charset    | `utf8mb4` |
| `collation_server`      | Collation          | `utf8mb4_general_ci` |

## 📊 Logging

| Option                       | Meaning                     | Recommendation |
|------------------------------|-----------------------------|----------------|
| `log_error`                  | Error log                   | Set |
| `slow_query_log`             | Slow queries                | Enable |
| `slow_query_log_file`        | Slow query log path         | e.g., `C:/Program Files/.../mysql-slow.log` |
| `long_query_time`            | Slow threshold              | 1–2 s |
| `log_queries_not_using_indexes` | Inefficient queries     | Enable consciously |
| `general_log`                | All queries (debug)         | `0` in prod |
| `general_log_file`           | Path for general query log  | e.g. `C:/Program Files/MariaDB 11.8/data/mysql/mysql-general.log` |

## 🔁 binary log

| Option                  | Meaning              | Recommendation |
|-------------------------|----------------------|----------------|
| `log_bin`               | Enable binlog        | Set path |
| `log_bin_index`         | Index file           | Set path |
| `binlog_format`         | Binlog format        | `MIXED` or `ROW` |
| `sync_binlog`           | Synchronization      | `1` |
| `expire_logs_days`      | Binlog retention     | 7–14 days |
| `binlog_expire_logs_seconds` | Binlog retention (new) | 7–14 days (604800–1209600) |

## 📦 mysqldump

| Option            | Meaning                   | Recommendation |
|-------------------|---------------------------|----------------|
| `quick`           | Stream row by row         | Enable |
| `quote-names`     | Backtick identifiers      | Enable |
| `max_allowed_packet` | Packet size for dumps  | `64M` or higher |

---

## 🧩 Secure configuration notes

- Separate `[client]` and `[mysqld]`; put TLS options in `[mysqld]`.
- Certificates owned by the MariaDB service account, restrictive ACLs; enforce TLS via `REQUIRE SSL`.
- Set `local_infile=0`, `secure_file_priv`, and `symbolic-links=0` for extra safety.
- Give app users minimal privileges; avoid working as `root`.
- Test backups and restores; plan binlog retention.
- Check paths and permissions for your Windows installation.

---

## 🧩 MariaDB init script (`init_mariadb.bat`)

This script automates the **first-time initialization of a MariaDB instance on Windows**.  
It creates users, permissions, and default databases before the service runs normally.

### ⚙️ Script flow

1. Stop the `MariaDB` service to avoid port conflicts.  
2. Start the service; wait briefly.  
3. Launch a temporary MariaDB server with the given `my.ini`.  
4. Execute `init_users.sql` (users/passwords/DB/privileges).  
5. Shut down the temporary server via `mysqladmin shutdown`.  
6. Start the service again—initialization complete.

### 🎯 Purpose

- Fast, repeatable, and secure initial configuration  
- Create users, databases, and permissions before production use

### ⚠️ Notes

- Run the script with administrator rights (service start/stop).  
- Set `ROOT_PASS` in the script.  
- Verify `CONFIG_FILE` and `INIT_SQL` paths.

---

## 🛠️ MariaDB Windows commands

Commands for managing MariaDB on Windows.

### 1️⃣ Start and stop the MariaDB service

| Command             | Description                                                                 |
| ------------------- | --------------------------------------------------------------------------- |
| `net start MariaDB` | Starts the Windows service `MariaDB`; the service then runs in background.  |
| `net stop MariaDB`  | Stops the Windows service `MariaDB` cleanly.                                |

> ⚠️ Administrator rights required.

### 2️⃣ Show service information

| Command                  | Description                                                                          |
| -----------------------  | ------------------------------------------------------------------------------------ |
| `sc qc MariaDB`          | Shows the **service configuration** (install path, start type, parameters).          |
| `sc query MariaDB`       | Shows the **current service status** (RUNNING, STOPPED, etc.).                       |
| `sc query type= service \| findstr /I MariaDB` | Filters all services for “MariaDB”, shows relevant lines only. |

### 3️⃣ Check and stop the MariaDB server process

| Command                                   | Description                                                        |
| ----------------------------------------  | ------------------------------------------------------------------ |
| `tasklist /FI "IMAGENAME eq mysqld.exe"`  | Checks if the MariaDB server process `mysqld.exe` is running.      |
| `taskkill /IM mysqld.exe /F`              | Force-stops the MariaDB server process.                            |

> ⚠️ Use only if the service is not in use.

### 4️⃣ Delete or reinstall the MariaDB service

| Command                                                                                                 | Description                                                                              |
| ------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------- |
| `sc delete MariaDB`                                                                                    | Removes the registered MariaDB service from Windows. Database files remain.              |
| `"C:\Program Files\MariaDB 11.8\bin\mysqld.exe" --install MariaDB --defaults-file="C:\Pfad\zu\my.ini"` | Installs a new Windows service `MariaDB` with the given config file.                     |

> ⚠️ Administrator rights required. The path to `my.ini` must be correct.

### 🔹 Tips

- Service vs process: service → `net start/stop`, `sc query/qc`; process → `mysqld.exe`, controlled via `tasklist`/`taskkill`.  
- Admin rights are required for service actions.  
- Check logs: e.g., `C:\Program Files\MariaDB 11.8\data\` or configured log directory.  
- Enable TLS once certificates exist; use `REQUIRE SSL`.  
- Set `secure_file_priv` to restrict file imports/exports.

© 2025 – Secure database configurations

