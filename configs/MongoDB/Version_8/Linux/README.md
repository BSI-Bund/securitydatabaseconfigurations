# <img src="https://www.svgrepo.com/show/331488/mongodb.svg" alt="MongoDB Logo" width="26"/> MongoDB – Linux (Docker Compose)

- [🚀 Getting started with the Docker Compose setup](#-getting-started-with-the-docker-compose-setup)
  - [⚙️ Services](#️-services)
  - [🧾 Environment variables](#-environment-variables)
  - [📑 Example `mongod.conf` (short)](#-example-mongodconf-short)
  - [📑 Parameter reference (short)](#-parameter-reference-short)
    - [🔐 security](#-security)
    - [🌐 net](#-net)
    - [📦 storage](#-storage)
    - [📘 systemLog](#-systemlog)
    - [⚙️ setParameter](#-setparameter)
  - [🧩 Secure configuration notes](#-secure-configuration-notes)
  - [📁 Volumes & mounts](#-volumes--mounts)
  - [🌐 Ports](#-ports)
- [🎛️ Start & operations](#️-start--operations)

---

## 🚀 Getting started with the Docker Compose setup

This setup provides a **MongoDB 8 instance** using the official [MongoDB Docker image](https://hub.docker.com/_/mongo).

Configuration file:

```bash
mongodb-compose/docker-compose.yml  # uses values from .env
```

---

### ⚙️ Services

#### 🗄️ mongodb

- Image `mongo:8-noble`
- Starts with external `mongod.conf`
- TLS files (CA/server) are mounted
- Volume-based persistence

---

### 🧾 Environment variables

Example values live in `mongodb-compose/.env.example`. Copy before starting:

```bash
cd mongodb-compose
cp .env.example .env
```

---

### 📑 Example `mongod.conf` (short)

```yaml
systemLog:
  destination: file
  path: "/var/log/mongodb/mongod.log"
  logAppend: true

storage:
  dbPath: "/var/lib/mongodb"

net:
  bindIp: 127.0.0.1
  port: 27017
  tls:
    mode: requireTLS
    certificateKeyFile: /etc/ssl/mongodb/test-server1.pem
    CAFile: /etc/ssl/mongodb/test-ca.pem

security:
  authorization: enabled

setParameter:
  enableLocalhostAuthBypass: false
```

---

### 📑 Parameter reference (short)

#### 🔐 security

| Option              | Meaning                         | Recommendation |
|---------------------|---------------------------------|----------------|
| `authorization`     | Access control                  | `enabled` |

#### 🌐 net

| Option                   | Description                      | Recommendation |
|--------------------------|----------------------------------|----------------|
| `bindIp`                 | Bind address(es)                 | `127.0.0.1` or VPN IP; (`0.0.0.0` localhost by docker compose file) |
| `port`                   | Listener port                    | 27017 (with firewall) |
| `maxIncomingConnections` | Max concurrent connections       | 200 (default) |
| `tls.mode`               | TLS mode                         | `requireTLS` for prod |
| `tls.certificateKeyFile` | Server certificate + key         | Path to `.pem` |
| `tls.CAFile`             | Root CA                          | Set path, enforce validation |

Creation of TLS certificate, see [README](../../../../README.md#-tls-configuration)

#### 📦 storage

| Option                                | Meaning              | Recommendation |
|---------------------------------------|----------------------|----------------|
| `dbPath`                              | Data directory       | Volume, e.g., `/var/lib/mongodb` |

#### 📘 systemLog

| Option        | Meaning                         | Recommendation |
|---------------|---------------------------------|----------------|
| `destination` | Log target                      | `file` (default) |
| `path`        | Location                        | e.g., `/var/log/mongodb/mongod.log` |
| `logAppend`   | Append to log                   | `true` |
| `verbosity`   | verbosity of log files          | `0` |

#### ⚙️ setParameter

| Parameter                   | Meaning                                   | Recommendation |
|-----------------------------|-------------------------------------------|----------------|
| `enableLocalhostAuthBypass` | Admin bypass only from localhost          | `false` in prod |
| `enableTestCommands`        | Enable unsupported features               | `false` in prod |

---

### 🧩 Secure configuration notes

- Set `authorization: enabled` by default; then create an admin user.
- Restrict `bindIp` (`127.0.0.1` or VPN); avoid public `0.0.0.0` without protection.
- `tls.mode: requireTLS` with real certificates; CA/key files readable only by `mongodb`.
- For replica sets, use `keyFile` or x.509 auth.
- `enableLocalhostAuthBypass: false` once users exist.
- Test backups & restore; keep journaling enabled.

---

### 📁 Volumes & mounts

| Mount                                                  | Description                          |
|--------------------------------------------------------|--------------------------------------|
| `mongo:/data/db`                                       | Persistent data                      |
| `../mongod.conf:/etc/mongo/mongod.conf`                | External configuration               |
| `./test-ca.pem:/etc/ssl/mongodb/test-ca.pem`           | CA certificate                       |
| `./test-server1.pem:/etc/ssl/mongodb/test-server1.pem` | Server certificate                   |

---

### 🌐 Ports

| Port    | Service | Description      |
|---------|---------|------------------|
| `27017` | MongoDB | Database access  |

---

## 🎛️ Start & operations

### ▶️ Start

```bash
cd mongodb-compose
docker compose up -d
```

### ⏹️ Stop

```bash
cd mongodb-compose
docker compose down
```

### 🧾 Show logs

```bash
cd mongodb-compose
docker compose logs -f
```

### 🧹 Remove the database (optional)

```bash
docker volume rm <project>_mongo
```

---

© 2025 – Secure database configurations

