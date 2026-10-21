# TLS Certificate Directory

Generated TLS files belong here:

- `ca.crt`
- `server.crt`
- `server.key`

Do not commit private keys or generated certificates. Use `../scripts/generate-local-tls.sh` for local testing, then replace the files with certificates from your own CA for production-style deployments.
