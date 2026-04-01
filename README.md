# 🛡️ Secure Database Configurations

- [📘 Contents](#-contents)
- [🎯 Audience](#-audience)
- [📘 Security objectives](#-security-objectives)
  - [🌐 Encrypted network configuration (TLS/SSL)](#-encrypted-network-configuration-tlsssl)
  - [🧾 Logging](#-logging)
  - [💾 Storage configuration](#-storage-configuration)
  - [♻️ Backups](#️-backups)
  - [👤 Secure authentication & privileges](#-secure-authentication--privileges)
  - [🧱 Updates & maintenance](#-updates--maintenance)
- [📁 Repository structure](#-repository-structure)
- [🛠️ Supported databases](#️-supported-databases)
- [⚙️ Installation & usage](#️-installation--usage)
- [🔒 TLS configuration](#-tls-configuration)
- [⚠️ Disclaimer](#️-disclaimer)


---

## 📘 Contents

This repository provides **secure configurations for multiple database systems**.  
It also includes scripts to **initialize the databases** and notes on **hardening tools**.  
Database deployments are provided for:

- 🐧 **Linux with Docker Compose** → containerized, automated setups  
- 🪟 **Windows without Docker** → local, manual installs (e.g., development environments)

---

## 🎯 Audience

This repository is aimed at:
- IT administrators
- Database administrators
- Developers focused on secure database operations

---

## 📘 Security objectives

Goal: reproducible, secure database setups covering these aspects:

### 🌐 Encrypted network configuration (TLS/SSL)
- Enforce encrypted communication (TLS/SSL)
- Restrict access to trusted networks or hosts

### 🧾 Logging
- Enable meaningful logs to **trace activity**
- Log failed or suspicious access attempts

### 💾 Storage configuration
- Define secure locations for database files
- Use restrictive permissions on data and log directories

### ♻️ Backups
- Automated, regular, encrypted backups
- Verify restorability (restore tests)

### 👤 Secure authentication & privileges
- Use **role-based access control (RBAC)**
- Minimal privileges following the **least-privilege principle**

The following must be done continuously in operations:

### 🧱 Updates & maintenance
- Apply **security updates** regularly
- Monitor database logs for security incidents

---

## 📁 Repository structure

DBMS folders generally follow this structure:
```bash
DatabaseSystem/                             # DBMS name
└── Version_X/                              # Version number
    ├── Linux/                              # Docker Compose setup (container, .env, volumes, init scripts)
    │   ├── compose/                        # Docker Compose configuration
    |   |   ├── init_db/                    # Collection of scripts to initialize the DBMS
    |   |   ├── .env.default                # Template for environment variables (e.g., username, port, password)
    |   |   └── docker-compose.yml          # Docker Compose file
    │   ├── config_description-linux.md     # Description of security-relevant settings and their purpose
    |   └── *configuration file*            # DBMS-specific configuration file
    └── Windows/                            # Classic configuration for local Windows installation
        ├── init_scripts/                   # Scripts for database initialization
        ├── config_description-windows.md   # Description of security-relevant settings and their purpose
        └── *configuration file*            # DBMS-specific configuration file
```
---

## 🛠️ Supported databases

✅ MariaDB  
✅ MongoDB  
✅ MySQL  
✅ Weaviate  

Coming soon:

➡️ PostgreSQL  
➡️ Redis  

---

## ⚙️ Installation & usage

1. Choose a configuration file from `configs/`.  
2. Adjust it to your environment and security requirements.  
3. Apply the configuration to your database.  
4. Test connectivity, authentication, and backups.

---

## 🔒 TLS configuration

This guide shows how to create your own **Certificate Authority (CA)** with OpenSSL and issue **server and client certificates** for applications such as MongoDB.

---

### ⚙️ Prerequisites

* Installed [OpenSSL for Windows](https://slproweb.com/products/Win32OpenSSL.html)
* Write access to the certificate directory (e.g., `C:\data`)
* Path to `openssl.cnf` (e.g., `C:\Users\<User>\openssl-3.5.3\apps\openssl.cnf`)

---

### 🏗️ 1. Create CA

```powershell
# Generate CA key
openssl genrsa -out test-ca.key 4096

# Create CA certificate
openssl req -x509 -new -nodes -key test-ca.key -sha256 -days 365 -out test-ca.pem -config "C:\Users\<User>\openssl-3.5.3\apps\openssl.cnf"
```

Result:

* `test-ca.key` → CA private key
* `test-ca.pem` → self-signed CA certificate

---

### 🖥️ 2. Create and sign server certificate

```powershell
# Generate server key
openssl genrsa -out mongo-server1.key 4096

# Create CSR
openssl req -new -key mongo-server1.key -out mongo-server1.csr -config "C:\Users\<User>\openssl-3.5.3\apps\openssl.cnf"

# Sign CSR with CA
openssl x509 -req -in mongo-server1.csr -CA test-ca.pem -CAkey test-ca.key -CAcreateserial -out mongo-server1.crt -days 365 -sha256

# Combine key + cert for MongoDB
copy /b mongo-server1.key+mongo-server1.crt mongo-server1.pem
```

Result:

* `mongo-server1.pem` → certificate MongoDB uses (includes key + CRT)

---

### 👤 3. Create and sign client certificate

```powershell
# Generate client key and CSR
openssl genrsa -out mongo-client.key 4096
openssl req -new -key mongo-client.key -out mongo-client.csr -config "C:\Users\<User>\openssl-3.5.3\apps\openssl.cnf"

# Sign CSR with CA
openssl x509 -req -in mongo-client.csr -CA C:\data\test-ca.pem -CAkey C:\data\test-ca.key -CAcreateserial -out mongo-client.crt -days 365 -sha256

# Combine key + cert for the client
copy /b mongo-client.key+mongo-client.crt mongo-client.pem
```

Result:

* `mongo-client.pem` → certificate the client uses (includes key + CRT)

---

### ⚡ 4. MongoDB TLS configuration

### 🧩 `mongod.conf` example

```yaml
net:
  port: 27017
  bindIp: 0.0.0.0
  tls:
    mode: requireTLS
    certificateKeyFile: C:\data\mongo-server1.pem
    CAFile: C:\data\test-ca.pem
```

---

### 📋 Summary

* **CA created** (`test-ca.pem`, `test-ca.key`)
* **Server certificate created and signed** (`mongo-server1.pem`)
* **Client certificate created and signed** (`mongo-client.pem`)
* **MongoDB TLS enabled** via `mongod.conf`

---

## ⚠️ Disclaimer

These files serve as **general security guides**.  
Before using them in production, review them carefully and adapt them to your **internal requirements**.

---

© 2025 – Secure database configurations
