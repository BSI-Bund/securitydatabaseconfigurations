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
✅ Redis 

Bald verfügbar:

➡️ Neo4j
➡️ PostgreSQL 

---

## ⚙️ Installation & Nutzung

1. Wähle eine passende Konfigurationsdatei aus dem Ordner `configs/`.  
2. Passe die Datei an deine Umgebung und Sicherheitsanforderungen an.  
3. Wende die Konfiguration auf deine Datenbank an.  
4. Teste die Erreichbarkeit, Authentifizierung und Backup-Funktion.

---

## 🔒 TLS-Konfiguration

Diese Anleitung beschreibt, wie man unter Windows mit OpenSSL eine eigene **Certificate Authority (CA)** erstellt und damit **Server- und Client-Zertifikate** für z. B. MongoDB erzeugt. Die verwendeten X.509-Erweiterungen werden explizit definiert, damit die erzeugten Zertifikate unabhängig von lokalen OpenSSL-Standardwerten nachvollziehbar und reproduzierbar bleiben.

---

### ⚙️ Voraussetzungen

* Installiertes [OpenSSL für Windows](https://slproweb.com/products/Win32OpenSSL.html)
* Schreibrechte im gewünschten Zertifikatsverzeichnis (z. B. `C:\data`)
* Die Beispielwerte für DNS-Namen und IP-Adressen müssen an die eigene Umgebung angepasst werden

> [!IMPORTANT]
> Die privaten Schlüssel müssen mit restriktiven Dateiberechtigungen geschützt werden. Der CA-Schlüssel wird in diesem Beispiel mit AES-256 verschlüsselt. Server- und Client-Schlüssel bleiben für die automatisierte Verwendung durch Dienste unverschlüsselt und müssen entsprechend über Dateiberechtigungen geschützt werden.

---

### 🏗️ 1. CA erstellen

```powershell
# Verschlüsselten CA-Key erzeugen
openssl genrsa -aes256 -out test-ca.key 4096

# CA-Zertifikat mit expliziten CA-Erweiterungen erstellen
openssl req -x509 -new -key test-ca.key -sha256 -days 365 -out test-ca.pem -subj "/CN=MongoDB Test CA" -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign"
```

Ergebnis:

* `test-ca.key` → AES-256-verschlüsselter privater Schlüssel der CA
* `test-ca.pem` → selbstsigniertes CA-Zertifikat mit expliziten CA-Eigenschaften

---

### 🖥️ 2. Server-Zertifikat erstellen und signieren

```powershell
# Server-Key erzeugen
openssl genrsa -out mongo-server1.key 4096

# Certificate Signing Request (CSR) erzeugen
openssl req -new -key mongo-server1.key -out mongo-server1.csr -subj "/CN=mongo-server1"

# X.509-Erweiterungen für das Server-Zertifikat definieren
@"
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:mongo-server1,DNS:localhost,IP:127.0.0.1
"@ | Set-Content -Encoding ascii server-ext.cnf

# CSR mit der CA und den expliziten Server-Erweiterungen signieren
openssl x509 -req -in mongo-server1.csr -CA test-ca.pem -CAkey test-ca.key -CAcreateserial -out mongo-server1.crt -days 365 -sha256 -extfile server-ext.cnf

# PEM-Datei für MongoDB erstellen (Key + Zertifikat zusammenführen)
cmd /c copy /b mongo-server1.key+mongo-server1.crt mongo-server1.pem
```

> [!NOTE]
> Die Werte in `subjectAltName` müssen den DNS-Namen beziehungsweise IP-Adressen entsprechen, über die Clients den MongoDB-Server tatsächlich erreichen. Bei einer Identitätsprüfung des Zertifikats werden diese Werte zur Host-Verifikation verwendet.

Ergebnis:

* `mongo-server1.pem` → vom Server verwendetes Zertifikat inklusive privatem Schlüssel und Zertifikat
* `server-ext.cnf` → explizite X.509-Erweiterungen für das Server-Zertifikat

---

### 👤 3. Client-Zertifikat erstellen und signieren

```powershell
# Client-Key erzeugen
openssl genrsa -out mongo-client.key 4096

# Certificate Signing Request (CSR) erzeugen
openssl req -new -key mongo-client.key -out mongo-client.csr -subj "/CN=mongo-client"

# X.509-Erweiterungen für das Client-Zertifikat definieren
@"
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=clientAuth
"@ | Set-Content -Encoding ascii client-ext.cnf

# CSR mit der CA und den expliziten Client-Erweiterungen signieren
openssl x509 -req -in mongo-client.csr -CA test-ca.pem -CAkey test-ca.key -CAcreateserial -out mongo-client.crt -days 365 -sha256 -extfile client-ext.cnf

# PEM-Datei für den Client erstellen (Key + Zertifikat zusammenführen)
cmd /c copy /b mongo-client.key+mongo-client.crt mongo-client.pem
```

Ergebnis:

* `mongo-client.pem` → vom Client verwendetes Zertifikat inklusive privatem Schlüssel und Zertifikat
* `client-ext.cnf` → explizite X.509-Erweiterungen für das Client-Zertifikat

---

### 🔍 4. Zertifikate prüfen

Vor der Verwendung sollten die erzeugten Zertifikate und ihre Erweiterungen geprüft werden:

```powershell
openssl x509 -in test-ca.pem -noout -text
openssl x509 -in mongo-server1.crt -noout -text
openssl x509 -in mongo-client.crt -noout -text
```

Für das Server-Zertifikat sollten insbesondere `CA:FALSE`, `TLS Web Server Authentication` und die erwarteten Subject Alternative Names sichtbar sein. Beim Client-Zertifikat sollte `TLS Web Client Authentication` gesetzt sein.

---

### ⚡ 5. MongoDB TLS-Konfiguration

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

* **Verschlüsselter CA-Schlüssel und CA-Zertifikat erstellt** (`test-ca.key`, `test-ca.pem`)
* **Server-Zertifikat mit explizitem SAN und `serverAuth` erzeugt** (`mongo-server1.pem`)
* **Client-Zertifikat mit explizitem `clientAuth` erzeugt** (`mongo-client.pem`)
* **X.509-Erweiterungen vor der Verwendung überprüfbar**
* **MongoDB TLS aktiviert** über `mongod.conf`

---

## ⚠️ Haftungsausschluss

Diese Dateien dienen als **allgemeine Sicherheitsleitfäden**.  
Vor der Verwendung in einer Produktionsumgebung müssen sie sorgfältig geprüft und an die jeweiligen **betriebsinternen Anforderungen** angepasst werden.

---

© 2025 – Sichere Datenbankkonfigurationen
