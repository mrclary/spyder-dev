:: This script installs or uninstalls the Spyder shortcut
@echo off
SETLOCAL

:: default uninstall then install
set UNINSTALL=true
set INSTALL=true
set VER=6

:: Create variables from arguments
:parse
IF "%~1"=="" goto endparse
IF "%~1"=="-h" (
     call :help
     goto exit
)
IF "%~1"=="-u" (
    set UNINSTALL=true
    set INSTALL=false
    SHIFT
)
IF "%~1"=="-i" (
    set INSTALL=true
    set UNINSTALL=false
    SHIFT
)
if "%~1"=="-v" set VER=%~2& shift
SHIFT
goto parse
:endparse

:: Enforce encoding
chcp 65001>nul

set base_prefix=%localappdata%\spyder-%VER%
set target_prefix=%base_prefix%\envs\spyder-runtime
set menu=%target_prefix%\Menu\spyder-menu.json

if "%UNINSTALL%"=="true" (
    %base_prefix%\python -c "from menuinst.api import remove; remove(r'%menu%', target_prefix=r'%target_prefix%', base_prefix=r'%base_prefix%')"
)

if "%INSTALL%"=="true" (
    %base_prefix%\python -c "from menuinst.api import install; install(r'%menu%', target_prefix=r'%target_prefix%', base_prefix=r'%base_prefix%')"
)

:exit
exit /B %ERRORLEVEL%

:help
    goto :EOF
