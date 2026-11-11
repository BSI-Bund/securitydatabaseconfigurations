@echo off
setlocal DisableDelayedExpansion
REM Apply SQL to the running service. Never launch a second server.
if not defined MARIADB_BIN set "MARIADB_BIN=C:\Program Files\MariaDB 11.8\bin"
if not defined MARIADB_HOST set "MARIADB_HOST=127.0.0.1"
if not defined MARIADB_PORT set "MARIADB_PORT=3306"
if not defined MARIADB_ADMIN set "MARIADB_ADMIN=root"
set "INIT_SQL=%~dp0init_users.sql"
set "MARIADB_CLIENT=%MARIADB_BIN%\mariadb.exe"
if not exist "%MARIADB_CLIENT%" set "MARIADB_CLIENT=%MARIADB_BIN%\mysql.exe"
if not exist "%MARIADB_CLIENT%" goto missing_client
if not exist "%INIT_SQL%" goto missing_sql
echo Replace example passwords in init_users.sql before continuing.
"%MARIADB_CLIENT%" --protocol=TCP --host="%MARIADB_HOST%" --port="%MARIADB_PORT%" --user="%MARIADB_ADMIN%" --password < "%INIT_SQL%"
if errorlevel 1 goto failed
echo MariaDB user initialization completed.
exit /b 0
:missing_client
echo Client not found. Set MARIADB_BIN to the installation's bin directory. 1>&2
exit /b 1
:missing_sql
echo init_users.sql is missing next to this batch file. 1>&2
exit /b 1
:failed
echo Initialization failed. Check the running service, credentials and SQL error. 1>&2
exit /b 1
