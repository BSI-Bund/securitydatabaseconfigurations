# TLS certificate directory

[Deutsch](README-de.md) · [Linux guide](../../README.md)

The TLS override expects `ca.crt`, `server.crt`, and `server.key` here. From the `postgres-compose/` directory, run `./scripts/generate-local-tls.sh` for a local test.

Do not commit generated files or private keys. Use certificates from your own CA for other environments and restrict access to `server.key`. Certificate generation alone does not activate the TLS Compose override.
