# <img src="https://www.svgrepo.com/show/331488/mongodb.svg" alt="MongoDB Logo" width="26"/> MongoDB – Windows

- [💾 Windows installation notes](#-windows-installation-notes)
  - [📁 Create the data directory](#-create-the-data-directory)
  - [🚀 Start MongoDB (example)](#-start-mongodb-example)
- [📑 Example `mongod.conf` (short)](#-example-mongodconf-short)
- [📑 Parameter reference (short)](#-parameter-reference-short)
  - [🔐 security](#-security)
  - [🌐 net](#-net)
  - [📦 storage](#-storage)
  - [📘 systemLog](#-systemlog)
  - [⚙️ setParameter](#-setparameter)
- [🧩 Secure configuration notes](#-secure-configuration-notes)
- [🧩 Init script (`init_mongodb.bat`)](#-init-script-init_mongodbbat)
  - [⚙️ Flow](#-flow)
  - [🎯 Purpose](#-purpose)

---

## 💾 Windows installation notes

Install via **MongoDB Community .msi** from the [Download Center](https://www.mongodb.com/try/download/community?tck=docs_server).  
Default config path: `<install_dir>\bin\mongod.cfg`

### 📁 Create the data directory

```powershell
cd C:\
md "\data\db"
```

### 🚀 Start MongoDB (example)

```powershell
"C:\Program Files\MongoDB\Server\8.0\bin\mongod.exe" --dbpath="C:\data\db"
```

Start with custom config:

```powershell
"C:\Program Files\MongoDB\Server\8.0\bin\mongod.exe" --config "C:\DB\mongod.conf"
```

More info: [Official MongoDB docs – Install on Windows](https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-windows/)

---

## 📑 Example `mongod.conf` (short)

```yaml
systemLog:
  destination: file
  path: "C:\\Program Files\\MongoDB\\Server\\8.0\\log\\mongod.log"
  logAppend: true

storage:
  dbPath: "C:\\Program Files\\MongoDB\\Server\\8.0\\data"

net:
  bindIp: 127.0.0.1
  port: 27017
  tls:
    mode: requireTLS
    certificateKeyFile: "C:\\certs\\mongodb\\server.pem"
    CAFile: "C:\\certs\\mongodb\\ca.pem"

security:
  authorization: enabled

setParameter:
  enableLocalhostAuthBypass: false
```

---

## 📑 Parameter reference (short)

### 🔐 security

| Option              | Meaning                             | Recommendation |
|---------------------|-------------------------------------|----------------|
| `authorization`     | Access control                      | `enabled` |

### 🌐 net

| Option                   | Description                      | Recommendation |
|--------------------------|----------------------------------|----------------|
| `bindIp`                 | Bind address(es)                 | `127.0.0.1` or VPN IP; avoid open `0.0.0.0` |
| `port`                   | Listener port                    | 27017 (firewall) |
| `maxIncomingConnections` | Max concurrent connections       | 200 (default) |
| `tls.mode`               | TLS mode                         | `requireTLS` for prod |
| `tls.certificateKeyFile` | Server certificate + key         | Path to `.pem` |
| `tls.CAFile`             | Root CA                          | Set path, enforce validation |

Creation of TLS certificate, see [README](../../../../README.md#-tls-configuration)

### 📦 storage

| Option                                | Meaning               | Recommendation |
|---------------------------------------|-----------------------|----------------|
| `dbPath`                              | Data directory        | e.g. `C:\\Program Files\\MongoDB\\Server\\8.0\\data` or a volume |

### 📘 systemLog

| Option        | Meaning                         | Recommendation |
|---------------|---------------------------------|----------------|
| `destination` | Log target                      | `file` |
| `path`        | Location                        | e.g. `C:\\Program Files\\MongoDB\\Server\\8.0\\log\\mongod.log` |
| `logAppend`   | Append to log                   | `true` |
| `verbosity`   | verbosity of log files          | `0` |

### ⚙️ setParameter

| Parameter                   | Meaning                                   | Recommendation |
|-----------------------------|-------------------------------------------|----------------|
| `enableLocalhostAuthBypass` | Admin bypass only from localhost          | `false` in prod |
| `enableTestCommands`        | Enable unsupported features               | `false` in prod |

---

## 🧩 Secure configuration notes

- Set `authorization: enabled` by default; then create an admin user.  
- Restrict `bindIp` (`127.0.0.1` or VPN); avoid public `0.0.0.0` without protection.  
- Use `tls.mode: requireTLS` with real certificates; CA/key files readable only by the service account.  
- For replica sets, use `keyFile` or x.509 auth.  
- `enableLocalhostAuthBypass: false` once users exist.  
- Test backups & restore; keep journaling enabled.

---

## 🧩 Init script (`init_mongodb.bat`)

This script automates the **initial bootstrap** of a MongoDB instance on Windows.

### ⚙️ Flow

1. Start without auth to create the admin user.  
2. Run `init_users.js` (users/roles).  
3. Stop the temporary server.  
4. Restart with auth & config (`mongod.conf`).  
5. Print success message.

### 🎯 Purpose

Secure, repeatable first-time setup; users are created once without auth, then the server runs protected.

---

© 2025 – Secure database configurations

