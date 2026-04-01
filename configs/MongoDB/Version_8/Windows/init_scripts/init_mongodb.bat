@echo off
setlocal

REM === Adjust paths as needed ===
set MONGO_BIN="C:\Program Files\MongoDB\Server\8.0\bin"
set MONGO_BIN_SHELL="C:\Program Files\MongoDB\mongosh-2.5.8-win32-x64\bin"
set CONFIG_FILE=C:\Projekte\MongoDB\Version_8\Windows\mongod.conf   REM adjust
set DBPATH=C:\data\mongodb
set LOGPATH=C:\data\log\mongod.log
set USER_SCRIPT=C:\Projekte\MongoDB\Version_8\Windows\init_users.js REM adjust path

echo [1/5] Starting MongoDB without authentication ...
start "MongoDBTemp" %MONGO_BIN%\mongod.exe --dbpath="%DBPATH%" --logpath="%LOGPATH%" --bind_ip 127.0.0.1 --port 27017 --noauth
timeout /t 5 >nul

echo [2/5] Running init users script ...
%MONGO_BIN_SHELL%\mongosh.exe --port 27017 "%USER_SCRIPT%"

echo [3/5] Stopping temporary MongoDB server ...
taskkill /IM mongod.exe /F >nul

REM === Authentication must be enabled in the config ===
REM security:
REM   authorization: enabled

echo [4/5] Starting MongoDB with authentication ...
start "MongoDB" %MONGO_BIN%\mongod.exe --config "%CONFIG_FILE%"

echo [5/5] Done! Users created and auth enabled.
endlocal
pause
