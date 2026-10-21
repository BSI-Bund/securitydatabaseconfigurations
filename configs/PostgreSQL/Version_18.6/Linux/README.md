# <img src="https://www.vectorlogo.zone/logos/postgresql/postgresql-icon.svg" alt="PostgreSQL Logo" width="26"/> PostgreSQL - Linux (Docker Compose)

- [Security status](#security-status)
- [Getting started](#getting-started)
- [TLS mode](#tls-mode)
- [Services](#services)
- [Adminer login](#adminer-login)
- [Environment variables](#environment-variables)
- [Parameter reference](#parameter-reference)
- [Backup and restore](#backup-and-restore)
- [BSI alignment](#bsi-alignment)
- [Volumes and ports](#volumes-and-ports)
- [Operations](#operations)
- [References](#references)

---

## Security status

This is a secure baseline, not a production guarantee. It gives you:

- localhost-only host port publishing in Docker Compose
- SCRAM-SHA-256 password authentication
- separate application roles in the init script
- explicit `pg_hba.conf` rules
- conservative durability settings
- connection, disconnection, DDL, slow-query, and lock-wait logging
- an optional TLS Compose override

The official PostgreSQL 18 image stores data in a major-version-specific path; this Compose setup mounts `/var/lib/postgresql` and sets `PGDATA=/var/lib/postgresql/18/docker` to match that behavior.

`POSTGRES_USER` is the bootstrap superuser of the official PostgreSQL image and is not intended for normal application access. Use `app_admin` and `app_reader` for Adminer and application testing.

Before production use, replace all example passwords, narrow network ranges, provide CA-issued certificates, define backup/WAL archiving, test restore, and review the full operating environment. No sample config can cover every security requirement of every deployment; secret management, encryption at rest, OS hardening, firewall rules, patch management, and application-layer controls still belong to the deployment.

---

## Getting started

This setup provides a PostgreSQL 18.6 instance and an Adminer web UI for local administration.
It is based on official images:

- [PostgreSQL on Docker Hub](https://hub.docker.com/_/postgres)
- [Adminer on Docker Hub](https://hub.docker.com/_/adminer)

```bash
cd postgres-compose
cp .env.example .env
docker compose up -d
```

The default setup is intentionally runnable without certificates. PostgreSQL is exposed only on `127.0.0.1:${DB_PORT:-5432}` at the host level.

---

## TLS mode

PostgreSQL can accept TLS and non-TLS connections on the same port. To require TLS for TCP clients, enable TLS in `postgresql.conf` and use `hostssl` rules in `pg_hba.conf`.

For local testing:

```bash
cd postgres-compose
./scripts/up-local-tls.sh
```

This script generates local certificates when they are missing, starts the TLS Compose variant, waits for PostgreSQL to become healthy, verifies a TLS connection, and verifies that non-TLS TCP access is rejected.

Adminer can still be used in TLS mode. The server stays `postgres`; use `app_admin` or `app_reader` for login. PostgreSQL then accepts TCP connections only when encrypted. The Adminer web UI itself remains available locally over HTTP on `127.0.0.1:8080`.

Manual TLS flow:

```bash
cd postgres-compose
./scripts/generate-local-tls.sh
docker compose -f docker-compose.yml -f docker-compose.tls.yml up -d
```

The TLS override uses:

- `../postgresql-tls.conf`
- `../pg_hba-tls.conf`
- `./ssl/server.crt`
- `./ssl/server.key`
- `./ssl/ca.crt`

Client example with certificate verification:

```bash
PGPASSWORD='S3cur3P@ss!' psql "host=localhost port=5432 dbname=appdb user=app_admin sslmode=verify-full sslrootcert=ssl/ca.crt"
```

For production-style deployments, replace the generated local CA and server certificate with certificates from your own CA. Keep `server.key` restricted to the PostgreSQL service user.

---

## Services

### postgres

- Image `postgres:18.6`
- Starts with custom `postgresql.conf` and `pg_hba.conf`
- Initializes with scripts in `./initdb/`
- Stores data in the `postgres_data` volume
- Uses `pg_isready` for health checks

### adminer

- Web UI for local administration
- Runs on `127.0.0.1:8080`
- Points to the `postgres` service
- Login with `app_admin` or `app_reader`; use `postgres` only for bootstrap/maintenance
- Not a production hardening control

---

## Adminer login

Recommended login values for the local example:

| Field | Write access | Read only |
|-------|--------------|-----------|
| System | `PostgreSQL` | `PostgreSQL` |
| Server | `postgres` | `postgres` |
| User | `app_admin` | `app_reader` |
| Password | `S3cur3P@ss!` | `Read0nly!` |
| Database | `appdb` | `appdb` |

The `postgres` user is a superuser. It is needed for container initialization, backup/restore, and administrative checks, but should not be used for normal application or Adminer access.

Note: When Adminer shows `postgres` in the header, this is the Compose service/server name. The logged-in database user is shown separately in the URL and login form.

---

## Environment variables

Example values live in `postgres-compose/.env.example`. Change all secrets before use:

```bash
POSTGRES_VERSION=18.6
TZ=Europe/Berlin
DB_PORT=5432
ADMINER_PORT=8080
POSTGRES_USER=postgres
POSTGRES_PASSWORD=ChangeMe!Root123
POSTGRES_DB=appdb
POSTGRES_APP_ADMIN_PASSWORD=S3cur3P@ss!
POSTGRES_APP_READER_PASSWORD=Read0nly!
PGDATA=/var/lib/postgresql/18/docker
```

---

## Parameter reference

### Network and authentication

| Option | Meaning | Recommendation |
|--------|---------|----------------|
| `listen_addresses` | Interfaces PostgreSQL listens on | `*` in Docker plus localhost-only host port binding |
| `port` | PostgreSQL port | `5432` unless the environment requires another port |
| `max_connections` | Concurrent connections | Start with 100; add pooling for larger workloads |
| `password_encryption` | Password hash format | `scram-sha-256` |
| `pg_hba.conf` | Client authentication policy | Restrict to explicit networks; use `scram-sha-256` |
| `pg_hba-tls.conf` | TLS-only client authentication policy | Use `hostssl`; reject accidental `hostnossl` access |

### TLS

| Option | Meaning | Recommendation |
|--------|---------|----------------|
| `ssl` | Enables TLS | `on` in TLS mode |
| `ssl_cert_file` | Server certificate | `/etc/postgresql/ssl/server.crt` |
| `ssl_key_file` | Server private key | `/etc/postgresql/ssl/server.key`, restricted permissions |
| `ssl_ca_file` | CA certificate | `/etc/postgresql/ssl/ca.crt` |
| `ssl_min_protocol_version` | Minimum TLS version | `TLSv1.2` or stricter if clients support it |

Certificate generation is also described in the repository [README](../../../../README.md#-tls-configuration).

### Storage and durability

| Option | Meaning | Recommendation |
|--------|---------|----------------|
| `data_directory` | Database files | `/var/lib/postgresql/18/docker` for the PostgreSQL 18 Docker image |
| `shared_buffers` | PostgreSQL buffer cache | Start with 25% of RAM on dedicated servers |
| `effective_cache_size` | Planner cache estimate | Around 50-75% of available memory |
| `work_mem` | Per-sort/hash memory | Tune carefully; multiplied per operation |
| `fsync` | Flush WAL/data safely | `on` |
| `synchronous_commit` | Commit durability | `on` for safe defaults |
| `full_page_writes` | Crash safety | `on` |
| `wal_level` | WAL detail | `replica` for backup/replication readiness |

### Logging and diagnostics

| Option | Meaning | Recommendation |
|--------|---------|----------------|
| `log_destination` | Log target | `stderr` in containers |
| `logging_collector` | File log collector | `off` in containers; use Docker logs |
| `log_connections` / `log_disconnections` | Session audit trail | `all` / `on` |
| `log_checkpoints` | Checkpoint diagnostics | `on` |
| `log_autovacuum_min_duration` | Autovacuum diagnostics | `10min` baseline |
| `log_min_error_statement` | Statements that cause errors | `error` baseline; review for sensitive query data |
| `log_min_duration_statement` | Slow query threshold | `1000` ms to start |
| `log_statement` | Statement logging | `ddl` for schema changes |
| `log_lock_waits` | Lock wait diagnostics | `on` |

### Runtime limits

| Option | Meaning | Recommendation |
|--------|---------|----------------|
| `idle_in_transaction_session_timeout` | Ends idle open transactions | `10min` baseline |
| `statement_timeout` | Query runtime limit | Set per app/workload |
| `lock_timeout` | Lock wait limit | Set per app/workload |

---

## Backup and restore

The Compose example includes logical backup helpers:

```bash
cd postgres-compose
./scripts/backup.sh
CONFIRM_RESTORE=appdb ./scripts/restore.sh backups/appdb-YYYYMMDDTHHMMSSZ.dump
```

`backup.sh` creates:

- a custom-format `pg_dump` of the configured application database
- a `pg_dumpall --globals-only` file for roles and global objects
- a SHA-256 checksum file

This supports a basic backup workflow, but it is not a full recovery concept. Define backup frequency, retention, encryption, off-host storage, restore tests, and RPO/RTO. For point-in-time recovery, add WAL archiving.

---

## BSI alignment

This baseline is aligned with the BSI key points for database systems, the BSI practical guide for secure database systems, and APP.4.3. It covers baseline hardening, regulated setup, encrypted database connections, monitoring/logging, and backup/restore preparation.

For production-like use, compare the configuration with protection needs, network exposure, secret management, backup/restore, and existing operations processes.

See [BSI alignment notes](../BSI-Alignment.md) for the checklist.

---

## Volumes and ports

| Mount / port | Description |
|--------------|-------------|
| `postgres_data:/var/lib/postgresql` | Persistent data parent directory for PostgreSQL 18 images |
| `./initdb:/docker-entrypoint-initdb.d:ro` | Initial SQL scripts, first start only |
| `../postgresql.conf:/etc/postgresql/postgresql.conf:ro` | Base server configuration |
| `../pg_hba.conf:/etc/postgresql/pg_hba.conf:ro` | Base authentication rules |
| `./ssl:/etc/postgresql/ssl:ro` | TLS certificates, TLS mode only |
| `127.0.0.1:5432` | PostgreSQL access from the host |
| `127.0.0.1:8080` | Adminer access from the host |

---

## Operations

```bash
docker compose up -d
docker compose logs -f
docker compose exec -e PGPASSWORD='S3cur3P@ss!' postgres psql -U app_admin -d appdb
docker compose exec -e PGPASSWORD='ChangeMe!Root123' postgres psql -U postgres -d appdb -f /docker-entrypoint-initdb.d/check_config.sql
docker compose down
```

TLS one-command startup:

```bash
./scripts/up-local-tls.sh
TLS=1 ./scripts/down.sh
```

Optional volume cleanup:

```bash
docker volume rm <project>_postgres_data
```

---

## References

- [PostgreSQL 18 SSL/TLS documentation](https://www.postgresql.org/docs/18/ssl-tcp.html)
- [PostgreSQL `pg_hba.conf` documentation](https://www.postgresql.org/docs/18/auth-pg-hba-conf.html)
- [PostgreSQL password authentication and SCRAM](https://www.postgresql.org/docs/18/auth-password.html)
- [PostgreSQL role attributes](https://www.postgresql.org/docs/18/role-attributes.html)
- [PostgreSQL connection settings](https://www.postgresql.org/docs/18/runtime-config-connection.html)
- [PostgreSQL resource settings](https://www.postgresql.org/docs/18/runtime-config-resource.html)
- [PostgreSQL WAL settings](https://www.postgresql.org/docs/18/runtime-config-wal.html)
- [PostgreSQL logging settings](https://www.postgresql.org/docs/18/runtime-config-logging.html)
- [PostgreSQL client timeout settings](https://www.postgresql.org/docs/18/runtime-config-client.html)
- [Postgres Docker Official Image documentation](https://github.com/docker-library/docs/blob/master/postgres/README.md)

© 2026 - Secure database configurations
