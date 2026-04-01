@echo off
setlocal

echo === Starting MariaDB initialization ===

REM === Adjust paths/variables ===
set MARIADB_BIN="C:\Program Files\MariaDB 11.8\bin"
set CONFIG_FILE="C:\Projekte\MariaDB\Version_11,8\Windows\my.ini"
set INIT_SQL="C:\Projekte\MariaDB\Version_11.8\Windows\init_users.sql"
set ROOT_PASS=password

echo [1/5] Stopping service...
net stop MariaDB
timeout /t 2 >nul

echo [2/5] Starting service...
net start MariaDB
timeout /t 2 >nul

echo [3/5] Starting MariaDB server...
start "" %MARIADB_BIN%\mysqld.exe --defaults-file=%CONFIG_FILE%
timeout /t 2 >nul

echo [4/5] Running initialization script...
%MARIADB_BIN%\mysql.exe -u root -p%ROOT_PASS% < %INIT_SQL%

echo [3/5] Stopping MariaDB server...
%MARIADB_BIN%\mysqladmin.exe -u root -p%ROOT_PASS% shutdown
timeout /t 5 >nul

echo [4/5] Starting MariaDB again (normal mode)...
net start MariaDB

echo [5/5] Done! MariaDB initialization complete.
endlocal
pause
