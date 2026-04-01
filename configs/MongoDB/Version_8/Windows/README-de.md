# <img src="https://www.svgrepo.com/show/331488/mongodb.svg" alt="MongoDB Logo" width="26"/> MongoDB – Windows

- [💾 Hinweise zur Installation unter Windows](#-hinweise-zur-installation-unter-windows)
  - [📁 Anlegen des Datenverzeichnisses](#-anlegen-des-datenverzeichnisses)
  - [🚀 MongoDB starten (Beispiel)](#-mongodb-starten-beispiel)
- [📑 Beispiel `mongod.conf` (Kurz)](#-beispiel-mongodconf-kurz)
- [📑 Parameter-Referenz (Kurz)](#-parameter-referenz-kurz)
  - [🔐 security](#-security)
  - [🌐 net](#-net)
  - [📦 storage](#-storage)
  - [📘 systemLog](#-systemlog)
  - [⚙️ setParameter](#-setparameter)
- [🧩 Hinweise zur sicheren Konfiguration](#-hinweise-zur-sicheren-konfiguration)
- [🧩 Init-Skript (`init_mongodb.bat`)](#-init-skript-init_mongodbbat)
  - [⚙️ Ablauf](#-ablauf)
  - [🎯 Zweck](#-zweck)

---

## 💾 Hinweise zur Installation unter Windows

Installation via **MongoDB Community .msi** vom [Download Center](https://www.mongodb.com/try/download/community?tck=docs_server).  
Standardpfad der Konfiguration: `<Installationsverzeichnis>\bin\mongod.cfg`

### 📁 Anlegen des Datenverzeichnisses

```powershell
cd C:\
md "\data\db"
```

### 🚀 MongoDB starten (Beispiel)

```powershell
"C:\Program Files\MongoDB\Server\8.0\bin\mongod.exe" --dbpath="C:\data\db"
```

Start mit eigener Config:

```powershell
"C:\Program Files\MongoDB\Server\8.0\bin\mongod.exe" --config "C:\DB\mongod.conf"
```

Weitere Infos: [Offizielle MongoDB-Dokumentation – Installation unter Windows](https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-windows/)

---

## 📑 Beispiel `mongod.conf` (Kurz)

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

## 📑 Parameter-Referenz (Kurz)

### 🔐 security

| Option              | Bedeutung                            | Empfehlung |
|---------------------|--------------------------------------|------------|
| `authorization`     | Zugriffskontrolle                    | `enabled` |

### 🌐 net

| Option                   | Beschreibung                      | Empfehlung |
|--------------------------|-----------------------------------|------------|
| `bindIp`                 | Bind-Adresse(n)                   | `127.0.0.1` oder VPN-IP, kein offenes `0.0.0.0` |
| `port`                   | Listener-Port                     | 27017 (Firewall setzen) |
| `maxIncomingConnections` | Max gleichzeitige Verbindungen    | 200 (default) |
| `tls.mode`               | TLS-Modus                         | `requireTLS` für Prod |
| `tls.certificateKeyFile` | Server-Zertifikat + Key           | Pfad zu `.pem` |
| `tls.CAFile`             | Root-CA                           | Pfad setzen, Validierung aktivieren |

Erstellung TLS Zertifikat siehe [README](../../../../README-de.md#-tls-konfiguration)

### 📦 storage

| Option                                | Bedeutung              | Empfehlung |
|---------------------------------------|------------------------|------------|
| `dbPath`                              | Datenverzeichnis       | z. B. `C:\\Program Files\\MongoDB\\Server\\8.0\\data` oder Volume |

### 📘 systemLog

| Option        | Bedeutung                      | Empfehlung |
|---------------|--------------------------------|------------|
| `destination` | Ziel für Logs                  | `file` |
| `path`        | Speicherort                   | z. B. `C:\\Program Files\\MongoDB\\Server\\8.0\\log\\mongod.log` |
| `logAppend`   | An Log anhängen                | `true` |
| `verbosity`   | Detailgrad Log-Dateien         | `0` |

### ⚙️ setParameter

| Parameter                   | Bedeutung                                  | Empfehlung |
|-----------------------------|--------------------------------------------|------------|
| `enableLocalhostAuthBypass` | Admin-Bypass nur von localhost             | `false` in Prod |
| `enableTestCommands`        | Nicht-unterstützte Features aktivieren    | `false` in Prod |

---

## 🧩 Hinweise zur sicheren Konfiguration

- `authorization: enabled` standardmäßig setzen; danach Admin-User anlegen.  
- `bindIp` restriktiv (`127.0.0.1` oder VPN); kein öffentliches `0.0.0.0` ohne Schutz.  
- `tls.mode: requireTLS` mit echten Zertifikaten; CA/Key-Dateien nur für den Dienstbenutzer lesbar.  
- Bei ReplSets `keyFile` oder x.509 Auth nutzen.  
- `enableLocalhostAuthBypass: false`, sobald User existieren.  
- Backups & Restore testen; Journaling aktiv halten.

---

## 🧩 Init-Skript (`init_mongodb.bat`)

Dieses Skript automatisiert die **Erstinitialisierung** einer MongoDB-Instanz unter Windows.

### ⚙️ Ablauf

1. Start ohne Auth, um Admin-User anzulegen.  
2. `init_users.js` ausführen (Benutzer/Rollen).  
3. Temporären Server beenden.  
4. Neu starten mit Auth & Konfig (`mongod.conf`).  
5. Erfolgsmeldung ausgeben.

### 🎯 Zweck

Sichere, reproduzierbare Erstkonfiguration; Benutzer werden nur einmalig ohne Auth erstellt, danach läuft der Server geschützt.

---

© 2025 – Sichere Datenbankkonfigurationen

