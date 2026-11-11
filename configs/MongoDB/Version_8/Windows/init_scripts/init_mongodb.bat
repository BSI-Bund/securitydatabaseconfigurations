@echo off
setlocal DisableDelayedExpansion
REM Only connect to an operator-started, dedicated localhost bootstrap instance.
REM No server is started, killed, stopped, or restarted by this script.
if /I not "%~1"=="--bootstrap" goto usage
if not defined MONGOSH_EXE set "MONGOSH_EXE=mongosh.exe"
if not defined MONGO_BOOTSTRAP_PORT set "MONGO_BOOTSTRAP_PORT=27017"
if not defined MONGO_BOOTSTRAP_DBPATH set "MONGO_BOOTSTRAP_DBPATH=C:\data\mongodb"
set "MONGO_BOOTSTRAP=1"
set "USER_SCRIPT=%~dp0init_users.js"
if not exist "%USER_SCRIPT%" goto missing_script
if exist "%MONGOSH_EXE%" goto run
where.exe "%MONGOSH_EXE%" >nul 2>&1
if errorlevel 1 goto missing_client
:run
"%MONGOSH_EXE%" --host 127.0.0.1 --port "%MONGO_BOOTSTRAP_PORT%" --file "%USER_SCRIPT%"
if errorlevel 1 goto failed
echo User created. Stop the bootstrap server with Ctrl+C, then start the TLS configuration.
exit /b 0
:usage
echo Usage: init_mongodb.bat --bootstrap 1>&2
echo First start a new localhost-only bootstrap instance as described in the README. 1>&2
exit /b 2
:missing_client
echo mongosh not found. Add it to PATH or set MONGOSH_EXE to its full path. 1>&2
exit /b 1
:missing_script
echo init_users.js is missing next to this batch file. 1>&2
exit /b 1
:failed
echo User initialization failed. The server has not been stopped or restarted. 1>&2
exit /b 1
