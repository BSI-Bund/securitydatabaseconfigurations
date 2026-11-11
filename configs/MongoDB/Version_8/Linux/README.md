# MongoDB 8 – Linux with Docker Compose

[Deutsch](README-de.md) · [Database overview](../../README.md) · [BSI-Alignment](../../../README.md#bsi-alignment)

This template runs a single MongoDB instance. Files: [`mongod.conf`](mongod.conf) and [`mongodb-compose/docker-compose.yml`](mongodb-compose/docker-compose.yml). The moving image tag `mongo:8-noble` does not pin a patch release.

- [Preparation](#preparation)
- [Startup and initialization](#startup-and-initialization)
- [Login and verification](#login-and-verification)
- [Configuration and logs](#configuration-and-logs)
- [Operations](#operations)
- [References](#references)

## Preparation

Install Docker with Compose, OpenSSL for the certificate example, and `mongosh` on the client. Run all following Compose commands from `mongodb-compose/`. Starting in this README directory:

```bash
cd mongodb-compose
cp .env.example .env
mkdir -p ssl
```

1. Replace all sample secrets in `.env`. `MONGO_USER` and `MONGO_PASSWORD` are passed as `MONGO_INITDB_ROOT_USERNAME` and `MONGO_INITDB_ROOT_PASSWORD`: this account has **root privileges in `admin`**, despite the sample name `appuser`.
2. Follow the [TLS guide](../../../../docs/TLS.md) to create CA, server, and client certificates. Server SANs must cover `localhost` and any container/DNS name actually used.
3. Prepare these files in `mongodb-compose/ssl/`:

| File | Contents and use |
|------|------------------|
| `test-ca.pem` | Public CA certificate; mounted into the server |
| `test-server1.pem` | Combined server key and certificate; mounted into the server |
| `client.pem` | Combined client key and certificate; for the client only |

4. The `ssl/` certificate source and `mongo_logs` log volume are already mounted. The startup wrapper initializes log permissions and copies only the two required server PEM files into a private tmpfs directory under `/etc/ssl/mongodb`. Files are owned by `mongodb` with mode `0600`; the client key stays on the client.
5. Run `docker compose config --quiet` and review the resolved configuration.

The template requires TLS. Because `allowConnectionsWithoutCertificates` is not enabled, clients also need a certificate signed by the same trusted CA. It does not replace username/password authentication.

## Startup and initialization

```bash
docker compose up -d
docker compose ps
docker compose logs --tail 100 mongodb
```

The host port is exclusively `127.0.0.1:27017`. `bindIp: 0.0.0.0` applies inside the container. The persistent data path is `/data/db`, matching the `mongo` volume.

On first startup with an empty volume, the image entrypoint creates the administration account. `MONGO_DATABASE` selects an initialization database; without writes or initialization scripts, this variable alone does not create a populated application database. Editing `.env` does not change accounts in an already initialized volume.

## Login and verification

Run on the host from `mongodb-compose/`. Adapt the username to `MONGO_USER`; the password is requested interactively:

```bash
mongosh --host localhost --port 27017 --tls --tlsCAFile ssl/test-ca.pem --tlsCertificateKeyFile ssl/client.pem --username appuser --authenticationDatabase admin --password
```

In the administrative session:

```javascript
db.adminCommand({ getCmdLineOpts: 1 })
db.runCommand({ connectionStatus: 1 })
```

Create a separate application account with roles limited to its database. Do not use the bootstrap root account for regular application access.

## Configuration and logs

The supplied `mongod.conf` contains:

```yaml
# System logging
systemLog:
  destination: file
  path: /var/log/mongodb/mongod.log
  logAppend: true
  verbosity: 0

# Storage options
storage:
  dbPath: /data/db

# Network options
net:
  bindIp: 0.0.0.0
  port: 27017
  maxIncomingConnections: 200
  tls:
    mode: requireTLS
    certificateKeyFile: /etc/ssl/mongodb/test-server1.pem
    CAFile: /etc/ssl/mongodb/test-ca.pem

# Security options
security:
  authorization: enabled

# Parameters
setParameter:
  enableLocalhostAuthBypass: false
```

`maxIncomingConnections: 200` and `verbosity: 0` are template values. The Compose command does not override logging verbosity.

After initialization, MongoDB writes to the configured log file. `docker compose logs` therefore does not show all database events. Example:

```bash
docker compose exec mongodb tail -n 100 /var/log/mongodb/mongod.log
```

## Operations

```bash
docker compose stop
docker compose start
docker compose down
```

`down` retains the data volume. Set up backups and restore tests separately. This template does not include a replica set or high availability configuration.

## References

- [MongoDB Docker image and initialization](https://hub.docker.com/_/mongo)
- [MongoDB: TLS configuration and client certificates](https://www.mongodb.com/docs/manual/tutorial/configure-ssl/)
