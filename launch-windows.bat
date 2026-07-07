@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set "PORT=%INTERVENTION_PORT%"
if not defined PORT set "PORT=8000"
set "NO_BROWSER="

:parse_args
if "%~1"=="" goto resolve_python
if /I "%~1"=="--no-browser" (
    set "NO_BROWSER=1"
    shift
    goto parse_args
)
for /f "delims=0123456789" %%A in ("%~1") do (
    echo Unknown argument: %~1
    echo Usage: %~n0 [port] [--no-browser]
    exit /b 1
)
set "PORT=%~1"
shift
goto parse_args

:resolve_python
set "PYTHON="
call :test_python "py -3"
if not defined PYTHON call :test_python "python3"
if not defined PYTHON call :test_python "python"
if not defined PYTHON if exist "%SCRIPT_DIR%runtime\python\python.exe" call :test_python "%SCRIPT_DIR%runtime\python\python.exe"
if not defined PYTHON if exist "%SCRIPT_DIR%runtime\python\bin\python.exe" call :test_python "%SCRIPT_DIR%runtime\python\bin\python.exe"

if not defined PYTHON (
    echo Python 3 with sqlite3 was not found.
    echo Install Python 3 or place a runtime under runtime\python\python.exe.
    exit /b 1
)

if not exist "%SCRIPT_DIR%data" mkdir "%SCRIPT_DIR%data" >nul 2>nul
set "DB_PATH=%SCRIPT_DIR%data\intervention_reports.sqlite3"

pushd "%SCRIPT_DIR%"
if defined NO_BROWSER (
    %PYTHON% "%SCRIPT_DIR%server.py" --host 127.0.0.1 --port %PORT% --db "%DB_PATH%" --no-browser
) else (
    %PYTHON% "%SCRIPT_DIR%server.py" --host 127.0.0.1 --port %PORT% --db "%DB_PATH%" --open-browser
)
set "EXITCODE=%ERRORLEVEL%"
popd
exit /b %EXITCODE%

:test_python
set "CANDIDATE=%~1"
%CANDIDATE% -c "import sqlite3, http.server" >nul 2>nul
if not errorlevel 1 set "PYTHON=%CANDIDATE%"
exit /b 0
