# MongoDB – Configurations

[Deutsch](README-de.md)

## Version and operating models

Documented targets: **Linux 8.3.11 / Windows 8.0**, directory [`Version_8`](Version_8/).

- [Linux with Docker Compose](Version_8/Linux/README.md)
- [Native Windows](Version_8/Windows/README.md)

The Compose example uses version tag `mongo:8.3.11-noble`.

## Version applicability and verification

Directory `Version_8` contains separate Linux and Windows target versions. The directory name does not approve every MongoDB 8.x release.

| Platform / variant | Applicable versions | Verification as of 2026-11-16 |
|---|---|---|
| Linux with Compose | 8.3.11 | Image default `mongo:8.3.11-noble`; runtime-tested. |
| Native Windows | 8.0 | Configuration and bootstrap guards checked; no native Windows runtime test. |

New version mappings and differing templates follow the [shared version policy](../README.md#versions-and-configuration-folders).

## BSI alignment

**MongoDB** follows the [shared BSI alignment for all database templates](../README.md#bsi-alignment). The [central implementation overview](../README.md#implementation-by-database) and the guides above describe existing measures and remaining tasks. Database-specific notes supplement the shared checklist.

© 2026 – Secure database configurations
