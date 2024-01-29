@echo off
setlocal

set script_path=%~f0
set here=%~dp0
for %%a in (%~dp0\..) do set src_inst_dir=%%~fa\spyder\installers-conda

where constructor.exe >NUL 2>null
if "%errorlevel%" neq "0" (
    echo Activate a conda environment with constructor installed to use %~nx0
    goto exit
)

:: Parse arguments
set BUILDCONDA=false
set BUILDPKG=false
set INSTALL=false
:parse
IF "%~1"=="" GOTO endparse
IF "%~1"=="-h" goto help
IF "%~1"=="-c" set BUILDCONDA=true
if "%~1"=="-C" set BUILDOPTS=%~2
IF "%~1"=="-p" set BUILDPKG=true
IF "%~1"=="-i" set INSTALL=true
SHIFT
GOTO parse

:help
echo %~nx0 [options]
echo.
echo Build conda packages, build package installer, and/or install
echo the package for user.
echo.
echo Options:
echo   -h          Display this help
echo.
echo   -c          Build conda packages for Spyder and external-deps. Uses
echo               build_conda_pkgs.py.
echo.
echo   -C OPTIONS  Options for building conda packages. This should be a single
echo               string of space-separated options, e.g.
echo               "--debug --build spyder"
echo   -p          Build package installer (.exe). Uses build_installers.py
echo.
echo   -i          Install the package to the current user
goto exit

:endparse

echo src_inst_dir: "%src_inst_dir%"
echo Build conda packages: %BUILDCONDA%
echo Build installer: %BUILDPKG%
echo Install: %INSTALL%
echo.

:: Build conda packages
if "%BUILDCONDA%"=="true" call :build_conda_pkgs

if "%BUILDPKG%" neq "true" if "%INSTALL%" neq "true" goto exit

call :get_pkg_name

:: Build installer pkg
if "%BUILDPKG%"=="true" call :build_installer

:: Install
if "%INSTALL%"=="true" (
    call :uninstall
    call :install
)

:exit
    exit /b %errorlevel%

:build_conda_pkgs
    echo Removing existing conda packages...
    del /S /Q "%USERPROFILE%\.conda\conda-bld\win-64\spyder-6*"
    del /S /Q "%USERPROFILE%\.conda\conda-bld\channeldata.json"

    echo Building conda packages...
    python "%src_inst_dir%\build_conda_pkgs.py" %BUILDOPTS% || goto exit
    goto :eof

:get_pkg_name
    for /F "tokens=*" %%i in (
        'python "%src_inst_dir%\build_installers.py" --artifact-name'
    ) do (
        set pkg_name=%%~fi
    )
    echo pkg_name: "%pkg_name%"
    goto :eof

:build_installer
    echo Removing constructor cache for Spyder...
    del /S /Q "%USERPROFILE%\.conda\constructor\win-64\spyder-6*"
    for /d %%i in ("%USERPROFILE%\.conda\constructor\win-64\spyder-6*") do rmdir /S /Q %%i

    echo Building installer...
    set NSIS_USING_LOG_BUILD=1
    python "%src_inst_dir%\build_installers.py"
    if not exist "%pkg_name%" goto exit
    goto :eof

:uninstall
    set base_prefix=%USERPROFILE%\AppData\Local\spyder-6

    if not exist %base_prefix%\Uninstall-Spyder.exe goto :eof

    echo Uninstalling existing Spyder...
    start /wait %base_prefix%\Uninstall-Spyder.exe /S
    timeout /t 2 /nobreak > nul
    :loop
    tasklist /fi "ImageName eq Un_A.exe" /fo csv 2>NUL | findstr /r "Un_A.exe">NUL
    if "%errorlevel%"=="0" (
        timeout /t 1 /nobreak > nul
        goto loop
    )
    echo Uninstall complete.
    goto :eof

:install
    set spy_rt=%base_prefix%\envs\spyder-runtime
    set menu=%spy_rt%\Menu\spyder-menu.json
    set mode=user

    echo Installing Spyder...
    start /wait %pkg_name% /S /D=%LOCALAPPDATA%\spyder-6
    if exist %LOCALAPPDATA%\spyder-6\install.log type %LOCALAPPDATA%\spyder-6\install.log

    :: Get shortcut path
    for /F "tokens=*" %%i in (
        '%base_prefix%\python -c "from menuinst.api import _load; menu, menu_items = _load(r'%menu%', target_prefix=r'%spy_rt%', base_prefix=r'%base_prefix%', _mode='%mode%'); print(menu_items[0]._paths()[0])"'
    ) do (
        set shortcut=%%~fi
    )
    if "%errorlevel%" neq "0" goto :exit

    echo shortcut: "%shortcut%"
    if exist "%shortcut%" (
        echo Spyder installed successfully
    ) else (
        echo Spyder NOT installed successfully
        EXIT /B 1
    )
    goto :eof
