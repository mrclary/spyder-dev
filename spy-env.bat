@rem This script creates Spyder conda environments
@echo off
SETLOCAL
set type=dev
set pyver=3.11

@rem Create variables from arguments
:parse
    if "%~1"=="" goto endparse
    if "%~1"=="-h" goto help
    if "%~1"=="-t" set "type=%~2" & shift
    if "%~1"=="-n" set "name=%~2" & shift
    if "%~1"=="-v" set "pyver=%~2" & shift
    shift
    goto :parse

:help
    echo %~nx0 [options]
    echo.
    echo Create an environment for developing or building Spyder.
    echo.
    echo Options:
    echo   -h        Display this help
    echo   -t TYPE   Envrionment type. "dev" or "conda-build". Default is "dev". conda-build
    echo             is a conda environment suitable for building the conda-based installers.
    echo             dev is a conda environment for developing Spyder.
    echo   -n NAME   Environment name. Default is spy-dev for dev type or spy-inst for
    echo             conda-build type.
    echo   -v PYVER  Specify the Python version. Default is %pyver%.x.
    echo.
    goto :exit

:endparse

set repos=%userprofile%\Documents\Repos
set spy_root=%repos%\spyder

if "%name%"=="" (
    if "%type%"=="dev" set name=spy-dev
    if "%type%"=="conda-build" set name=spy-inst
)

call conda env list 2>nul | findstr %name% >nul && (
    @echo Removing existing environment %name%...
    call conda env remove -y -n %name% 2>nul
    rmdir /S /Q %userprofile%\.conda\envs\%name%
)
set CONDA_CHANNEL_PRIORITY=flexible

@echo Creating environment %name%...
call conda create -y -n %name% python=%pyver% || goto :error

if "%type%"=="dev" (
    call conda env update -n %name% -f %spy_root%\requirements\main.yml || goto :error
    call conda env update -n %name% -f %spy_root%\requirements\windows.yml || goto :error
    call conda env update -n %name% -f %spy_root%\requirements\tests.yml || goto :error
    rem  conda update -n %name% -f %repos%\spyder-dev\plugins.txt || goto :error
    call conda run -n %name% python %spy_root%\install_dev_repos.py || goto :error
)
if "%type%"=="conda-build" (
    @echo Updating with build-environment.yml...
    call conda env update -n %name% -f %spy_root%\installers-conda\build-environment.yml || goto :error

    @echo Installing nsis...
    call conda install -y -n %name% nsis=3.08=*_log_* || goto :error
)
goto :exit

:error
    @echo An error occurred
    goto :exit

:exit
    exit /b %errorlevel%

endlocal
