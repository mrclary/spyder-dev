#!/usr/bin/env bash
set -e

help() { cat <<EOF

$(basename $0) [-h]
Install Spyder's subrepos in develop mode

EOF
}

SPYROOT=$(cd $(dirname $BASH_SOURCE)/../ 2> /dev/null && pwd -P)
SPYREPO=$SPYROOT/spyder
EXTDEPS=$SPYREPO/external-deps

echo "Installing subrepos..."

if [[ -z "$CONDA_DEFAULT_ENV" && -z "$PYENV_VERSION" && -z "$VIRTUAL_ENV" ]]; then
    echo "Do not install subrepos into base environment. Activate an environment first."; exit 1
fi
if [[ -e "$SPYREPO/install_dev_repos.py" ]]; then
    python -bb -X dev -W error $SPYREPO/install_dev_repos.py --no-install spyder
else
    for dep in $(ls $SPYREPO/external-deps); do
        $SPYROOT/spyder-dev/spy-install-subrepo.sh $dep
    done
fi
