:: This script creates Spyder conda environments
@echo off
SETLOCAL
set type=dev
set pyver=3.10

:: Create variables from arguments
:parse
IF "%~1"=="" goto endparse
IF "%~1"=="-h" goto help
IF "%~1"=="-t" set type=%~2& shift
IF "%~1"=="-n" set name=%~2& shift
if "%~1"=="-v" set pyver=%~2& shift
SHIFT
goto parse

:help
echo %~nx0 [options]
echo.
echo Create an environment for developing or building Spyder.
echo.
echo Options:
echo   -h        Display this help
echo.
echo   -t TYPE   Envrionment type. "dev" or "conda-build". Default is "dev". conda-build
echo             is a conda environment suitable for building the conda-based installers.
echo             dev is a conda environment for developing Spyder.
echo.
echo   -n NAME   Environment name. Default is spy-dev for dev type or spy-inst for
echo             conda-build type.
echo   -v PYVER  Specify the Python version. Default is %pyver%.x.
echo.
goto exit

:endparse

set conda_prefix=C:\Users\rclary\AppData\Local\miniforge3
set repos=C:\Users\rclary\Documents\Repos
set spy_root=%repos%\spyder

if "%name%"=="" (
    if "%type%"=="dev" set name=spy-dev
    if "%type%"=="conda-build" set name=spy-inst
)

@echo on
call mamba env remove -n %name%
rmdir /S /Q %HOMEPATH%\.conda\envs\%name%
set CONDA_CHANNEL_PRIORITY=flexible

call mamba create -y -n %name% python=%pyver% || goto error

IF "%type%"=="dev" (
    call mamba env update -n %name% -f %spy_root%\requirements\main.yml || goto error
    call mamba env update -n %name% -f %spy_root%\requirements\windows.yml || goto error
    call mamba env update -n %name% -f %spy_root%\requirements\tests.yml || goto error
    rem  call mamba update -n %name% -f %repos%\spyder-dev\plugins.txt || goto error
    call mamba run -n %name% python %spy_root%\install_dev_repos.py || goto error
)
IF "%type%"=="conda-build" (
    call mamba env update -n %name% -f %spy_root%\installers-conda\build-environment.yml || goto error
)
@echo off

:error
goto exit

:exit
exit /B %errorlevel%
