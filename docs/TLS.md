# TLS certificates for the database templates

[Deutsch](TLS-de.md) · [Project overview](../README.md)

This guide describes a local OpenSSL example for CA, server, and client certificates. Integrate them into each DBMS using its own guide afterwards. Other environments can use existing certificates from their PKI.

- [Prerequisites and working directory](#prerequisites-and-working-directory)
- [1. Create the CA](#1-create-the-ca)
- [2. Create the server certificate](#2-create-the-server-certificate)
- [3. Create a client certificate if required](#3-create-a-client-certificate-if-required)
- [4. Verify certificates](#4-verify-certificates)
- [5. Prepare files for the respective DBMS](#5-prepare-files-for-the-respective-dbms)
- [References](#references)

## Prerequisites and working directory

Install OpenSSL with support for `req -addext`. The single-line OpenSSL commands work in a POSIX shell and PowerShell. Save the `.cnf` contents as text files in the same working directory.

Use a separate directory with restricted access outside the repository. Keep the CA key there; do not mount it into containers or copy it to database servers. `ca.key` is password-protected. Server and client keys are unencrypted for service use and require restrictive file permissions or Windows ACLs.

## 1. Create the CA

```sh
openssl genrsa -aes256 -out ca.key 4096
openssl req -x509 -new -key ca.key -sha256 -days 365 -out ca.crt -subj "/CN=Database Example CA" -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign"
```

The CA passphrase is requested interactively. Output: `ca.key` and `ca.crt`.

## 2. Create the server certificate

Save the following as `server-ext.cnf`. SAN entries must cover the actual DNS names and IP addresses used by clients; `db-server`, `localhost`, and `127.0.0.1` are examples.

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

Output: `server.key` and `server.crt`. Clients must trust the CA certificate and verify the server name they use.

## 3. Create a client certificate if required

The MongoDB templates in this repository also require a client certificate with their unchanged TLS configuration. For the other DBMSs, its use depends on the selected authentication method.

Save `client-ext.cnf`:

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

Output: `client.key` and `client.crt`. The example CN `db-client` does not automatically create a database role. Configure certificate verification and database authentication separately.

## 4. Verify certificates

```sh
openssl verify -CAfile ca.crt -purpose sslserver -verify_hostname localhost server.crt
openssl verify -CAfile ca.crt -purpose sslclient client.crt
openssl x509 -in server.crt -noout -text
openssl x509 -in client.crt -noout -text
```

Replace `localhost` in the verification command when connecting through another DNS name. For an IP address, use `-verify_ip` instead of `-verify_hostname`. Inspect the expected SAN entries and `serverAuth` or `clientAuth` usage.

## 5. Prepare files for the respective DBMS

| DBMS | Required format | Integration |
|------|-----------------|-------------|
| MariaDB and MySQL | Separate PEM files for the CA, server certificate, and server key | Use the filenames configured in `ssl-ca`, `ssl-cert`, and `ssl-key`; check container mounts and read permissions |
| PostgreSQL | `ca.crt`, `server.crt`, `server.key` | Follow the platform TLS guide; the Linux template also includes its own local certificate generator |
| MongoDB | Separate CA; server key and certificate combined in one PEM file; client PEM likewise | Linux and Windows guides specify filenames and destination paths |
| Redis Enterprise | Certificates according to the Redis Enterprise administration model | Integrate through the documented administration tools |
| Weaviate with Traefik | Certificate and key covering the proxy domain names | Follow the [Traefik guide](../configs/Weaviate/Version_1.34/reverse-proxy-traefik/README.md) |

For MongoDB, combine files in this order:

POSIX shell:

```sh
cat server.key server.crt > server.pem
cat client.key client.crt > client.pem
```

PowerShell through `cmd.exe`:

```powershell
cmd /c copy /b server.key+server.crt server.pem
cmd /c copy /b client.key+client.crt client.pem
```

Copy only the required certificates and keys into their destination directories. Adjust filenames to match the configuration; the CA key `ca.key` is not needed there. Enable TLS in the DBMS and test an actual client connection with CA and hostname verification.

## References

- [OpenSSL: req and X.509 extensions](https://docs.openssl.org/3.0/man1/openssl-req/)
- [OpenSSL: certificate verification](https://docs.openssl.org/3.0/man1/openssl-verification-options/)
- [MongoDB: TLS configuration](https://www.mongodb.com/docs/manual/tutorial/configure-ssl/)
- [PostgreSQL 18: TLS](https://www.postgresql.org/docs/18/ssl-tcp.html)
