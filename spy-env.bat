@echo off

setlocal

set conda_prefix=C:\Users\rclary\AppData\Local\mambaforge
set repos=C:\Users\rclary\Documents\Repos
set spy_root=%repos%\spyder
set name=spy-dev
set pyver=3.9

call mamba env remove -n %name%
rmdir /s /q %conda_prefix%\envs\%name%
call mamba create -n %name% python=%pyver%
call mamba env update -n %name% -f %spy_root%\requirements\main.yml
call mamba env update -n %name% -f %spy_root%\requirements\windows.yml
call mamba env update -n %name% -f %spy_root%\requirements\tests.yml
rem  call mamba update -n %name% -f %repos%\spyder-dev\plugins.txt
call mamba run -n %name% python %spy_root%\install_dev_repos.py

rem call mamba env update -n %name% %spy_root%\installers-conda\build-environment.yml
