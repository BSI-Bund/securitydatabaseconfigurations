# MongoDB 8 – Linux mit Docker Compose

[English](README.md) · [Datenbankübersicht](../../README-de.md) · [BSI-Alignment](../../../README-de.md#bsi-alignment)

Diese Vorlage betreibt eine einzelne MongoDB-Instanz. Die Dateien sind [`mongod.conf`](mongod.conf) und [`mongodb-compose/docker-compose.yml`](mongodb-compose/docker-compose.yml). Der Image-Tag `mongo:8-noble` ist beweglich und legt keine konkrete Patchversion fest.

- [Vorbereitung](#vorbereitung)
- [Start und Initialisierung](#start-und-initialisierung)
- [Anmeldung und Prüfung](#anmeldung-und-prüfung)
- [Konfiguration und Logs](#konfiguration-und-logs)
- [Betrieb](#betrieb)
- [Referenzen](#referenzen)

## Vorbereitung

Docker mit Compose, OpenSSL für das Zertifikatsbeispiel und `mongosh` auf dem Client werden benötigt. Alle folgenden Compose-Befehle laufen im Ordner `mongodb-compose/`. Ausgehend von diesem README-Verzeichnis:

```bash
cd mongodb-compose
cp .env.example .env
mkdir -p ssl
```

1. Alle Beispiel-Secrets in `.env` ersetzen. `MONGO_USER` und `MONGO_PASSWORD` werden als `MONGO_INITDB_ROOT_USERNAME` und `MONGO_INITDB_ROOT_PASSWORD` übergeben: Dieses Konto besitzt **Root-Rechte in `admin`**, auch wenn der Beispielname `appuser` lautet.
2. Nach der [TLS-Anleitung](../../../../docs/TLS-de.md) CA-, Server- und Clientzertifikat erstellen. Die Server-SANs müssen `localhost` sowie gegebenenfalls den tatsächlich verwendeten Container-/DNS-Namen abdecken.
3. Die folgenden Dateien in `mongodb-compose/ssl/` bereitstellen:

| Datei | Inhalt und Verwendung |
|-------|-----------------------|
| `test-ca.pem` | Öffentliches CA-Zertifikat; wird in den Server gemountet |
| `test-server1.pem` | Serverschlüssel und Serverzertifikat kombiniert; wird in den Server gemountet |
| `client.pem` | Clientschlüssel und Clientzertifikat kombiniert; nur für den Client |

4. Die Zertifikatsquelle `ssl/` und das Log-Volume `mongo_logs` sind bereits eingebunden. Das Startskript legt das Logverzeichnis mit passenden Rechten an und kopiert ausschließlich die beiden benötigten Server-PEM-Dateien in ein privates tmpfs-Verzeichnis unter `/etc/ssl/mongodb`. Die Dateien erhalten Eigentümer `mongodb` und Modus `0600`; der Clientschlüssel bleibt auf dem Client.
5. `docker compose config --quiet` ausführen und die aufgelöste Konfiguration prüfen.

Die Vorlage erzwingt TLS. Da `allowConnectionsWithoutCertificates` nicht aktiviert ist, benötigt der Client außerdem das von derselben vertrauenswürdigen CA signierte Clientzertifikat. Dieses ersetzt nicht die Anmeldung mit Benutzer und Passwort.

## Start und Initialisierung

```bash
docker compose up -d
docker compose ps
docker compose logs --tail 100 mongodb
```

Der Host-Port ist ausschließlich `127.0.0.1:27017`. `bindIp: 0.0.0.0` gilt innerhalb des Containers. Das persistente Datenverzeichnis ist `/data/db`, entsprechend dem Volume `mongo`.

Beim ersten Start mit leerem Volume legt der Image-Entrypoint das Administrationskonto an. `MONGO_DATABASE` wählt eine Initialisierungsdatenbank; ohne entsprechende Schreiboperationen oder Init-Skripte erzeugt diese Variable allein keine befüllte Anwendungsdatenbank. Änderungen an `.env` ändern keine Konten in einem bereits initialisierten Volume.

## Anmeldung und Prüfung

Auf dem Host im Ordner `mongodb-compose/` ausführen. Den Benutzernamen an `MONGO_USER` anpassen; das Passwort wird interaktiv abgefragt:

```bash
mongosh --host localhost --port 27017 --tls --tlsCAFile ssl/test-ca.pem --tlsCertificateKeyFile ssl/client.pem --username appuser --authenticationDatabase admin --password
```

In der administrativen Sitzung:

```javascript
db.adminCommand({ getCmdLineOpts: 1 })
db.runCommand({ connectionStatus: 1 })
```

Für die Anwendung anschließend ein eigenes Konto mit auf deren Datenbank begrenzten Rollen anlegen. Das Bootstrap-Root-Konto nicht als reguläres Anwendungskonto verwenden.

## Konfiguration und Logs

Die mitgelieferte `mongod.conf` enthält:

```yaml
# System logging
systemLog:
  destination: file
  path: /var/log/mongodb/mongod.log
  logAppend: true
  verbosity: 0

# Storage options
storage:
  dbPath: /data/db

# Network options
net:
  bindIp: 0.0.0.0
  port: 27017
  maxIncomingConnections: 200
  tls:
    mode: requireTLS
    certificateKeyFile: /etc/ssl/mongodb/test-server1.pem
    CAFile: /etc/ssl/mongodb/test-ca.pem

# Security options
security:
  authorization: enabled

# Parameters
setParameter:
  enableLocalhostAuthBypass: false
```

`maxIncomingConnections: 200` und `verbosity: 0` sind die Werte dieser Vorlage. Die Compose-Kommandozeile überschreibt die Log-Detailstufe nicht.

Nach der Initialisierung schreibt MongoDB in die konfigurierte Logdatei. `docker compose logs` zeigt daher nicht sämtliche Datenbankereignisse. Beispiel:

```bash
docker compose exec mongodb tail -n 100 /var/log/mongodb/mongod.log
```

## Betrieb

```bash
docker compose stop
docker compose start
docker compose down
```

`down` lässt das Daten-Volume bestehen. Backups und Restore-Tests sind separat einzurichten. Diese Vorlage enthält keinen Replica-Set- oder Hochverfügbarkeitsaufbau.

## Referenzen

- [MongoDB Docker-Image und Initialisierung](https://hub.docker.com/_/mongo)
- [MongoDB: TLS-Konfiguration und Clientzertifikate](https://www.mongodb.com/docs/manual/tutorial/configure-ssl/)
