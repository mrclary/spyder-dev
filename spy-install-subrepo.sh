#!/usr/bin/env bash
set -e

help() { cat <<EOF

$(basename $0) [-h] subrepo

Install subrepo in develop mode without dependencies

Options:
  subrepo     Subrepo name

EOF
}

exec 3>&1  # Additional output descriptor for logging
log(){
    level="INFO"
    echo "$(date "+%Y-%m-%d %H:%M:%S") [$level] [install-subrepo] -> $@" 1>&3
}

SPYROOT=$(dirname $(dirname ${BASH_SOURCE:-${(%):-%x}}))
SPYREPO=$SPYROOT/spyder
EXTDEPS=$SPYREPO/external-deps

if [[ -z "$CONDA_DEFAULT_ENV" && -z "$PYENV_VERSION" && -z "$VIRTUAL_ENV" ]]; then
    log "Do not install subrepos into base environment. Activate an environment first."
    exit 1
fi
if [[ -e "$SPYREPO/install_dev_repos.py" ]]; then
    python -bb -X dev -W error $SPYREPO/install_dev_repos.py $@
else
    if [[ "$1" = "python-lsp-server" && -e $SPYREPO/pylsp_utils.py ]]; then
        export SETUPTOOLS_SCM_PRETEND_VERSION=$(python $SPYREPO/pylsp_utils.py)
    fi
    python -m pip install --no-deps -e $EXTDEPS/$1
fi
