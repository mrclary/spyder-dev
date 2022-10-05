#!/usr/bin/env bash
# set -e

ROOT=$(cd $(dirname $BASH_SOURCE)/../../ 2> /dev/null && pwd -P)

mamba env create --force -f $ROOT/mamba/micromamba/environment-dev.yml
mamba env update -f $ROOT/mamba/libmamba/environment-static-dev.yml
