# MySQL – Linux with Docker Compose

[Deutsch](README-de.md) · [Database overview](../../README.md) · [BSI alignment](../../../README.md#bsi-alignment)

This template combines **MySQL 8.4.6** and Adminer. The database configuration is [`my.cnf`](my.cnf); the Compose file is [`mysql-compose/docker-compose.yml`](mysql-compose/docker-compose.yml).

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

Run all following Compose commands from `mysql-compose/`. Starting from this README directory:

```bash
cd mysql-compose
cp .env.example .env
mkdir -p ssl
```

1. Replace every sample password in `.env` and adjust `DB_PORT` if needed.
2. Follow the [TLS guide](../../../../docs/TLS.md) to prepare `ssl/ca-cert.pem`, `ssl/server-cert.pem`, and `ssl/server-key.pem`. Rename generated files as needed; do not copy the private CA key.
3. Certificate SANs must cover `localhost` and the Compose service name `mysql` so both host clients and Adminer can verify the server name.
4. Mounts are already included. The startup wrapper copies only the three required PEM files from read-only `ssl/` into a private tmpfs directory and sets ownership and permissions for `mysql`. The private key receives mode `0600`; the log directory is initialized with suitable permissions in persistent volume `mysql_logs`.
5. Make the public CA certificate `ssl/ca-cert.pem` readable by the Adminer container, for example with mode `0644`. Keep private keys restricted. Then check the configuration:

```bash
docker compose config --quiet
```

`my.cnf` already specifies certificate paths and `require_secure_transport=ON`. The template requires certificate integration before it is ready to start.

The pinned MySQL 8.4.6 image uses a temporary client option file during bootstrap. `MYSQL_ROOT_PASSWORD` therefore must not contain double quotes, backslashes, or newlines. The startup wrapper checks this before initialization; a long randomly generated password, for example from `openssl rand -hex 32`, avoids this restriction. It concerns the bootstrap root password, not the application password.

## Startup and login

```bash
docker compose up -d
docker compose ps
docker compose logs --tail 100 mysql
```

Host ports are bound to `127.0.0.1`: database `${DB_PORT:-3306}`, Adminer `8080`. `bind_address=0.0.0.0` applies to interfaces **inside the container** and is needed for connections from other containers.

`MYSQL_USER` and `MYSQL_PASSWORD` create an application account for `MYSQL_DATABASE` on first startup. `MYSQL_ROOT_PASSWORD` belongs to the administration account. Scripts in `initdb/` run only with an empty data volume; editing `.env` does not change existing database passwords.

For an administrative check over the local socket:

```bash
docker compose exec mysql mysql -uroot -p
```

Adminer is available at `http://127.0.0.1:8080`, with `mysql` prefilled as the server. Log in with the application account. The included `adminer-tls.php` plugin enables TLS with CA and server name verification for the database connection. The local Adminer web UI itself uses HTTP.

## Verify the configuration

The tables below contain recommendations; `my.cnf` contains the actual settings. Check, among others, `SHOW VARIABLES LIKE 'require_secure_transport';`, `SHOW VARIABLES LIKE 'ssl_ca';`, and `SHOW GRANTS;`. `initdb/check_config.sql` contains further read-only checks and can be run from an administrative session.

Use a client with the generated CA files and certificate name verification for the TLS test. A socket login or successful healthcheck does not prove that a TCP connection is encrypted.

For a TCP test from the host, install the MySQL client and run from the Compose directory. Adapt the port and account to `.env`; the certificate SAN must include `localhost`:

```bash
mysql --protocol=TCP --host=localhost --port=3306 --user=appuser --password --ssl-mode=VERIFY_IDENTITY --ssl-ca=ssl/ca-cert.pem
```

In that connection, check `SHOW SESSION STATUS LIKE 'Ssl_cipher';`.

## Parameter reference

### Security & network

| Option              | Meaning                        | Recommendation |
|---------------------|--------------------------------|----------------|
| `bind_address`      | Bind IP                        | `127.0.0.1` or VPN IP; (`0.0.0.0` inside the container; host port bound to `127.0.0.1`) |
| `skip_networking`   | Disable TCP/IP                 | `0`; only `1` if socket-only |
| `skip_name_resolve` | Avoid DNS lookups              | `1`; use IPs in `CREATE USER` |
| `max_connections`   | Max connections                | 100–500 as needed |
| `local_infile`      | `LOAD DATA LOCAL INFILE`       | `0` (disable) |
| `secure_file_priv`  | Folder for import/export       | Set dedicated path or `NULL` (block) |

### TLS/SSL

| Option                      | Meaning                    | Recommendation |
|-----------------------------|----------------------------|----------------|
| `ssl-ca` / `ssl-cert` / `ssl-key` | CA/server certificates | Set paths, permissions `600`, owner `mysql:mysql` |
| `require_secure_transport`  | TLS/socket-only connections | `ON` after TLS setup |

### Storage & performance

| Option                       | Meaning                     | Recommendation |
|------------------------------|-----------------------------|----------------|
| `innodb_buffer_pool_size`    | InnoDB main cache           | Tune for available RAM and workload |
| `innodb_redo_log_capacity`   | Total redo log size (new)   | 1–4 GB depending on write load |
| `innodb_file_per_table`      | Separate tablespace         | `1` |
| `innodb_flush_log_at_trx_commit` | Durability vs. performance | `1` (ACID), `2` if needed |
| `innodb_flush_method`        | I/O strategy                | `O_DIRECT` optional |

### Character sets

| Option                  | Meaning            | Recommendation |
|-------------------------|--------------------|----------------|
| `character_set_server`  | Default charset    | `utf8mb4` |
| `collation_server`      | Sort order         | `utf8mb4_0900_ai_ci` |

### Logging

| Option                       | Meaning                       | Recommendation |
|------------------------------|-------------------------------|----------------|
| `log_error`                  | Error log                     | File or container logs |
| `slow_query_log`             | Slow queries                  | `1` |
| `slow_query_log_file`        | Slow query log path           | e.g. `/var/log/mysql/mysql-slow.log` |
| `long_query_time`            | Slow threshold                | 1–2 s |
| `log_queries_not_using_indexes` | Log queries without indexes | Enable with care |
| `general_log`                | All statements (debug)        | `0` in prod |
| `general_log_file`           | Path for general query log    | e.g. `/var/log/mysql/mysql-general.log` |

### binary log

| Option                    | Meaning               | Recommendation |
|---------------------------|-----------------------|----------------|
| `log-bin` / `log_bin`     | Enable binary log     | Set path, plan rotation |
| `log-bin-index` / `log_bin_index` | Index file    | Set path |
| `sync_binlog`             | Binlog safety         | `1` |
| `binlog_expire_logs_seconds` | Retention           | 7–14 days (604800–1209600) |

### mysqldump

| Option            | Meaning                  | Recommendation |
|-------------------|--------------------------|----------------|
| `quick`           | Stream row by row        | Enable |
| `quote-names`     | Backtick object names    | Enable |
| `max_allowed_packet` | Max packet size       | `64M` or higher for large dumps |
| *(CLI)*           | Consistent dump          | `--single-transaction` (CLI, not `my.cnf`) |

When rotating certificates, replace the source files in `ssl/` and run `docker compose restart mysql` to recreate the protected runtime copies. Then verify the TLS connection again.

## Files and operations

| File or mount | Purpose |
|---------------|---------|
| `../my.cnf:/etc/mysql/conf.d/my.cnf:ro` | Server configuration |
| `./initdb:/docker-entrypoint-initdb.d:ro` | First-start initialization |
| `mysql_data:/var/lib/mysql` | Persistent data |
| `./ssl:/run/tls-source:ro` | Certificate source; private runtime copy under `/etc/mysql/ssl` |
| `mysql_logs:/var/log/mysql` | Persistent database logs |

The database writes error, slow-query, and binary logs to `/var/log/mysql`. `docker compose logs` shows container output; review the log files separately.

```bash
docker compose stop
docker compose start
docker compose down
```

`down` removes containers and the network while retaining the data volume. Plan and protect backups separately and verify them through restore tests. Initialization scripts and binary logs are not a complete backup process. When running multiple setups, adjust fixed container names and overlapping default host ports.

## References

- [MySQL Docker image](https://hub.docker.com/_/mysql)
- [Adminer extensions](https://www.adminer.org/en/plugins/)
- [Shared TLS guide](../../../../docs/TLS.md)
