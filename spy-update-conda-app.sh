#!/usr/bin/env bash
set -e

ver=$1
shift

if [[ "$OSTYPE" = "darwin"* ]]; then
    ROOT_PREFIX=$HOME/Library/spyder-${ver}
else
    ROOT_PREFIX=$HOME/.local/spyder-${ver}
fi
PREFIX=${ROOT_PREFIX}/envs/spyder-runtime

mamba run --live-stream -p $PREFIX python $SPYREPO/install_dev_repos.py "$@"
