#!/usr/bin/env bash
set -e

ver=$1
if [[ "$OSTYPE" = "darwin"* ]]; then
    PREFIX=$HOME/Library/spyder-${ver}/envs/spyder-${ver}
else
    PREFIX=$HOME/.local/Spyder-${ver}/envs/spyder-${ver}
fi

mamba run --live-stream -p $PREFIX python $SPYREPO/install_dev_repos.py
