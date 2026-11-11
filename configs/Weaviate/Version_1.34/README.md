# Weaviate 1.34.0 – Docker Compose

[Deutsch](README-de.md) · [Database overview](../README.md) · [BSI alignment](../../README.md#bsi-alignment)

This variant runs a single Weaviate instance with a local HTTP API. The [Traefik variant](reverse-proxy-traefik/README.md) is an independent setup with a separate data volume. Their default host ports overlap; do not run both unchanged at the same time.

- [Preparation](#preparation)
- [Startup and effective settings](#startup-and-effective-settings)
- [Verify the connection](#verify-the-connection)
- [Parameter reference](#parameter-reference)
- [Data and operations](#data-and-operations)
- [References](#references)

## Preparation

Install Docker with Compose. Run every command from this README directory.

```bash
cp .env.example .env
```

Replace the example API keys in `.env`. `WEAVIATE_API_KEYS` and `WEAVIATE_API_USERS` are associated by their order. Only identities listed in `WEAVIATE_ROOT_USERS` automatically have root permissions; assign appropriate RBAC roles to other users.

The base `.env.example` already enables `text2vec-ollama` and `generative-ollama`, but this setup has no Ollama service. For a simple REST test without model integration, set in `.env`:

```dotenv
ENABLE_API_BASED_MODULES=false
ENABLE_MODULES=
```

For model integration, configure reachable endpoints and models per collection instead. The [Traefik guide](reverse-proxy-traefik/README.md) describes a variant with an optional Ollama service.

## Startup and effective settings

```bash
docker compose config --quiet
docker compose pull
docker compose up -d
docker compose ps
```

The [Compose file](docker-compose.yml) uses `cr.weaviate.io/semitechnologies/weaviate:${WEAVIATE_VERSION}` and binds the HTTP API exclusively to `127.0.0.1:${WEAVIATE_PORT}`. With template values, this is `http://127.0.0.1:8080`. gRPC port `50051` is not published in this variant.

The template enables API key authentication and RBAC and disables anonymous API access. These container settings are **already configured**: `no-new-privileges`, `cap_drop: [ALL]`, a read-only root filesystem, writable data volume, temporary `/tmp`, memory limit `4g`, and CPU limit `2.0`. Adapt resources and required writable paths to the workload.

This base variant uses HTTP. Access across untrusted networks requires appropriate TLS integration; see [Traefik](reverse-proxy-traefik/README.md). The configured hardening options do not replace a review of the full operating environment.

## Verify the connection

Compose reads `.env` for configuration; it does not automatically export those variables into the invoking shell. The commands below therefore use the concrete default port. Adjust it if `WEAVIATE_PORT` was changed.

```bash
curl --fail-with-body http://127.0.0.1:8080/v1/.well-known/ready
export WEAVIATE_API_KEY='REPLACE_WITH_KEY_FROM_ENV'
curl --fail-with-body http://127.0.0.1:8080/v1/meta -H "Authorization: Bearer ${WEAVIATE_API_KEY}"
```

Replace the placeholder with a configured API key. The readiness endpoint checks service readiness; it does not prove authentication works. Also test an authenticated API request. For `401` or `403`, check the API key, user mapping, and RBAC permissions.

## Parameter reference

| Variable                           | Purpose                                          | Recommendation |
|------------------------------------|--------------------------------------------------|----------------|
| `WEAVIATE_VERSION`                 | Pin Weaviate version (avoid `latest`)            | `1.34.0` |
| `WEAVIATE_HOST`                    | Bind address inside container                    | `0.0.0.0` |
| `WEAVIATE_PORT`                    | API port                                         | `8080` |
| `WEAVIATE_SCHEME`                  | Internal protocol                                | `http` |
| `TZ`                               | Timezone                                         | `Europe/Berlin` |
| `WEAVIATE_DATA_PATH`               | Persistence path in container                    | `/var/lib/weaviate` |
| `WEAVIATE_QUERY_LIMIT`             | Default query limit                              | `100` |
| `WEAVIATE_CLUSTER_HOSTNAME`        | Node name (Raft/cluster)                         | `node1` |
| `DISABLE_TELEMETRY`                | Opt out of anonymous usage metrics               | `true` |
| `QUERY_SLOW_LOG_ENABLED`           | Enable slow query logging                        | `true` |

**Auth & RBAC**

| Variable                                    | Purpose                                 | Recommendation |
|---------------------------------------------|-----------------------------------------|----------------|
| `AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED`   | Disable anonymous access                | `"false"` |
| `AUTHENTICATION_APIKEY_ENABLED`             | Enable API key auth                     | `"true"` |
| `WEAVIATE_API_KEYS`                         | API keys (comma separated)              | `keyA,keyB` |
| `WEAVIATE_API_USERS`                        | Users mapped to keys (same order)       | `userA,userB` |
| `AUTHORIZATION_ENABLE_RBAC`                 | Enable RBAC                             | `"true"` |
| `WEAVIATE_ROOT_USERS`                       | Root users (admin)                      | `userA` |

**Modules (optional)**

| Variable                    | Purpose                               | Recommendation |
|-----------------------------|---------------------------------------|----------------|
| `ENABLE_API_BASED_MODULES`  | Allow API-based modules               | `"true"` |
| `ENABLE_MODULES`            | Modules to enable                     | `text2vec-ollama,generative-ollama` |

> ℹ️ **Module note:** Model and endpoint (e.g., Ollama `http://ollama:11434`) are set **per collection in the client**, not via `.env`.

## Data and operations

`weaviate_data` is mounted at `${WEAVIATE_DATA_PATH}`, defaulting to `/var/lib/weaviate`. The volume is persistent but is not a backup. Configure a consistent backup procedure and restore tests for your environment.

```bash
docker compose logs --tail 100 weaviate
docker compose stop
docker compose start
docker compose down
```

`down` retains the data volume. Apply `.env` changes with `docker compose up -d`, then inspect the effective settings.

## References

- [Weaviate: authentication and Bearer headers](https://docs.weaviate.io/deploy/configuration/authentication)
- [Shared TLS guide](../../../docs/TLS.md)
