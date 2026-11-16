# Weaviate – Configurations

[Deutsch](README-de.md)

## Version and operating models

Template baseline: **1.34.0**, directory [`Version_1.34`](Version_1.34/).

- [Docker Compose, local HTTP API](Version_1.34/README.md)
- [Docker Compose with Traefik and TLS](Version_1.34/reverse-proxy-traefik/README.md)

The two variants are independent setups with separate data volumes. Adjust their overlapping default host ports before running both at the same time.

## Version applicability and verification

The template in `Version_1.34` is verified for 1.34.0. Further 1.34 patches and other 1.x versions are not automatically included.

| Platform / variant | Applicable versions | Verification as of 2026-11-16 |
|---|---|---|
| Base Compose variant | 1.34.0 | REST access, API-key authentication, and RBAC runtime-tested. |
| Compose with Traefik | 1.34.0 | HTTPS and direct REST/gRPC endpoints, including access controls, runtime-tested; Ollama model inference not tested. |

New version mappings and differing templates follow the [shared version policy](../README.md#versions-and-configuration-folders).

## BSI alignment

**Weaviate** follows the [shared BSI alignment for all database templates](../README.md#bsi-alignment). The [central implementation overview](../README.md#implementation-by-database) and the guides above describe existing measures and remaining tasks. Database-specific notes supplement the shared checklist.

© 2026 – Secure database configurations
