# Database configurations – Shared BSI alignment

[Deutsch](README-de.md)

This README defines the shared BSI alignment for **every database template** under `configs/`: **MariaDB, MongoDB, MySQL, PostgreSQL, Redis Enterprise, and Weaviate**. It applies across DBMSs to the documented container and native installations. Database-specific implementation details and additional requirements supplement this shared framework.

- [BSI alignment](#bsi-alignment)
  - [References](#references)
  - [Shared checklist](#shared-checklist)
  - [Scope and use](#scope-and-use)
  - [Implementation by database](#implementation-by-database)
- [Database folders](#database-folders)

## BSI alignment

The BSI key points for database systems and the BSI practical guide for secure database systems provide the common orientation for these configuration templates. The checklist below summarizes selected shared security objectives; the available settings, scripts, and operational measures must be reviewed for each DBMS and deployment.

IT-Grundschutz module APP.4.3 addresses **relational database systems**. Its applicability to other database types must be assessed for the target environment; it is not assumed for every DBMS in this repository.

### References

- [BSI key points for selecting and using database systems](https://www.bsi.bund.de/SharedDocs/Downloads/DE/BSI/Datenbanksysteme/datenbanksystem_eckpunkte_papier.pdf?__blob=publicationFile&v=2)
- [BSI appendix to the database system key points](https://www.bsi.bund.de/SharedDocs/Downloads/DE/BSI/Datenbanksysteme/datenbanksystem_eckpunkte_anlagen.pdf?__blob=publicationFile&v=2)
- [BSI practical guide for secure database systems](https://www.bsi.bund.de/SharedDocs/Downloads/DE/BSI/Datenbanksysteme/praxisleitfaden_sichere_datenbanksysteme.pdf)
- [BSI IT-Grundschutz APP.4.3 Relationale Datenbanken (Edition 2023)](https://www.bsi.bund.de/SharedDocs/Downloads/DE/BSI/Grundschutz/IT-GS-Kompendium_Einzel_PDFs_2023/06_APP_Anwendungen/APP_4_3_Relationale_Datenbanksysteme_Edition_2023.pdf?__blob=publicationFile&v=3)

### Shared checklist

| Topic | Shared security objective | Review for each DBMS and deployment |
|-------|---------------------------|-------------------------------------|
| Planning and standardization | Use documented, versioned, and reproducible configurations | Select the version and operating model; document protection needs, responsibilities, and deviations |
| Secure initial setup | Configure the service deliberately and protect initial access | Replace sample secrets, adapt initialization scripts, and restrict permissions on data, logs, and secrets |
| Access control and authentication | Use strong authentication and least-privilege roles | Define application and administrator accounts, trusted networks, and DBMS-specific authentication rules |
| Transport protection | Encrypt database connections and verify certificate identities | Enable the DBMS-specific TLS configuration; adapt CA, certificates, clients, and network exposure |
| Logging and monitoring | Record security-relevant events and review them during operations | Set log scope, access permissions, forwarding, retention, and monitoring responsibilities |
| Backup and restore | Create regular, protected backups and verify restorability | Define scheduling, encryption, off-host storage, retention, restore tests, and recovery objectives |
| Updates and maintenance | Keep the database and its operating environment maintained | Track DBMS, image, host, and platform updates; plan and test upgrades |

### Scope and use

The checklist is a thematic summary, not a complete mapping to individual BSI requirement identifiers. It is a shared review framework, not a statement that every template implements every measure. The database documentation describes the implementation and remaining operational tasks. Review the configuration against the protection needs and processes of the target environment before use.

### Implementation by database

The shared checklist applies to each database below. This table maps existing measures and remaining tasks to the respective templates; the linked guides describe their implementation.

| Database | Existing measures | Remaining tasks |
|----------|-------------------|-----------------|
| [MariaDB](MariaDB/README.md) | Compose with local host-port binding, user initialization, and server TLS configuration; native Windows template | Provide certificates; enable TLS on Windows; define account privileges, backup, and restore |
| [MongoDB](MongoDB/README.md) | Required TLS and authorization in Linux/Windows configurations; administration-account bootstrap procedures | Provide server and client certificates; configure restricted application accounts and backups |
| [MySQL](MySQL/README.md) | Compose with local host-port binding, application user, and server TLS configuration; native Windows template | Provide certificates; configure TLS and application accounts on Windows; define backup and restore |
| [PostgreSQL](PostgreSQL/README.md) | Local default access, SCRAM-SHA-256, application roles, logging, optional TLS configuration, and logical backup helpers for Linux | Enable TLS before non-local access; add backup scheduling, encryption, retention, and restore tests; configure a Windows backup process |
| [Redis Enterprise](Redis/README.md) | Native cluster guide covering TLS, ACL/RBAC, network access, logging, persistence, backups, and replication | Enable and check measures through administration tools; test actual port exposure, certificates, replication, and restore |
| [Weaviate](Weaviate/README.md) | API key authentication, RBAC, local direct access, and container hardening; separate Traefik TLS variant with disabled dashboard and local port binding | Replace example keys, assign user roles, and configure backups; provide proxy certificates and review intended network exposure |

DBMS-specific implementation and operational tasks are documented in the respective version and platform READMEs. The common BSI references and security objectives are maintained here for every DBMS.

## Database folders

- [MariaDB](MariaDB/README.md)
- [MongoDB](MongoDB/README.md)
- [MySQL](MySQL/README.md)
- [PostgreSQL](PostgreSQL/README.md)
- [Redis](Redis/README.md)
- [Weaviate](Weaviate/README.md)

© 2026 - Secure database configurations
