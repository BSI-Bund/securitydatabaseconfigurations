# TLS-Zertifikate für die Datenbankvorlagen

[English](TLS.md) · [Projektübersicht](../README-de.md)

Diese Anleitung beschreibt ein lokales Beispiel mit OpenSSL für CA-, Server- und Client-Zertifikate. Die Einbindung in das jeweilige DBMS erfolgt anschließend nach dessen Anleitung. Für andere Umgebungen können vorhandene Zertifikate der eigenen PKI verwendet werden.

- [Voraussetzungen und Arbeitsverzeichnis](#voraussetzungen-und-arbeitsverzeichnis)
- [1. CA erstellen](#1-ca-erstellen)
- [2. Serverzertifikat erstellen](#2-serverzertifikat-erstellen)
- [3. Clientzertifikat erstellen, falls benötigt](#3-clientzertifikat-erstellen-falls-benötigt)
- [4. Zertifikate prüfen](#4-zertifikate-prüfen)
- [5. Dateien für das jeweilige DBMS bereitstellen](#5-dateien-für-das-jeweilige-dbms-bereitstellen)
- [Referenzen](#referenzen)

## Voraussetzungen und Arbeitsverzeichnis

OpenSSL mit Unterstützung für `req -addext` muss installiert sein. Die einzeiligen OpenSSL-Befehle funktionieren in einer POSIX-Shell und in PowerShell. Die Inhalte der `.cnf`-Dateien werden als Textdateien im selben Arbeitsverzeichnis gespeichert.

Ein separates, zugriffsgeschütztes Arbeitsverzeichnis außerhalb des Repositorys verwenden. Die CA-Schlüsseldatei bleibt dort und wird weder in Container gemountet noch auf Datenbankserver kopiert. `ca.key` ist passwortgeschützt; die Server- und Client-Schlüssel sind für den Dienstbetrieb unverschlüsselt und benötigen restriktive Dateirechte beziehungsweise Windows-ACLs.

## 1. CA erstellen

```sh
openssl genrsa -aes256 -out ca.key 4096
openssl req -x509 -new -key ca.key -sha256 -days 365 -out ca.crt -subj "/CN=Database Example CA" -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign"
```

Die Passphrase der CA wird interaktiv abgefragt. Ergebnis: `ca.key` und `ca.crt`.

## 2. Serverzertifikat erstellen

Die Datei `server-ext.cnf` mit folgendem Inhalt speichern. Die SAN-Einträge müssen die tatsächlich verwendeten DNS-Namen und IP-Adressen abdecken; `db-server`, `localhost` und `127.0.0.1` sind Beispielwerte.

```ini
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:db-server,DNS:localhost,IP:127.0.0.1
```

```sh
openssl genrsa -out server.key 4096
openssl req -new -key server.key -out server.csr -subj "/CN=db-server"
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 365 -sha256 -extfile server-ext.cnf
```

Ergebnis: `server.key` und `server.crt`. Der Client muss dem CA-Zertifikat vertrauen und den verwendeten Servernamen prüfen.

## 3. Clientzertifikat erstellen, falls benötigt

Die MongoDB-Vorlagen in diesem Repository verlangen bei unveränderter TLS-Konfiguration auch ein Clientzertifikat. Bei den anderen DBMS hängt dessen Verwendung von der gewählten Authentifizierung ab.

Die Datei `client-ext.cnf` speichern:

```ini
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=clientAuth
```

```sh
openssl genrsa -out client.key 4096
openssl req -new -key client.key -out client.csr -subj "/CN=db-client"
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAserial ca.srl -out client.crt -days 365 -sha256 -extfile client-ext.cnf
```

Ergebnis: `client.key` und `client.crt`. Der Beispiel-CN `db-client` ist keine automatisch angelegte Datenbankrolle. Zertifikatsprüfung und Datenbankanmeldung sind getrennt zu konfigurieren.

## 4. Zertifikate prüfen

```sh
openssl verify -CAfile ca.crt -purpose sslserver -verify_hostname localhost server.crt
openssl verify -CAfile ca.crt -purpose sslclient client.crt
openssl x509 -in server.crt -noout -text
openssl x509 -in client.crt -noout -text
```

Bei Verbindungen über einen anderen DNS-Namen `localhost` im Prüfbefehl durch diesen Namen ersetzen. Für eine IP-Adresse `-verify_ip` statt `-verify_hostname` verwenden. Die Ausgaben müssen die erwarteten SAN-Einträge sowie `serverAuth` beziehungsweise `clientAuth` zeigen.

## 5. Dateien für das jeweilige DBMS bereitstellen

| DBMS | Benötigtes Format | Einbindung |
|------|-------------------|------------|
| MariaDB und MySQL | CA, Serverzertifikat und Serverschlüssel als getrennte PEM-Dateien | Unter den in `ssl-ca`, `ssl-cert` und `ssl-key` genannten Namen bereitstellen; Container-Mount und Leserechte prüfen |
| PostgreSQL | `ca.crt`, `server.crt`, `server.key` | Nach der jeweiligen TLS-Anleitung einbinden; die Linux-Vorlage enthält auch einen eigenen lokalen Zertifikatsgenerator |
| MongoDB | CA separat; Serverschlüssel und Serverzertifikat gemeinsam in einer PEM-Datei; ebenso Client-PEM | Dateinamen und Zielpfade stehen in den Linux-/Windows-Anleitungen |
| Redis Enterprise | Zertifikate nach dem Verwaltungsmodell von Redis Enterprise | Über die dokumentierten Verwaltungswerkzeuge einbinden |
| Weaviate mit Traefik | Zertifikat und Schlüssel für die Proxy-Domainnamen | Nach der [Traefik-Anleitung](../configs/Weaviate/Version_1.34/reverse-proxy-traefik/README-de.md) bereitstellen |

Für MongoDB werden die Dateien in dieser Reihenfolge kombiniert:

POSIX-Shell:

```sh
cat server.key server.crt > server.pem
cat client.key client.crt > client.pem
```

PowerShell über `cmd.exe`:

```powershell
cmd /c copy /b server.key+server.crt server.pem
cmd /c copy /b client.key+client.crt client.pem
```

Nur die benötigten Zertifikate und Schlüssel in die Zielverzeichnisse kopieren. Dateinamen gegebenenfalls an die Konfiguration anpassen; die CA-Schlüsseldatei `ca.key` wird nicht benötigt. Danach TLS im DBMS aktivieren und eine echte Client-Verbindung mit CA- und Namensprüfung testen.

## Referenzen

- [OpenSSL: req und X.509-Erweiterungen](https://docs.openssl.org/3.0/man1/openssl-req/)
- [OpenSSL: Zertifikatsprüfung](https://docs.openssl.org/3.0/man1/openssl-verification-options/)
- [MongoDB: TLS-Konfiguration](https://www.mongodb.com/docs/manual/tutorial/configure-ssl/)
- [PostgreSQL 18: TLS](https://www.postgresql.org/docs/18/ssl-tcp.html)
