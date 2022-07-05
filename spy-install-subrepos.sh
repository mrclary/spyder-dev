#!/usr/bin/env bash
set -e

help() { cat <<EOF

$(basename $0) [-h]
Install Spyder's subrepos in develop mode

EOF
}

exec 3>&1  # Additional output descriptor for logging
log(){
    level="INFO"
    date "+%Y-%m-%d %H:%M:%S [$level] [install-subrepos] -> $1" 1>&3
}

SPYROOT=$(cd $(dirname $BASH_SOURCE)/../ 2> /dev/null && pwd -P)
SPYREPO=$SPYROOT/spyder
EXTDEPS=$SPYREPO/external-deps

if [[ -z "$CONDA_DEFAULT_ENV" && -z "$PYENV_VERSION" && -z "$VIRTUAL_ENV" ]]; then
    log "Do not install subrepos into base environment. Activate an environment first."
    exit 1
fi

log "Installing subrepos..."

if [[ -e "$SPYREPO/install_dev_repos.py" ]]; then
    python -bb -X dev -W error $SPYREPO/install_dev_repos.py --no-install spyder
else
    for dep in $(ls $SPYREPO/external-deps); do
        $SPYROOT/spyder-dev/spy-install-subrepo.sh $dep
    done
fi
