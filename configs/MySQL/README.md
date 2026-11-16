# MySQL Community Server – Configurations

[Deutsch](README-de.md)

## Version and operating models

Template baseline: **8.4.6**, directory [`Version_8.4.6`](Version_8.4.6/).

- [Linux with Docker Compose](Version_8.4.6/Linux/README.md)
- [Native Windows](Version_8.4.6/Windows/README.md)

## Version applicability and verification

The template baseline is 8.4.6. The mapping below applies to this directory; it does not approve other MySQL 8.4 patches or new major versions.

| Platform / variant | Applicable versions | Verification as of 2026-11-16 |
|---|---|---|
| Linux with Compose | 8.4.6 and 8.4.13 | Both versions runtime-tested with the unchanged template; image default `mysql:8.4.13`, selectable through `MYSQL_VERSION`. |
| Native Windows | 8.4.6 | Configuration reviewed statically; no native runtime test. |

New version mappings and differing templates follow the [shared version policy](../README.md#versions-and-configuration-folders).

## BSI alignment

**MySQL** follows the [shared BSI alignment for all database templates](../README.md#bsi-alignment). The [central implementation overview](../README.md#implementation-by-database) and the guides above describe existing measures and remaining tasks. Database-specific notes supplement the shared checklist.

© 2026 – Secure database configurations
