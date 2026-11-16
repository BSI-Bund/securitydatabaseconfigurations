# PostgreSQL – Configurations

[Deutsch](README-de.md)

## Version and operating models

Template baseline: **18.6**, directory [`Version_18.6`](Version_18.6/).

- [Linux with Docker Compose](Version_18.6/Linux/README.md)
- [Native Windows](Version_18.6/Windows/README.md)

## Version applicability and verification

The template baseline is 18.6. The mapping below applies to this directory; it does not automatically approve further PostgreSQL 18 patches or new major versions.

| Platform / variant | Applicable versions | Verification as of 2026-11-16 |
|---|---|---|
| Linux with Compose | 18.6 and 18.7 | Base/TLS variants, Adminer, roles, and backup/restore runtime-tested with both versions; image default `postgres:18.7`. |
| Native Windows | 18.6 | Configuration reviewed statically; no native runtime test. |

New version mappings and differing templates follow the [shared version policy](../README.md#versions-and-configuration-folders).

## BSI alignment

**PostgreSQL** follows the [shared BSI alignment for all database templates](../README.md#bsi-alignment). The [central implementation overview](../README.md#implementation-by-database) and the guides above describe existing measures and remaining tasks. Database-specific notes supplement the shared checklist.

© 2026 – Secure database configurations
