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
    python %src_inst_dir%\build_conda_pkgs.py %BUILDOPTS% || goto exit
) else (
    echo Not building conda packages
)

:: Build installer pkg
if "%BUILDPKG%"=="true" (
    echo Building installer...
    python %src_inst_dir%\build_installers.py || goto exit
) else (
    echo Not building installer
)

for /F "tokens=*" %%i in (
    'python %src_inst_dir%\build_installers.py --artifact-name'
) do (
    set pkg_name=%%~fi
)
echo pkg_name: "%pkg_name%"

rem if "%INSTALL%"=="true" (
rem    echo install
rem      # Remove previous install
rem      log "Uninstall previous installation..."
rem      u_spy_exe=$dest_root/spyder-*/uninstall-spyder.sh
rem      u_spy_exe=$(dirname $u_spy_exe)/$(basename $u_spy_exe)
rem      [[ -f $u_spy_exe ]] && $u_spy_exe -f
rem
rem      # Run installer
rem      log "Installing Spyder..."
rem      if [[ "$pkg_name" =~ ^.*\.pkg$ ]]; then
rem          tail -F /var/log/install.log &
rem          trap "kill -s TERM $!" EXIT
rem          installer -pkg $pkg_name -target CurrentUserHomeDirectory
rem      else
rem          # export CONDA_VERBOSITY=3
rem          "$pkg_name" ${install_opts[@]}
rem      fi
rem
rem      set base_prefix=%localappdata%\spyder-6
rem      set target_prefix=%base_prefix%\envs\spyder-runtime
rem      set menu=%target_prefix%\Menu\spyder-menu.json
rem      set mode
rem      for /F "tokens=*" %%i in (
rem          '%base_prefix%\python -c "from menuinst.api import _load; menu, menu_items = _load(r'%menu%', target_prefix='%spy_rt%', base_prefix='%base_prefix%', _mode='%mode%'); print(menu_items[0]._paths()[0])"'
rem      ) do (
rem          set shortcut=%%~fi
rem      )
rem
rem      # Show install results
rem      log "Install info:"
rem      echo -e "Contents of" $dest_root/spyder-* :
rem      ls -al $dest_root/spyder-*
rem      echo -e "\nContents of" $dest_root/spyder-*/uninstall-spyder.sh :
rem      cat $dest_root/spyder-*/uninstall-spyder.sh
rem      echo ""
rem      if [[ "$OSTYPE" = "darwin"* && -e "$shortcut_path" ]]; then
rem          tree $shortcut_path
rem          echo ""
rem          cat $shortcut_path/Contents/Info.plist
rem          echo ""
rem          cat $shortcut_path/Contents/MacOS/spyder-script
rem          echo ""
rem      elif [[ "$OSTYPE" = "linux" && -e "$shortcut_path" ]]; then
rem          cat $shortcut_path
rem          echo ""
rem      else
rem          log "$shortcut_path does not exist"
rem      fi
rem ) else (
rem    echo Not installing
rem )

:exit
exit /b %errorlevel%
