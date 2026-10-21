# PostgreSQL 18.6 - BSI Alignment Notes

This PostgreSQL baseline is a recommendation and template for secure PostgreSQL setups. It is aligned with the BSI key points for database systems, the BSI practical guide for secure database systems, and IT-Grundschutz module APP.4.3.

References:
- [BSI key points for selecting and using database systems](https://www.bsi.bund.de/SharedDocs/Downloads/DE/BSI/Datenbanksysteme/datenbanksystem_eckpunkte_papier.pdf?__blob=publicationFile&v=2)
- [BSI appendix to the database system key points](https://www.bsi.bund.de/SharedDocs/Downloads/DE/BSI/Datenbanksysteme/datenbanksystem_eckpunkte_anlagen.pdf?__blob=publicationFile&v=2)
- [BSI practical guide for secure database systems](https://www.bsi.bund.de/SharedDocs/Downloads/DE/BSI/Datenbanksysteme/praxisleitfaden_sichere_datenbanksysteme.pdf)
- [BSI IT-Grundschutz APP.4.3 Relationale Datenbanksysteme](https://it-grundschutzkompendium.de/app_anwendungen/app.4.3_relationale_datenbanken)

## Covered By This Baseline

| BSI topic | Recommendation in this baseline | Usage notes |
|-----------|---------------------------------|-------------------|
| Planning and standardization | Versioned PostgreSQL folder, READMEs, parameter reference, tested Compose files | Use as a traceable starting point for deployments |
| Secure initial setup | Compose setup, `.env.example`, init scripts, least-privilege sample roles | Adapt sample secrets and roles to the application |
| Access control and authentication | SCRAM-SHA-256, explicit `pg_hba.conf`, localhost host binding | Define networks, service accounts, and admin access deliberately |
| Transport protection | TLS override, `hostssl` rules, certificate directory, generator, and one-command local TLS startup | Use an own CA/certificates for non-local connections |
| Logging and monitoring | Connection/disconnection logging, DDL logging, slow-query logging, lock/autovacuum/checkpoint diagnostics | Adjust log scope and forwarding to the environment |
| Backup and restore | `backup.sh`, `restore.sh`, checksum generation, backup docs | Choose backup location, retention, and restore tests by protection needs |
| Update and maintenance | Versioned image tag and docs | Track PostgreSQL, image, host, and platform updates regularly |

## Scope

These files provide technical recommendations for PostgreSQL. They do not replace an assessment of the target environment; they provide reviewable starting values for configuration, Compose operation, TLS, roles, logging, and backup.

## Usage Notes

The examples are intentionally runnable and contain placeholder values. For production-like deployments, adapt secrets, networks, certificates, roles, backup/restore, and logging to the respective protection needs.

© 2026 - Secure database configurations
