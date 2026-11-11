# Weaviate – Configurations

[Deutsch](README-de.md)

## Version and operating models

Configuration version: **1.34.0**, directory [`Version_1.34`](Version_1.34/).

- [Docker Compose, local HTTP API](Version_1.34/README.md)
- [Docker Compose with Traefik and TLS](Version_1.34/reverse-proxy-traefik/README.md)

The two variants are independent setups with separate data volumes. Adjust their overlapping default host ports before running both at the same time.

## BSI alignment

**Weaviate** follows the [shared BSI alignment for all database templates](../README.md#bsi-alignment). The [central implementation overview](../README.md#implementation-by-database) and the guides above describe existing measures and remaining tasks. Database-specific notes supplement the shared checklist.

© 2026 – Secure database configurations
