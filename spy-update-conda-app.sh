#!/usr/bin/env bash
set -e

script_path=${BASH_SOURCE:-${(%):-%x}}
here=$(dirname $script_path)
spyrepo=$(dirname $here)/spyder

ver=6

help(){ cat <<EOF
$(basename $script_path) [options]

Install local Spyder repository and friends ($spyrepo)
in editable mode in the installer location.
Requires that Spyder is already installed via installer.

Options:
  -h      Display this help and exit.
  -v VER  Spyder major version (default $ver).

Additional options are passed to $spyrepo/install_dev_repos.py

------------------------------------------------------------------------------

$(conda run python $spyrepo/install_dev_repos.py --help)

EOF
}

while getopts ":hv:" option; do
    case $option in
        (h) help; exit ;;
        (v) ver=$OPTARG
    esac
done
shift $(($OPTIND - 1))

if [[ "$OSTYPE" = "darwin"* ]]; then
    ROOT_PREFIX=$HOME/Library/spyder-${ver}
else
    ROOT_PREFIX=$HOME/.local/spyder-${ver}
fi
PREFIX=${ROOT_PREFIX}/envs/spyder-runtime

conda run --live-stream -p $PREFIX python $spyrepo/install_dev_repos.py "$@"
