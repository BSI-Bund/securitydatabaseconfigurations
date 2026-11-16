# TLS certificate directory

[Deutsch](README-de.md) · [Linux guide](../../README.md)

The TLS override expects `ca.crt`, `server.crt`, and `server.key` here. From the `postgres-compose/` directory, run `./scripts/generate-local-tls.sh` for a local test.

The generator keeps the private CA outside the repository under `${XDG_DATA_HOME:-$HOME/.local/share}/db-sec-conf/postgresql-dev-ca` or an explicitly configured `CA_DIR`. That directory must not be inside `ssl/`. The override mounts only the three required files; Adminer receives only the public CA certificate.

Do not commit generated files or private keys. Use certificates from your own CA for other environments and restrict access to `server.key`. Certificate generation alone does not activate the TLS Compose override.
