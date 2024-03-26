@echo off
setlocal

set script_path=%~f0
set here=%~dp0
for %%a in (%~dp0\..) do set src_inst_dir=%%~fa\spyder\installers-conda

where constructor.exe >NUL 2>null
if "%errorlevel%" neq "0" (
    @echo Activate a conda environment with constructor installed to use %~nx0
    goto exit
)

rem  Parse arguments
set BUILDCONDA=false
set BUILDPKG=false
set INSTALL=false
:parse
if "%~1"=="" goto endparse
if "%~1"=="-h" goto help
if "%~1"=="-c" set BUILDCONDA=true& shift
if "%~1"=="-C" set BUILDOPTS=%~2& shift& shift
if "%~1"=="-p" set BUILDPKG=true& shift
if "%~1"=="-i" set INSTALL=true& shift
goto parse
:endparse

@echo src_inst_dir: "%src_inst_dir%"
@echo Build conda packages: %BUILDCONDA%
@echo Build installer: %BUILDPKG%
@echo Install: %INSTALL%
@echo.

set CONDA_BLD_PATH=%USERPROFILE%\.conda\conda-bld

rem  Build conda packages
if "%BUILDCONDA%"=="true" call :build_conda_pkgs || goto exit

if "%BUILDPKG%" neq "true" if "%INSTALL%" neq "true" goto exit

call :get_pkg_name || goto exit

rem  Build installer pkg
if "%BUILDPKG%"=="true" call :build_installer || goto exit

rem  Install
if "%INSTALL%"=="true" (
    call :uninstall || goto exit
    call :install || goto exit
)

:exit
    exit /b %errorlevel%

:help
    @echo %~nx0 [options]
    @echo.
    @echo Build conda packages, build package installer, and/or install
    @echo the package for user.
    @echo.
    @echo Options:
    @echo   -h          Display this help
    @echo.
    @echo   -c          Build conda packages for Spyder and external-deps. Uses
    @echo               build_conda_pkgs.py.
    @echo.
    @echo   -C OPTIONS  Options for building conda packages. This should be a single
    @echo               string of space-separated options, e.g.
    @echo               "--debug --build spyder"
    @echo   -p          Build package installer (.exe). Uses build_installers.py
    @echo.
    @echo   -i          Install the package to the current user
    goto exit

:build_conda_pkgs
    @echo Removing existing conda packages...
    del /s /q "%CONDA_BLD_PATH%\win-64\spyder-6*"
    del /s /q "%CONDA_BLD_PATH%\channeldata.json"

    @echo Building conda packages...
    python "%src_inst_dir%\build_conda_pkgs.py" %BUILDOPTS%

    for /d %%i in ("%CONDA_BLD_PATH%\spyder*") do rmdir /s /q %%i
    for /d %%i in ("%CONDA_BLD_PATH%\qtconsole*") do rmdir /s /q %%i
    for /d %%i in ("%CONDA_BLD_PATH%\python-lsp*") do rmdir /s /q %%i

    goto :eof

:get_pkg_name
    for /F "tokens=*" %%i in (
        'python "%src_inst_dir%\build_installers.py" --artifact-name'
    ) do (
        set pkg_name=%%~fi
    )
    @echo pkg_name: "%pkg_name%"
    goto :eof

:build_installer
    @echo Removing constructor cache for Spyder...
    del /s /q "%USERPROFILE%\.conda\constructor\win-64\spyder-6*"
    for /d %%i in ("%USERPROFILE%\.conda\constructor\win-64\spyder-6*") do rmdir /s /q %%i

    @echo Building installer...
    set NSIS_USING_LOG_BUILD=1
    python "%src_inst_dir%\build_installers.py"
    if not exist "%pkg_name%" (
        @echo Installer "%pkg_name%" not created
        exit /b 1
    )
    goto :eof

:uninstall
    set base_prefix=%LOCALAPPDATA%\spyder-6

    if not exist %base_prefix%\Uninstall-Spyder.exe goto :eof

    @echo Uninstalling existing Spyder...
    start /wait %base_prefix%\Uninstall-Spyder.exe /s _?=%base_prefix%
    @echo Uninstall complete.
    goto :eof

:install
    set mode=user

    @echo Installing Spyder...
    start /wait %pkg_name% /InstallationType=JustMe /s
    if exist %base_prefix%\install.log type %base_prefix%\install.log

    rem  Get shortcut path
    for /F "tokens=*" %%i in (
        '%base_prefix%\python %base_prefix%\Scripts\menuinst_cli.py shortcut --mode=%mode%'
    ) do (
        set shortcut=%%~fi
    )

    @echo shortcut: "%shortcut%"
    if exist "%shortcut%" (
        @echo Spyder installed successfully
    ) else (
        @echo Spyder NOT installed successfully
        exit /b 1
    )
    goto :eof
