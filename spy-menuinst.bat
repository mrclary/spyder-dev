@echo off
rem  SETLOCAL

rem  default uninstall then install
set UNINSTALL=true
set INSTALL=true
set bp=%localappdata%\spyder-6
set tp=%bp%\envs\spyder-runtime

rem  Create variables from arguments
:parse
if "%~1"=="" goto endparse
if "%~1"=="-h" goto :help
if "%~1"=="-u" set UNINSTALL=true& set INSTALL=false& shift
if "%~1"=="-i" set INSTALL=true& set UNINSTALL=false& shift
if "%~1"=="-b" set bp=%localappdata%\%~2& shift& shift
if "%~1"=="-t" set tp=%userprofile%\.conda\envs\%~2& shift& shift
goto parse
:endparse

set menu=%tp%\Menu\spyder-menu.json

if "%UNINSTALL%"=="true" (
    %bp%\python -c "from menuinst.api import remove; remove(r'%menu%', target_prefix=r'%tp%', base_prefix=r'%bp%')"
)

if "%INSTALL%"=="true" (
    %bp%\python -c "from menuinst.api import install; install(r'%menu%', target_prefix=r'%tp%', base_prefix=r'%bp%')"
)

:exit
    exit /b %errorlevel%

:help
    @echo %~nx0 [options]
    @echo.
    @echo Install or uninstall Spyder shortcut. If -u and -i are not provided, then
    @echo the shortcut is first uninstalled and then reinstalled.
    @echo.
    @echo Options:
    @echo   -h         Display this help
    @echo.
    @echo   -u         Uninstall the shortcut
    @echo.
    @echo   -i         Install the shortcut
    @echo.
    @echo   -b BASE    Base environment name, located in %localappdata%.
    @echo              If not provided, %bp% is used
    @echo              for the base prefix.
    @echo.
    @echo   -t TARGET  Target environment name, located in %userprofile%\.conda\envs.
    @echo              If not provided, %tp%
    @echo              is used for the target prefix.
    goto :exit
