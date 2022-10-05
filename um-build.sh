#!/usr/bin/env bash
set -e

ROOT=$(cd $(dirname $BASH_SOURCE)/../../ 2> /dev/null && pwd -P)

# mamba activate mamba-dev

build_dir=$ROOT/mamba/build
rm -rf $build_dir
mkdir -p $build_dir
cd $build_dir

cmake_opts=()
cmake_opts+=("-DBUILD_LIBMAMBA=ON")
cmake_opts+=("-DBUILD_STATIC_DEPS=ON")
cmake_opts+=("-DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX")
cmake_opts+=("-DBUILD_MICROMAMBA=ON")
cmake_opts+=("-DMICROMAMBA_LINKAGE=FULL_STATIC")
cmake .. ${cmake_opts[@]}
make
