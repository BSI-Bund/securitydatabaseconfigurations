# 🛡️ Sichere Datenbank-Konfigurationen

- [📘 Inhalt](#-inhalt)
- [🎯 Zielgruppe](#-zielgruppe)
- [📘 Sicherheitsziele](#-sicherheitsziele)
  - [🌐 Verschlüsselte Netzwerkkonfiguration (TLS/SSL)](#-verschlüsselte-netzwerkkonfiguration-tlsssl)
  - [🧾 Protokollierung](#-protokollierung)
  - [💾 Speicherkonfiguration](#-speicherkonfiguration)
  - [♻️ Backups](#️-backups)
  - [👤 Sichere Authentifizierung & Benutzerrechte](#-sichere-authentifizierung--benutzerrechte)
  - [🧱 Updates & Wartung](#-updates--wartung)
- [📁 Repository-Struktur](#-repository-struktur)
- [🛠️ Unterstützte Datenbanken](#️-unterstützte-datenbanken)
- [⚙️ Installation & Nutzung](#️-installation--nutzung)
- [🔒 TLS-Konfiguration](#-tls-konfiguration)
- [⚠️ Haftungsausschluss](#️-haftungsausschluss)


---

## 📘 Inhalt

Dieses Repository stellt **sichere Konfigurationen für verschiedene Datenbanksysteme** bereit.  
Zusätzlich sind Skripte zur **Initialisierung der Datenbanken** sowie Hinweise zu **Tools zur Absicherung** enthalten.  
Die Bereitstellung der Datenbanksysteme erfolgt für:

- 🐧 **Linux mit Docker Compose** → für containerisierte, automatisierte Setups  
- 🪟 **Windows ohne Docker** → für lokale, manuelle Installationen (z. B. Entwicklungsumgebungen)

---

## 🎯 Zielgruppe

Dieses Repository richtet sich an:
- IT-Administratoren
- Datenbank-Administratoren
- Entwickler:innen mit Fokus auf sichere Datenbank-Betriebskonzepte

---

## 📘 Sicherheitsziele

Ziel ist die Bereitstellung reproduzierbarer, sicherer Datenbank-Setups, welche die folgenden Sicherheitsaspekte abdecken:

### 🌐 Verschlüsselte Netzwerkkonfiguration (TLS/SSL)
- Nutzung verschlüsselter Kommunikation (TLS/SSL)
- Einschränkung des Zugriffs auf vertrauenswürdige Netzwerke oder Hosts

### 🧾 Protokollierung
- Aktivierung aussagekräftiger Logs zur **Nachvollziehbarkeit von Aktivitäten**
- Logging von fehlerhaften oder auffälligen Zugriffen

### 💾 Speicherkonfiguration
- Sichere Festlegung des Speicherorts der Datenbankdateien
- Verwendung restriktiver Zugriffsrechte auf Daten- und Log-Verzeichnisse

### ♻️ Backups
- Automatisierte, regelmäßige Backups mit Verschlüsselung
- Prüfung der Wiederherstellbarkeit (Restore-Tests)

### 👤 Sichere Authentifizierung & Benutzerrechte
- Verwendung **rollenbasierter Zugriffskontrolle (RBAC)**
- Minimale Berechtigungen nach dem **Least-Privilege-Prinzip**

Folgendes ist im laufenden Betrieb auszuführen:

### 🧱 Updates & Wartung
- Regelmäßige Einspielung von **Security-Updates**
- Überwachung der Datenbank-Logs auf Sicherheitsvorfälle

---

## 📁 Repository-Struktur

Die verschiedenen DBMS haben in der Regel folgende Struktur:
```bash
Datenbanksystem/                                # Bezeichnung des DBMS
└── Version_X/                                  # Versionsnummer
    ├── Linux/                                  # Docker-Compose-Umgebung (Container, .env, Volumes, Init-Skripte)
    │   ├── compose/                            # Docker Compose Konfiguration
    |   |   ├── init_db/                        # Sammlung von Skripten zum Initialisieren des DBMS
    |   |   ├── .env.default                    # Vorlage-Datei für Umgebungsvariablen (z. B. Benutzername, Port, Passwort)
    |   |   └── docker-compose.yml              # Docker Compose Datei
    │   ├── config_description-linux.md         # Beschreibung der sicherheitsrelevanten Einstellungen und deren Zweck
    |   └── *Konfigurationsdatei*               # Konfigurationsdatei des jeweiligen DBMS
    └── Windows/                                # Klassische Konfiguration für lokale Installation unter Windows
        ├── init_scripts/                       # Skripte zur Datenbankinitialisierung
        ├── config_description-windows.md       # Beschreibung der sicherheitsrelevanten Einstellungen und deren Zweck
        └── *Konfigurationsdatei*               # Konfigurationsdatei des jeweilligen DBMS
```
---

## 🛠️ Unterstützte Datenbanken

✅ MariaDB  
✅ MongoDB  
✅ MySQL  
✅ Weaviate  

Bald verfügbar:

➡️ PostgreSQL  
➡️ Redis  

---

## ⚙️ Installation & Nutzung

1. Wähle eine passende Konfigurationsdatei aus dem Ordner `configs/`.  
2. Passe die Datei an deine Umgebung und Sicherheitsanforderungen an.  
3. Wende die Konfiguration auf deine Datenbank an.  
4. Teste die Erreichbarkeit, Authentifizierung und Backup-Funktion.

---

## 🔒 TLS-Konfiguration

Diese Anleitung beschreibt, wie man unter Windows mit OpenSSL eine eigene **Certificate Authority (CA)** erstellt und damit **Server- und Client-Zertifikate** für z.B. MongoDB erzeugt.

---

### ⚙️ Voraussetzungen

* Installiertes [OpenSSL für Windows](https://slproweb.com/products/Win32OpenSSL.html)
* Schreibrechte im gewünschten Zertifikatsverzeichnis (z. B. `C:\data`)
* Pfad zur `openssl.cnf` Konfigurationsdatei (z. B. `C:\Users\<User>\openssl-3.5.3\apps\openssl.cnf`)

---

### 🏗️ 1. CA erstellen

```powershell
# CA-Key erzeugen
openssl genrsa -out test-ca.key 4096

# CA-Zertifikat erstellen
openssl req -x509 -new -nodes -key test-ca.key -sha256 -days 365 -out test-ca.pem -config "C:\Users\<User>\openssl-3.5.3\apps\openssl.cnf"
```

Ergebnis:

* `test-ca.key` → privater Schlüssel der CA
* `test-ca.pem` → selbstsigniertes CA-Zertifikat

---

### 🖥️ 2. Server-Zertifikat erstellen und signieren

```powershell
# Server-Key erzeugen
openssl genrsa -out mongo-server1.key 4096

# Certificate Signing Request (CSR) erzeugen
openssl req -new -key mongo-server1.key -out mongo-server1.csr -config "C:\Users\<User>\openssl-3.5.3\apps\openssl.cnf"

# CSR mit der CA signieren
openssl x509 -req -in mongo-server1.csr -CA test-ca.pem -CAkey test-ca.key -CAcreateserial -out mongo-server1.crt -days 365 -sha256

# PEM-Datei für MongoDB erstellen (Key + Zertifikat zusammenführen)
copy /b mongo-server1.key+mongo-server1.crt mongo-server1.pem
```

Ergebnis:

* `mongo-server1.pem` → vom Server verwendetes Zertifikat (enthält Key + CRT)

---

### 👤 3. Client-Zertifikat erstellen und signieren

```powershell
# Client-Key und CSR erzeugen
openssl genrsa -out mongo-client.key 4096
openssl req -new -key mongo-client.key -out mongo-client.csr -config "C:\Users\<User>\openssl-3.5.3\apps\openssl.cnf"

# CSR mit der CA signieren
openssl x509 -req -in mongo-client.csr -CA C:\data\test-ca.pem -CAkey C:\data\test-ca.key -CAcreateserial -out mongo-client.crt -days 365 -sha256

# PEM-Datei für den Client erstellen (Key + Zertifikat zusammenführen)
copy /b mongo-client.key+mongo-client.crt mongo-client.pem
```

Ergebnis:

* `mongo-client.pem` → vom Client verwendetes Zertifikat (enthält Key + CRT)

---

### ⚡ 4. MongoDB TLS-Konfiguration

#### 🧩 `mongod.conf` Beispiel

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

### 📋 Zusammenfassung

* **CA erstellt** (`test-ca.pem`, `test-ca.key`)
* **Server-Zertifikat erzeugt und signiert** (`mongo-server1.pem`)
* **Client-Zertifikat erzeugt und signiert** (`mongo-client.pem`)
* **MongoDB TLS aktiviert** über `mongod.conf`

---

## ⚠️ Haftungsausschluss

Diese Dateien dienen als **allgemeine Sicherheitsleitfäden**.  
Vor der Verwendung in einer Produktionsumgebung müssen sie sorgfältig geprüft und an die jeweiligen **betriebsinternen Anforderungen** angepasst werden.

---

© 2025 – Sichere Datenbankkonfigurationen
