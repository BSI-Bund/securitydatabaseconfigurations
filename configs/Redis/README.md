# Redis Enterprise – Configurations

[Deutsch](README-de.md)

## Version and operating models

Template baseline: **8.0.x (example: 8.0.10)**, directory [`Version_8.0.x_Enterprise`](Version_8.0.x_Enterprise/).

- [Native Linux, three-node cluster](Version_8.0.x_Enterprise/Linux/README.md)

This guide covers Redis Enterprise and its administration tools. It does not include a Docker Compose setup or a Redis Open Source configuration.

## Version applicability and verification

The guide in `Version_8.0.x_Enterprise` uses 8.0.10 as its documented example baseline. Other 8.0.x builds require review for changed settings and management procedures.

| Platform / variant | Applicable versions | Verification as of 2026-11-16 |
|---|---|---|
| Native Linux, three nodes | Redis Enterprise 8.0.10 | Documentation reviewed statically; no native cluster runtime test or build-specific approval. |

New version mappings and differing templates follow the [shared version policy](../README.md#versions-and-configuration-folders).

## BSI alignment

**Redis Enterprise** follows the [shared BSI alignment for all database templates](../README.md#bsi-alignment). The [central implementation overview](../README.md#implementation-by-database) and the guides above describe existing measures and remaining tasks. Database-specific notes supplement the shared checklist.

© 2026 – Secure database configurations
