# MongoDB 8 – Windows

[Deutsch](README-de.md) · [Database overview](../../README.md) · [BSI-Alignment](../../../README.md#bsi-alignment)

The [`mongod.conf`](mongod.conf) template runs a single instance with TLS and authorization enabled. Install MongoDB Community and, separately, `mongosh`: [Windows installation](https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-windows/).

- [Preparation](#preparation)
- [Create the administration account for a new instance](#create-the-administration-account-for-a-new-instance)
- [Normal startup and login](#normal-startup-and-login)
- [Verify the effective configuration](#verify-the-effective-configuration)

## Preparation

Relative paths refer to this README directory. Before initial setup, stop any existing MongoDB service gracefully and ensure no other process uses the same data directory. Do not reinitialize an existing data directory.

The configuration uses `C:\data\mongodb` for data and `C:\data\log` for logs. Create them in PowerShell and grant the eventual service account the required permissions:

```powershell
New-Item -ItemType Directory -Force C:\data\mongodb, C:\data\log
```

Follow the [TLS guide](../../../../docs/TLS.md) to create and prepare CA, server, and client certificates:

| File | Contents |
|------|----------|
| `C:\data\test-ca.pem` | Public CA certificate |
| `C:\data\mongo-server1.pem` | Combined server key and certificate |
| `C:\data\mongo-client.pem` | Combined client key and certificate |

Keep the private CA key off the database server. Server SANs must cover `localhost` or the actual DNS names used. The template also requires a client certificate; username/password authentication remains required.

The supplied configuration binds exclusively to `127.0.0.1` on port **27018**. Deliberately adapt network exposure, TLS identities, and firewall rules for intended remote access.

## Create the administration account for a new instance

The regular configuration disables the localhost authentication bypass. Create the first administration account before starting with that configuration. The new administration password is requested twice interactively during user creation; the script contains no password.

For a new, unconfigured data directory, start a temporary server on localhost only. In the first PowerShell:

```powershell
& "C:\Program Files\MongoDB\Server\8.0\bin\mongod.exe" --dbpath C:\data\mongodb --logpath C:\data\log\bootstrap.log --bind_ip 127.0.0.1 --port 27017 --noauth
```

In a second PowerShell from the README directory, with `mongosh` on the search path:

```powershell
.\init_scripts\init_mongodb.bat --bootstrap
```

After successful user creation, stop the temporary server gracefully with `Ctrl+C` in the first window. Temporary bootstrap port `27017` differs from normal template port `27018`.

The batch script only connects to the prepared instance; it does not start or stop processes. Before creating a user, `init_users.js` checks the expected data path, loopback-only binding, disabled authorization, and absence of existing administration users. Set `MONGO_BOOTSTRAP_DBPATH` and `MONGO_BOOTSTRAP_PORT` for different paths or ports; calls without `--bootstrap` are rejected. Put `mongosh` on PATH or set `MONGOSH_EXE` to its full executable path. Failures return a nonzero exit code.

## Normal startup and login

Run in PowerShell from this README directory:

```powershell
& "C:\Program Files\MongoDB\Server\8.0\bin\mongod.exe" --config .\mongod.conf
```

For persistent service operation, configure the actual Windows service to load this file and inspect it with `sc.exe qc MongoDB`. Do not run the service and a manual process against the same data directory simultaneously.

In a second PowerShell:

```powershell
mongosh --host localhost --port 27018 --tls --tlsCAFile C:\data\test-ca.pem --tlsCertificateKeyFile C:\data\mongo-client.pem --username admin --authenticationDatabase admin --password
```

The password is requested interactively. The script creates only a root administration account; create restricted application accounts separately.

## Verify the effective configuration

In an administrative `mongosh` session, check `db.adminCommand({ getCmdLineOpts: 1 })` and `db.runCommand({ connectionStatus: 1 })`. The template writes database logs to `C:\data\log\mongod.log`.

The supplied file contains:

```yaml
# System logging
systemLog:
  destination: file
  path: "C:\\data\\log\\mongod.log"
  logAppend: true
  verbosity: 0

# Storage options
storage:
  dbPath: "C:\\data\\mongodb"

# Network options
net:
  bindIp: 127.0.0.1
  port: 27018
  maxIncomingConnections: 200
  tls:
    mode: requireTLS
    certificateKeyFile: "C:\\data\\mongo-server1.pem"
    CAFile: "C:\\data\\test-ca.pem"

# Security options
security:
  authorization: enabled

# Parameters
setParameter:
  enableLocalhostAuthBypass: false
```

Set up backups, retention, and restore tests separately. This guide does not describe replication or high availability.
