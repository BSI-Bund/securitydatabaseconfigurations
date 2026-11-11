# Secure database configurations

[Deutsch](README-de.md)

This repository contains configuration templates and operating instructions for MariaDB, MongoDB, MySQL, PostgreSQL, Redis Enterprise, and Weaviate. It provides a starting point for hardening your database environments. Each setup guide explains the measures already implemented and the preparation still required.

- [Getting started](#getting-started)
- [BSI alignment](#bsi-alignment)
- [Available databases and operating models](#available-databases-and-operating-models)
- [Documentation structure](#documentation-structure)
- [Security objectives and operational tasks](#security-objectives-and-operational-tasks)
- [TLS and certificates](#tls-and-certificates)

## Getting started

1. Select a DBMS and its guide from the table below.
2. Read the entire platform-specific README. It lists prerequisites, files, working directory, and startup sequence.
3. Adapt the configuration, sample secrets, network exposure, and storage paths to your environment. For Compose setups, copy `.env.example` to `.env` in the directory specified by the guide.
4. Prepare certificates and required directories before startup where the guide requires them.
5. After startup, check the effective configuration, authentication, TLS, and logging; test backup and restore.

The guides are intended for administrators and developers familiar with the respective DBMS. Docker Compose is required only for the container setups explicitly listed below.

## BSI alignment

**BSI alignment applies to every database template in this repository: MariaDB, MongoDB, MySQL, PostgreSQL, Redis Enterprise, and Weaviate.** The [shared configuration overview](configs/README.md#bsi-alignment) contains the BSI references, common checklist, and implementation for each DBMS. Database-specific additions provide details within this shared framework.

## Available databases and operating models

Versions describe the configuration templates, not the latest vendor releases.

| Database | Configuration version | Included operating models | Start here |
|----------|-----------------------|---------------------------|------------|
| MariaDB | 11.8 | Linux with Docker Compose; native Windows installation | [MariaDB](configs/MariaDB/README.md) |
| MongoDB | 8.x | Linux with Docker Compose; native Windows installation | [MongoDB](configs/MongoDB/README.md) |
| MySQL Community Server | 8.4.6 | Linux with Docker Compose; native Windows installation | [MySQL](configs/MySQL/README.md) |
| PostgreSQL | 18.6 | Linux with Docker Compose; native Windows installation | [PostgreSQL](configs/PostgreSQL/README.md) |
| Redis Enterprise | 8.0.x | Native Linux cluster installation | [Redis Enterprise](configs/Redis/README.md) |
| Weaviate | 1.34.0 | Docker Compose; additional standalone variant with Traefik | [Weaviate](configs/Weaviate/README.md) |

## Documentation structure

```text
README.md                     Project overview and entry point
configs/
├── README.md                 Shared BSI alignment and database overview
└── <DBMS>/
    ├── README.md             Versions and links to included setups
    └── Version_*/            DBMS-specific files and instructions
```

MariaDB, MongoDB, MySQL, and PostgreSQL have separate `Linux/` and `Windows/` directories below the version folder. Redis contains a Linux guide for Redis Enterprise. Weaviate keeps its Compose files directly in the version folder, with the Traefik variant in `reverse-proxy-traefik/`.

Each German guide has an English counterpart without `-de` in its filename. Filenames and directory layouts vary by DBMS; the respective README links to the available files.

## Security objectives and operational tasks

Shared objectives include encrypted connections, restricted network access, separate administration and application accounts, least privilege, useful logs, and recoverable backups. The implementation differs between templates.

Replace sample secrets before use. Set up patch management, host and file protection, monitoring, backup retention and encryption, and regular restore tests for your environment. A persistent Docker volume or enabled replication does not replace a backup.

## TLS and certificates

The separate [TLS guide](docs/TLS.md) explains how to create and verify CA, server, and client certificates with OpenSSL. Each DBMS guide explains file formats, paths, integration, and client connections. Creating a certificate alone does not enable TLS.

© 2026 – Secure database configurations
