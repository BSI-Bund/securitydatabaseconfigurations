@echo off
setlocal

echo === Starting PostgreSQL initialization ===

REM === Adjust paths/variables ===
set POSTGRES_BIN="C:\Program Files\PostgreSQL\18\bin"
set CONFIG_FILE="C:\Program Files\PostgreSQL\18\data\postgresql.conf"
set INIT_SQL="C:\Projekte\PostgreSQL\Version_18.6\Windows\init_scripts\init_users.sql"
set PGUSER=postgres
set PGPASSWORD=ChangeMe!Root123

echo [1/4] Stopping service...
net stop postgresql-x64-18
timeout /t 2 >nul

echo [2/4] Starting service...
net start postgresql-x64-18
timeout /t 5 >nul

echo [3/4] Running initialization script...
%POSTGRES_BIN%\psql.exe -v ON_ERROR_STOP=1 -U %PGUSER% -d postgres -f %INIT_SQL%

echo [4/4] Checking configuration...
%POSTGRES_BIN%\psql.exe -U %PGUSER% -d appdb -c "SHOW config_file;" -c "SHOW hba_file;" -c "SHOW password_encryption;"

echo Done! PostgreSQL initialization complete.
endlocal
pause
