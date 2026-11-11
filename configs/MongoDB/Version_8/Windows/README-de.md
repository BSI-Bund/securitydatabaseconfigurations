# MongoDB 8 – Windows

[English](README.md) · [Datenbankübersicht](../../README-de.md) · [BSI-Alignment](../../../README-de.md#bsi-alignment)

Die Vorlage [`mongod.conf`](mongod.conf) betreibt eine einzelne Instanz mit TLS und aktivierter Autorisierung. Für die Einrichtung werden MongoDB Community und separat `mongosh` benötigt: [Installation unter Windows](https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-windows/).

- [Vorbereitung](#vorbereitung)
- [Administrationskonto bei einer neuen Instanz anlegen](#administrationskonto-bei-einer-neuen-instanz-anlegen)
- [Regulärer Start und Anmeldung](#regulärer-start-und-anmeldung)
- [Wirksame Konfiguration prüfen](#wirksame-konfiguration-prüfen)

## Vorbereitung

Alle relativen Pfade beziehen sich auf dieses README-Verzeichnis. Vor einer Ersteinrichtung den vorhandenen MongoDB-Dienst geordnet stoppen und sicherstellen, dass kein anderer Prozess dasselbe Datenverzeichnis verwendet. Ein bestehendes Datenverzeichnis nicht neu initialisieren.

Die Konfiguration verwendet `C:\data\mongodb` für Daten und `C:\data\log` für Logs. In PowerShell anlegen und dem späteren Dienstkonto die benötigten Zugriffsrechte geben:

```powershell
New-Item -ItemType Directory -Force C:\data\mongodb, C:\data\log
```

Nach der [TLS-Anleitung](../../../../docs/TLS-de.md) CA-, Server- und Clientzertifikate erstellen und bereitstellen:

| Datei | Inhalt |
|-------|--------|
| `C:\data\test-ca.pem` | Öffentliches CA-Zertifikat |
| `C:\data\mongo-server1.pem` | Serverschlüssel und Serverzertifikat kombiniert |
| `C:\data\mongo-client.pem` | Clientschlüssel und Clientzertifikat kombiniert |

Der private CA-Schlüssel bleibt außerhalb des Datenbankservers. Die Server-SANs müssen `localhost` beziehungsweise die verwendeten DNS-Namen abdecken. Die Vorlage benötigt auch ein Clientzertifikat; Benutzer-/Passwortauthentifizierung bleibt zusätzlich erforderlich.

Die mitgelieferte Konfiguration bindet ausschließlich an `127.0.0.1` und Port **27018**. Für gewollten Remote-Zugriff Netzwerkfreigaben, TLS-Identitäten und Firewall-Regeln ausdrücklich anpassen.

## Administrationskonto bei einer neuen Instanz anlegen

Die reguläre Konfiguration deaktiviert den Localhost-Authentifizierungs-Bypass. Das erste Administrationskonto muss deshalb vor dem Start mit dieser Konfiguration angelegt werden. Das neue Administrationspasswort wird während der Benutzeranlage zweimal interaktiv abgefragt; im Skript ist kein Passwort hinterlegt.

Für ein neues, noch nicht eingerichtetes Datenverzeichnis einen vorübergehenden Server ausschließlich auf localhost starten. In der ersten PowerShell:

```powershell
& "C:\Program Files\MongoDB\Server\8.0\bin\mongod.exe" --dbpath C:\data\mongodb --logpath C:\data\log\bootstrap.log --bind_ip 127.0.0.1 --port 27017 --noauth
```

In einer zweiten PowerShell im README-Verzeichnis, mit `mongosh` im Suchpfad:

```powershell
.\init_scripts\init_mongodb.bat --bootstrap
```

Nach erfolgreicher Benutzeranlage den temporären Server im ersten Fenster mit `Ctrl+C` geordnet beenden. Der temporäre Bootstrap-Port `27017` unterscheidet sich vom regulären Vorlagen-Port `27018`.

Das Batch-Skript verbindet sich nur mit der vorbereiteten Instanz und startet oder beendet keine Prozesse. `init_users.js` prüft vor der Benutzeranlage den erwarteten Datenpfad, reine Loopback-Bindung, deaktivierte Autorisierung und das Fehlen vorhandener Administrationsnutzer. Bei abweichenden Pfaden oder Ports `MONGO_BOOTSTRAP_DBPATH` und `MONGO_BOOTSTRAP_PORT` setzen; ohne `--bootstrap` wird der Aufruf abgelehnt. `mongosh` muss im Suchpfad liegen oder über `MONGOSH_EXE` als vollständiger Programmpfad angegeben werden. Fehler führen zu einem Exitcode ungleich null.

## Regulärer Start und Anmeldung

In PowerShell aus diesem README-Verzeichnis:

```powershell
& "C:\Program Files\MongoDB\Server\8.0\bin\mongod.exe" --config .\mongod.conf
```

Für dauerhaften Dienstbetrieb die Konfiguration beim tatsächlichen Windows-Dienst hinterlegen und mit `sc.exe qc MongoDB` prüfen. Dienst und manuellen Prozess nicht gleichzeitig für dasselbe Datenverzeichnis starten.

In einer zweiten PowerShell:

```powershell
mongosh --host localhost --port 27018 --tls --tlsCAFile C:\data\test-ca.pem --tlsCertificateKeyFile C:\data\mongo-client.pem --username admin --authenticationDatabase admin --password
```

Das Passwort wird interaktiv abgefragt. Das Skript erzeugt nur ein Root-Administrationskonto; Anwendungskonten mit begrenzten Rollen separat anlegen.

## Wirksame Konfiguration prüfen

In einer administrativen `mongosh`-Sitzung `db.adminCommand({ getCmdLineOpts: 1 })` sowie `db.runCommand({ connectionStatus: 1 })` prüfen. Datenbanklogs liegen gemäß der Vorlage unter `C:\data\log\mongod.log`.

Die mitgelieferte Datei enthält:

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

Backups, Aufbewahrung und Restore-Tests sind separat einzurichten. Diese Anleitung beschreibt keine Replikation oder Hochverfügbarkeit.
