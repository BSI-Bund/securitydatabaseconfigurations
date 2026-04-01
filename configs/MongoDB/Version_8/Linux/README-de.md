# <img src="https://www.svgrepo.com/show/331488/mongodb.svg" alt="MongoDB Logo" width="26"/> MongoDB – Linux (Docker Compose)

- [🚀 Hinweise zum Start mit Docker Compose Setup](#-hinweise-zum-start-mit-docker-compose-setup)
  - [⚙️ Services](#-services)
  - [🧾 Umgebungsvariablen](#-umgebungsvariablen)
  - [📑 Beispiel `mongod.conf` (Kurz)](#-beispiel-mongodconf-kurz)
  - [📑 Parameter-Referenz (Kurz)](#-parameter-referenz-kurz)
    - [🔐 security](#-security)
    - [🌐 net](#-net)
    - [📦 storage](#-storage)
    - [📘 systemLog](#-systemlog)
    - [⚙️ setParameter](#-setparameter)
  - [🧩 Hinweise zur sicheren Konfiguration](#-hinweise-zur-sicheren-konfiguration)
  - [📁 Volumes & Mounts](#-volumes--mounts)
  - [🌐 Ports](#-ports)
- [🎛️ Start & Verwaltung](#-start--verwaltung)

---

## 🚀 Hinweise zum Start mit Docker Compose Setup

Dieses Setup stellt eine **MongoDB 8 Instanz** bereit.  
Es basiert auf dem offiziellen [MongoDB Docker-Image](https://hub.docker.com/_/mongo).

Konfiguration über:

```bash
mongodb-compose/docker-compose.yml  # nutzt Werte aus .env
```

---

### ⚙️ Services

#### 🗄️ mongodb

- Image `mongo:8-noble`
- Start mit externer `mongod.conf`
- TLS-Dateien (CA/Server) werden gemountet
- Volumebasiertes Persistenz-Setup

---

### 🧾 Umgebungsvariablen

Beispielwerte liegen in `mongodb-compose/.env.example`. Vor dem Start kopieren:

```bash
cd mongodb-compose
cp .env.example .env
```

---

### 📑 Beispiel `mongod.conf` (Kurz)

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

### 📑 Parameter-Referenz (Kurz)

#### 🔐 security

| Option              | Bedeutung                         | Empfehlung |
|---------------------|-----------------------------------|------------|
| `authorization`     | Zugriffskontrolle                | `enabled` |

#### 🌐 net

| Option                   | Beschreibung                      | Empfehlung |
|--------------------------|-----------------------------------|------------|
| `bindIp`                 | Bind-Adresse(n)                   | `127.0.0.1` oder VPN-IP, (`0.0.0.0` localhost über Docker Compose File) |
| `port`                   | Listener-Port                     | 27017 (mit Firewall) |
| `maxIncomingConnections` | Max gleichzeitige Verbindungen    | 200 (default) |
| `tls.mode`               | TLS-Modus                         | `requireTLS` für Prod |
| `tls.certificateKeyFile` | Server-Zertifikat + Key           | Pfad zu `.pem` |
| `tls.CAFile`             | Root-CA                           | Pfad setzen, Validierung aktivieren |

Erstellung TLS Zertifikat siehe [README](../../../../README-de.md#-tls-konfiguration)

#### 📦 storage

| Option                                | Bedeutung              | Empfehlung |
|---------------------------------------|------------------------|------------|
| `dbPath`                              | Datenverzeichnis       | Volume, z. B. `/var/lib/mongodb` |

#### 📘 systemLog

| Option        | Bedeutung                      | Empfehlung |
|---------------|--------------------------------|------------|
| `destination` | Ziel für Logs                  | `file` (Standard) |
| `path`        | Speicherort                    | z. B. `/var/log/mongodb/mongod.log` |
| `logAppend`   | An Log anhängen                | `true` |
| `verbosity`   | Detailgrad Log-Dateien         | `0` |

#### ⚙️ setParameter

| Parameter                   | Bedeutung                                  | Empfehlung |
|-----------------------------|--------------------------------------------|------------|
| `enableLocalhostAuthBypass` | Admin-Bypass nur von localhost             | `false` in Prod |
| `enableTestCommands`        | Nicht-unterstützte Features aktivieren    | `false` in Prod |

---

### 🧩 Hinweise zur sicheren Konfiguration

- `authorization: enabled` standardmäßig setzen; danach Admin-User anlegen.
- `bindIp` restriktiv (`127.0.0.1` oder VPN); kein öffentliches `0.0.0.0` ohne Schutz.
- `tls.mode: requireTLS` mit echten Zertifikaten; CA/Key-Dateien nur für `mongodb` lesbar.
- Bei ReplSets `keyFile` oder x.509 Auth nutzen.
- `enableLocalhostAuthBypass: false`, sobald User existieren.
- Backups & Restore testen; Journaling aktiv halten.

---

### 📁 Volumes & Mounts

| Mount                                                  | Beschreibung                             |
|--------------------------------------------------------|------------------------------------------|
| `mongo:/data/db`                                       | Persistente Daten                        |
| `../mongod.conf:/etc/mongo/mongod.conf`                | Externe Konfiguration                    |
| `./test-ca.pem:/etc/ssl/mongodb/test-ca.pem`           | CA-Zertifikat                            |
| `./test-server1.pem:/etc/ssl/mongodb/test-server1.pem` | Server-Zertifikat                        |

---

### 🌐 Ports

| Port    | Dienst  | Beschreibung     |
|---------|---------|------------------|
| `27017` | MongoDB | Datenbankzugriff |

---

## 🎛️ Start & Verwaltung

### ▶️ Starten

```bash
cd mongodb-compose
docker compose up -d
```

### ⏹️ Stoppen

```bash
cd mongodb-compose
docker compose down
```

### 🧾 Logs anzeigen

```bash
cd mongodb-compose
docker compose logs -f
```

### 🧹 Datenbank entfernen (optional)

```bash
docker volume rm <projektname>_mongo
```

---

© 2025 – Sichere Datenbankkonfigurationen

