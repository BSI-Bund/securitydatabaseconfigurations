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
✅ Redis

Coming soon:

➡️ Neo4j
➡️ PostgreSQL  

---

## ⚙️ Installation & usage

1. Choose a configuration file from `configs/`.  
2. Adjust it to your environment and security requirements.  
3. Apply the configuration to your database.  
4. Test connectivity, authentication, and backups.

---

## 🔒 TLS configuration

This guide shows how to create your own **Certificate Authority (CA)** with OpenSSL on Windows and issue **server and client certificates** for applications such as MongoDB. The X.509 extensions are defined explicitly so that the resulting certificates remain reviewable and reproducible instead of depending on local OpenSSL defaults.

---

### ⚙️ Prerequisites

* Installed [OpenSSL for Windows](https://slproweb.com/products/Win32OpenSSL.html)
* Write access to the certificate directory (e.g., `C:\data`)
* Replace the example DNS names and IP addresses with values matching the target environment

> [!IMPORTANT]
> Private keys must be protected with restrictive file permissions. The CA private key is encrypted with AES-256 in this example. Server and client private keys remain unencrypted for unattended service use and therefore require appropriate filesystem protection.

---

### 🏗️ 1. Create CA

```powershell
# Generate an encrypted CA private key
openssl genrsa -aes256 -out test-ca.key 4096

# Create the CA certificate with explicit CA extensions
openssl req -x509 -new -key test-ca.key -sha256 -days 365 -out test-ca.pem -subj "/CN=MongoDB Test CA" -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign"
```

Result:

* `test-ca.key` → AES-256-encrypted CA private key
* `test-ca.pem` → self-signed CA certificate with explicit CA properties

---

### 🖥️ 2. Create and sign server certificate

```powershell
# Generate server key
openssl genrsa -out mongo-server1.key 4096

# Create Certificate Signing Request (CSR)
openssl req -new -key mongo-server1.key -out mongo-server1.csr -subj "/CN=mongo-server1"

# Define explicit X.509 extensions for the server certificate
@"
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:mongo-server1,DNS:localhost,IP:127.0.0.1
"@ | Set-Content -Encoding ascii server-ext.cnf

# Sign CSR with the CA and the explicit server extensions
openssl x509 -req -in mongo-server1.csr -CA test-ca.pem -CAkey test-ca.key -CAcreateserial -out mongo-server1.crt -days 365 -sha256 -extfile server-ext.cnf

# Combine key + certificate for MongoDB
cmd /c copy /b mongo-server1.key+mongo-server1.crt mongo-server1.pem
```

> [!NOTE]
> The `subjectAltName` values must match the DNS names or IP addresses clients actually use to reach the MongoDB server. Certificate identity verification uses these values for hostname validation.

Result:

* `mongo-server1.pem` → server certificate including the private key and certificate
* `server-ext.cnf` → explicit X.509 extensions for the server certificate

---

### 👤 3. Create and sign client certificate

```powershell
# Generate client key
openssl genrsa -out mongo-client.key 4096

# Create Certificate Signing Request (CSR)
openssl req -new -key mongo-client.key -out mongo-client.csr -subj "/CN=mongo-client"

# Define explicit X.509 extensions for the client certificate
@"
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=clientAuth
"@ | Set-Content -Encoding ascii client-ext.cnf

# Sign CSR with the CA and the explicit client extensions
openssl x509 -req -in mongo-client.csr -CA test-ca.pem -CAkey test-ca.key -CAcreateserial -out mongo-client.crt -days 365 -sha256 -extfile client-ext.cnf

# Combine key + certificate for the client
cmd /c copy /b mongo-client.key+mongo-client.crt mongo-client.pem
```

Result:

* `mongo-client.pem` → client certificate including the private key and certificate
* `client-ext.cnf` → explicit X.509 extensions for the client certificate

---

### 🔍 4. Verify certificates

The generated certificates and their extensions should be reviewed before use:

```powershell
openssl x509 -in test-ca.pem -noout -text
openssl x509 -in mongo-server1.crt -noout -text
openssl x509 -in mongo-client.crt -noout -text
```

The server certificate should show `CA:FALSE`, `TLS Web Server Authentication`, and the expected Subject Alternative Names. The client certificate should show `TLS Web Client Authentication`.

---

### ⚡ 5. MongoDB TLS configuration

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

* **Encrypted CA key and CA certificate created** (`test-ca.key`, `test-ca.pem`)
* **Server certificate created with explicit SAN and `serverAuth`** (`mongo-server1.pem`)
* **Client certificate created with explicit `clientAuth`** (`mongo-client.pem`)
* **X.509 extensions can be reviewed before use**
* **MongoDB TLS enabled** via `mongod.conf`

---

## ⚠️ Disclaimer

These files serve as **general security guides**.  
Before using them in production, review them carefully and adapt them to your **internal requirements**.

---

© 2025 – Secure database configurations
