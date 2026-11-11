# Weaviate 1.34.0 with Traefik and TLS

[Deutsch](README-de.md) · [Base Weaviate variant](../README.md) · [BSI alignment](../../../README.md#bsi-alignment)

This independent Compose setup exposes Weaviate over HTTPS through Traefik v3.5. It uses its own data volume, `weaviate_data_proxy`; data from the base variant is not transferred automatically.

- [Preparation and network exposure](#preparation-and-network-exposure)
- [Certificate and hostnames](#certificate-and-hostnames)
- [Startup and TLS verification](#startup-and-tls-verification)
- [Optional model integration with Ollama](#optional-model-integration-with-ollama)
- [Python examples](#python-examples)
- [Operations and data](#operations-and-data)
- [References](#references)

## Preparation and network exposure

Prerequisites: Docker with Compose, OpenSSL 3 for the certificate example, and free host ports. Every command assumes this README directory and a POSIX shell.

```bash
cp .env.example .env
```

Replace API keys in `.env` and check their mapping to `WEAVIATE_API_USERS`. `WEAVIATE_ROOT_USERS` determines root identities; assign appropriate roles to other users.

The [Compose file](docker-compose.yml) publishes these endpoints:

| Endpoint | Template host binding | Transport |
|----------|-----------------------|-----------|
| Weaviate REST | `127.0.0.1:8080` | HTTP, direct local access |
| Weaviate gRPC | `127.0.0.1:50051` | Unencrypted, published by default |
| Traefik | `127.0.0.1:80` and `127.0.0.1:443` | HTTP redirect to HTTPS; TLS termination |
| Ollama, only with the `ollama` profile | `127.0.0.1:11434` | HTTP |

Traefik port mappings already bind to `127.0.0.1:80:80` and `127.0.0.1:443:443`. **The dashboard and insecure API access are disabled; no dashboard route exists.** For intended remote access, adjust only the required API exposure and firewall rules.

Direct local HTTP/gRPC access remains available. TLS terminates at Traefik; its internal connection to Weaviate uses HTTP. Compose container hardening options apply to Weaviate, not automatically to all services. Routing is defined in `dynamic/tls.yml` through the file provider; Traefik requires neither a Docker socket nor a Docker provider. `WEAVIATE_DOMAIN` and `WEAVIATE_PORT` are passed into the Traefik container for the dynamic template.

## Certificate and hostnames

Domains in `.env`, certificate SANs, and client connections must match. For the unchanged example domains:

```bash
mkdir -p certs
openssl req -x509 -newkey rsa:4096 -noenc -keyout certs/local.key -out certs/local.crt -days 365 -subj "/CN=weaviate.docker.localhost" -addext "basicConstraints=critical,CA:FALSE" -addext "keyUsage=critical,digitalSignature,keyEncipherment" -addext "extendedKeyUsage=serverAuth" -addext "subjectAltName=DNS:weaviate.docker.localhost"
chmod 600 certs/local.key
```

This creates a local self-signed server certificate. Tests explicitly trust `certs/local.crt`; it does not replace certificate management for other environments. [`dynamic/tls.yml`](dynamic/tls.yml) loads `local.crt` and `local.key` and defines the header middleware. It also defines the router and backend service; the domain and backend port are populated from Traefik environment variables when loaded.

The example domains must resolve to the local host. If local DNS does not already provide this, add these entries to `/etc/hosts`, or `C:\Windows\System32\drivers\etc\hosts` on Windows:

```text
127.0.0.1 weaviate.docker.localhost
```

## Startup and TLS verification

```bash
docker compose config --quiet
docker compose pull
docker compose up -d
docker compose ps
```

The proxy variant's `.env.example` disables embedding modules. Ollama is not needed for these REST checks. Replace the API key placeholder with the value configured in `.env`:

```bash
export WEAVIATE_API_KEY='REPLACE_WITH_KEY_FROM_ENV'
curl --fail-with-body --cacert certs/local.crt https://weaviate.docker.localhost/v1/.well-known/ready
curl --fail-with-body --cacert certs/local.crt https://weaviate.docker.localhost/v1/meta -H "Authorization: Bearer ${WEAVIATE_API_KEY}"
curl --fail-with-body --cacert certs/local.crt https://weaviate.docker.localhost/v1/schema -H "Authorization: Bearer ${WEAVIATE_API_KEY}"
```

These commands verify the server certificate; `-k` is not needed. Readiness only confirms service readiness. Also verify the authenticated request succeeds. Compose healthchecks inspect the local HTTP endpoint; they do not establish that TLS or API key checks work.

## Optional model integration with Ollama

The `ollama` service is already defined with a Compose profile. Set in `.env`:

```dotenv
ENABLE_API_BASED_MODULES=true
ENABLE_MODULES=text2vec-ollama,generative-ollama
```

Then start the service and download models:

```bash
docker compose --profile ollama up -d
docker compose exec ollama ollama pull nomic-embed-text
docker compose exec ollama ollama pull llama3.2
```

The endpoint **from Weaviate** is `http://ollama:11434`. The endpoint **for the client on the host** is `http://127.0.0.1:11434`. Models and endpoints are configured per collection. This template references the Ollama image as `latest`; select a suitable version before relying on reproducible deployments.

## Python examples

- [REST example](example-clients-python/weaviate-rest-minimal.py): creates `Question`, downloads example data from the internet, and writes objects.
- [Ollama example](example-clients-python/weaviate-ollama-client.py): checks models, creates or uses `QuestionOllama`, inserts an object, and performs a generative search.

Both supplied scripts connect directly to the local HTTP endpoint; the Ollama example also uses local gRPC. They do not test the Traefik TLS endpoint. Adapt `API_KEY` in each script before running. The examples modify data and may add more objects on repeated runs.

From a Python environment in this README directory, after completing the prerequisites for the respective example:

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install requests 'weaviate-client>=4,<5'
python example-clients-python/weaviate-rest-minimal.py
python example-clients-python/weaviate-ollama-client.py
```

The Ollama example requires enabled modules and downloaded models. Use a Python client version compatible with the server; the installation above only limits the major version to 4.

## Operations and data

```bash
docker compose logs --tail 100 weaviate-db-proxy traefik
docker compose stop
docker compose start
docker compose down
```

`down` retains the data volumes. Set up backups, retention, and restore tests separately. Base and proxy variants use different Weaviate volumes and conflict on default local ports unless adjusted.

## References

- [Weaviate authentication](https://docs.weaviate.io/deploy/configuration/authentication)
- [Traefik: dashboard and access protection](https://doc.traefik.io/traefik/v3.5/operations/dashboard/)
- [Traefik: file provider](https://doc.traefik.io/traefik/reference/install-configuration/providers/others/file/)
- [Shared TLS guide](../../../../docs/TLS.md)
