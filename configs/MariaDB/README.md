# MariaDB – Configurations

[Deutsch](README-de.md)

## Version and operating models

Template baseline: **11.8**, directory [`Version_11`](Version_11/).

- [Linux with Docker Compose](Version_11/Linux/README.md)
- [Native Windows](Version_11/Windows/README.md)

## Version applicability and verification

Directory `Version_11` currently contains the template for the 11.8 series. This does not approve every MariaDB 11 version.

| Platform / variant | Applicable versions | Verification as of 2026-11-16 |
|---|---|---|
| Linux with Compose | 11.8.3 | Image default `mariadb:11.8.3`; runtime-tested. |
| Native Windows | 11.8 | Configuration reviewed statically; no native runtime test. |

New version mappings and differing templates follow the [shared version policy](../README.md#versions-and-configuration-folders).

## BSI alignment

**MariaDB** follows the [shared BSI alignment for all database templates](../README.md#bsi-alignment). The [central implementation overview](../README.md#implementation-by-database) and the guides above describe existing measures and remaining tasks. Database-specific notes supplement the shared checklist.

© 2026 – Secure database configurations
