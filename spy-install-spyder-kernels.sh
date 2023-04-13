#!/usr/bin/env bash
set -e

conda_env=$1
mamba run --live-stream -n $conda_env python $SPYREPO/install_dev_repos.py --install spyder-kernels
