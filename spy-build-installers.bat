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
echo   -h  Display this help
echo.
echo   -a  Perform all operations: build conda packages; build package
echo       installer; notarize package installer; and install package.
echo       Equivalent to -c -p -n -i
echo.
echo   -c  Build conda packages for Spyder and external-deps. Uses
echo       build_conda_pkgs.py.
echo.
echo   -p  Build package installer (.exe). Uses build_installers.py
echo.
echo   -i  Install the package to the current user
goto exit

:endparse

echo src_inst_dir: "%src_inst_dir%"
echo BUILDCONDA: %BUILDCONDA%
echo BUILDPKG: %BUILDPKG%
echo INSTALL: %INSTALL%
echo.

:: Build conda packages
if "%BUILDCONDA%"=="true" (
    echo Building conda packages...
    python "%src_inst_dir%\build_conda_pkgs.py" %BUILDOPTS% || goto exit
) else (
    echo Not building conda packages
)

:: Build installer pkg
if "%BUILDPKG%"=="true" (
    echo Building installer...
    python "%src_inst_dir%\build_installers.py" || goto exit
) else (
    echo Not building installer
)

for /F "tokens=*" %%i in (
    'python "%src_inst_dir%\build_installers.py" --artifact-name'
) do (
    set pkg_name=%%~fi
)
echo pkg_name: "%pkg_name%"

:: Install
if "%INSTALL%"=="true" (
    set base_prefix=%USERPROFILE%\AppData\Local\spyder-6

    :: Remove previous install
    start /wait "%base_prefix%\Uninstall-Spyder"

    start /wait "%pkg_name%" /InstallationType=JustMe /NoRegistry=1 /S

    :: Get shortcut path
    set spy_rt=%base_prefix%\envs\spyder-runtime
    set menu=%spy_rt%\Menu\spyder-menu.json
    set mode=user
    for /F "tokens=*" %%i in (
        '%base_prefix%\python -c "from menuinst.api import _load; menu, menu_items = _load(r'%menu%', target_prefix=r'%spy_rt%', base_prefix=r'%base_prefix%', _mode='%mode%'); print(menu_items[0]._paths()[0])"'
    ) do (
        set shortcut=%%~fi
    )

    if exist "%shortcut%" (
        echo Spyder installed successfully
    ) else (
        echo Spyder NOT installed successfully
        EXIT /B 1
    )
) else (
  echo Not installing
)

:exit
exit /b %errorlevel%
