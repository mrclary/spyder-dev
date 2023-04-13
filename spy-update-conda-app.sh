#!/usr/bin/env bash
set -e

ver=$1
PREFIX=$HOME/Library/spyder-${ver}/envs/spyder-${ver}

mamba run --live-stream -p $PREFIX python $SPYREPO/install_dev_repos.py
