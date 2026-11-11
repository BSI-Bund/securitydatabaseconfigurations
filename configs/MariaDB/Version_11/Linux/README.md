# MariaDB – Linux with Docker Compose

[Deutsch](README-de.md) · [Database overview](../../README.md) · [BSI alignment](../../../README.md#bsi-alignment)

This template combines **MariaDB 11.8** and Adminer. The database configuration is [`mariadb.cnf`](mariadb.cnf); the Compose file is [`mariadb-compose/docker-compose.yml`](mariadb-compose/docker-compose.yml).

- [Preparation](#preparation)
- [Startup and login](#startup-and-login)
- [Verify the configuration](#verify-the-configuration)
- [Parameter reference](#parameter-reference)
  - [Security & network](#security--network)
  - [TLS/SSL](#tlsssl)
  - [Storage & performance](#storage--performance)
  - [Character sets](#character-sets)
  - [Logging](#logging)
  - [binary log](#binary-log)
  - [mysqldump](#mysqldump)
- [Files and operations](#files-and-operations)
- [References](#references)

## Preparation

Install Docker with Compose and provide enough memory for the configured buffers. The template sets `innodb_buffer_pool_size=4G`; adapt it to available memory before startup.

Run all following Compose commands from `mariadb-compose/`. Starting from this README directory:

```bash
cd mariadb-compose
cp .env.example .env
mkdir -p ssl
```

1. Replace every sample password in `.env` and adjust `DB_PORT` if needed.
2. Follow the [TLS guide](../../../../docs/TLS.md) to prepare `ssl/ca-cert.pem`, `ssl/server-cert.pem`, and `ssl/server-key.pem`. Rename generated files as needed; do not copy the private CA key.
3. Certificate SANs must cover `localhost` and the Compose service name `mariadb` so both host clients and Adminer can verify the server name.
4. Mounts are already included. The startup wrapper copies only the three required PEM files from read-only `ssl/` into a private tmpfs directory and sets ownership and permissions for `mysql`. The private key receives mode `0600`; the log directory is initialized with suitable permissions in persistent volume `mariadb_logs`.
5. Make the public CA certificate `ssl/ca-cert.pem` readable by the Adminer container, for example with mode `0644`. Keep private keys restricted. Then check the configuration:

```bash
docker compose config --quiet
```

`mariadb.cnf` already specifies certificate paths and `require_secure_transport=ON`. The template requires certificate integration before it is ready to start.

## Startup and login

```bash
docker compose up -d
docker compose ps
docker compose logs --tail 100 mariadb
```

Host ports are bound to `127.0.0.1`: database `${DB_PORT:-3306}`, Adminer `8080`. `bind_address=0.0.0.0` applies to interfaces **inside the container** and is needed for connections from other containers.

`MARIADB_USER` and `MARIADB_PASSWORD` create an application account for `MARIADB_DATABASE` on first startup. `MARIADB_ROOT_PASSWORD` belongs to the administration account. Scripts in `initdb/` run only with an empty data volume; editing `.env` does not change existing database passwords.

For an administrative check over the local socket:

```bash
docker compose exec mariadb mariadb -uroot -p
```

Adminer is available at `http://127.0.0.1:8080`, with `mariadb` prefilled as the server. Log in with the application account. The included `adminer-tls.php` plugin enables TLS with CA and server name verification for the database connection. The local Adminer web UI itself uses HTTP.

## Verify the configuration

The tables below contain recommendations; `mariadb.cnf` contains the actual settings. Check, among others, `SHOW VARIABLES LIKE 'require_secure_transport';`, `SHOW VARIABLES LIKE 'ssl_ca';`, and `SHOW GRANTS;`. `initdb/check_config.sql` contains further read-only checks and can be run from an administrative session.

Use a client with the generated CA files and certificate name verification for the TLS test. A socket login or successful healthcheck does not prove that a TCP connection is encrypted.

For a TCP test from the host, install the MariaDB client and run from the Compose directory. Adapt the port and account to `.env`; the certificate SAN must include `localhost`:

```bash
mariadb --protocol=TCP --host=localhost --port=3306 --user=appuser --password --ssl --ssl-verify-server-cert --ssl-ca=ssl/ca-cert.pem
```

In that connection, check `SHOW SESSION STATUS LIKE 'Ssl_cipher';`.

## Parameter reference

### Security & network

| Option              | Meaning                        | Recommendation |
|---------------------|--------------------------------|----------------|
| `bind_address`      | Bind IP                        | `127.0.0.1` or VPN IP (`0.0.0.0` inside the container; host port bound to `127.0.0.1`)|
| `skip_networking`   | Disable TCP/IP                 | `0`; only `1` if socket-only |
| `skip_name_resolve` | Avoid DNS lookups              | `1` |
| `max_connections`   | Max clients                    | 100–500 depending on workload |
| `local_infile`      | `LOAD DATA LOCAL INFILE`       | `0` (disable) |
| `secure_file_priv` | Import/export directory | Set a dedicated directory; commented out in the template |
| `symbolic-links`    | Symlink usage                  | `0` (disable) |

### TLS/SSL

| Option    | Meaning               | Recommendation |
|-----------|-----------------------|----------------|
| `ssl-ca`  | CA certificate        | e.g., `/etc/mysql/ssl/ca-cert.pem` |
| `ssl-cert`| Server certificate    | e.g., `/etc/mysql/ssl/server-cert.pem` |
| `ssl-key` | Server key            | e.g., `/etc/mysql/ssl/server-key.pem` |

> Enforce TLS via SQL: `ALTER USER 'appuser'@'%' REQUIRE SSL;`

### Storage & performance

| Option                       | Meaning                  | Recommendation |
|------------------------------|--------------------------|----------------|
| `innodb_buffer_pool_size`    | InnoDB buffer            | Tune for available RAM and workload |
| `innodb_log_file_size`       | Redo log size            | 128–512 MB |
| `innodb_file_per_table`      | Separate tablespace      | `1` |
| `innodb_flush_log_at_trx_commit` | Durability vs performance | `1` (ACID), `2` if needed |
| `innodb_flush_method`        | I/O handling             | `O_DIRECT` recommended |
| `aria_pagecache_buffer_size` | Aria cache               | ~128 MB (workload-dependent) |
| `aria_log_file_size`         | Aria log size            | ~64 MB |

### Character sets

| Option                  | Meaning            | Recommendation |
|-------------------------|--------------------|----------------|
| `character_set_server`  | Default charset    | `utf8mb4` |
| `collation_server`      | Collation          | `utf8mb4_general_ci` |

### Logging

| Option                       | Meaning                     | Recommendation |
|------------------------------|-----------------------------|----------------|
| `log_error`                  | Error log                   | Set |
| `slow_query_log`             | Slow queries                | Enable |
| `slow_query_log_file`        | Slow query log path         | e.g., `/var/log/mysql/mysql-slow.log` |
| `long_query_time`            | Slow threshold              | 1–2 s |
| `log_queries_not_using_indexes` | Inefficient queries     | Enable cautiously |
| `general_log`                | All queries (debug)         | `0` in prod |
| `general_log_file`           | Path for general query log    | e.g. `/var/log/mysql/mysql-general.log` |

### binary log

| Option                  | Meaning              | Recommendation |
|-------------------------|----------------------|----------------|
| `log_bin`               | Enable binlog        | Set path |
| `log_bin_index`         | Index file           | Set path |
| `binlog_format`         | Binlog format        | `MIXED` or `ROW` |
| `sync_binlog`           | Synchronization      | `1` |
| `expire_logs_days`      | Binlog retention     | 7–14 days |
| `binlog_expire_logs_seconds` | Binlog retention (new) | 7–14 days (604800–1209600) |

### mysqldump

| Option            | Meaning                  | Recommendation |
|-------------------|--------------------------|----------------|
| `quick`           | Stream row by row        | Enable |
| `quote-names`     | Backtick identifiers     | Enable |
| `max_allowed_packet` | Packet size for dumps | `64M` or higher |

When rotating certificates, replace the source files in `ssl/` and run `docker compose restart mariadb` to recreate the protected runtime copies. Then verify the TLS connection again.

## Files and operations

| File or mount | Purpose |
|---------------|---------|
| `../mariadb.cnf:/etc/mysql/conf.d/my.cnf:ro` | Server configuration |
| `./initdb:/docker-entrypoint-initdb.d:ro` | First-start initialization |
| `mariadb_data:/var/lib/mysql` | Persistent data |
| `./ssl:/run/tls-source:ro` | Certificate source; private runtime copy under `/etc/mysql/ssl` |
| `mariadb_logs:/var/log/mysql` | Persistent database logs |

The database writes error, slow-query, and binary logs to `/var/log/mysql`. `docker compose logs` shows container output; review the log files separately.

```bash
docker compose stop
docker compose start
docker compose down
```

`down` removes containers and the network while retaining the data volume. Plan and protect backups separately and verify them through restore tests. Initialization scripts and binary logs are not a complete backup process. When running multiple setups, adjust fixed container names and overlapping default host ports.

## References

- [MariaDB Docker image](https://hub.docker.com/_/mariadb)
- [Adminer extensions](https://www.adminer.org/en/plugins/)
- [Shared TLS guide](../../../../docs/TLS.md)
