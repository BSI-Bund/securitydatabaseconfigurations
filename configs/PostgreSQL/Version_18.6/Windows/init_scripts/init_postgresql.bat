@echo off
setlocal DisableDelayedExpansion
REM Apply SQL to the existing service without restarting or reconfiguring it.
if not defined POSTGRES_BIN set "POSTGRES_BIN=C:\Program Files\PostgreSQL\18\bin"
if not defined PGHOST set "PGHOST=127.0.0.1"
if not defined PGPORT set "PGPORT=5432"
if not defined PGUSER set "PGUSER=postgres"
set "INIT_SQL=%~dp0init_users.sql"
if not exist "%POSTGRES_BIN%\psql.exe" goto missing_client
if not exist "%INIT_SQL%" goto missing_sql
echo Replace example passwords in init_users.sql before continuing.
"%POSTGRES_BIN%\psql.exe" -v ON_ERROR_STOP=1 -U "%PGUSER%" -d postgres -f "%INIT_SQL%" -c "SHOW config_file;" -c "SHOW hba_file;" -c "SHOW password_encryption;"
if errorlevel 1 goto failed
echo PostgreSQL user initialization completed.
exit /b 0
:missing_client
echo psql.exe not found. Set POSTGRES_BIN to the installation's bin directory. 1>&2
exit /b 1
:missing_sql
echo init_users.sql is missing next to this batch file. 1>&2
exit /b 1
:failed
echo Initialization failed. Check the running service, credentials and SQL error. 1>&2
exit /b 1
