#!/usr/bin/env bash
set -e

SPYROOT=$(cd $(dirname $BASH_SOURCE)/../ 2> /dev/null && pwd -P)
SPYREPO=$SPYROOT/spyder
EXTDEPS=$SPYREPO/external-deps

help() { cat <<EOF

$(basename $0) [-d] [-b <BRANCH>] [-h] REPO
Clone REPO to spyder subrepo

REPO          Repository to clone. Must be in spyder/external-deps

  -d          Clone local repository; otherwise clone from GitHub

  -b BRANCH   Clone from branch BRANCH; otherwise clone from HEAD

  -h          Print this help message

EOF
}

exec 3>&1  # Additional output descriptor for logging
log(){
    level="INFO"
    date "+%Y-%m-%d %H:%M:%S [$level] [clone-subrepo] -> $1" 1>&3
}

while getopts "hdb:" option; do
    case "$option" in
        (h) help; exit ;;
        (d) DEV=true ;;
        (b) BRANCH=$OPTARG ;;
    esac
done
shift $(($OPTIND - 1))

REPO=$1
if [[ -z "$REPO" || ! -d "$EXTDEPS/$REPO" ]]; then
    log "Please specify a repository from spyder/external-deps."
    exit 1
fi

if [[ "$DEV" = true ]]; then
    CLONE=$SPYROOT/$REPO
    BRANCH=${BRANCH:=$(git -C $CLONE branch --show-current)}
else
    case $REPO in
        (python-lsp-server)
            CLONE=https://github.com/python-lsp/python-lsp-server.git
            BRANCH=develop ;;
        (qdarkstyle)
            CLONE=https://github.com/ColinDuquesnoy/QDarkStyleSheet.git
            BRANCH=develop ;;
        (qtconsole)
            CLONE=https://github.com/jupyter/qtconsole.git
            BRANCH=4.2.x ;;
        (spyder-kernels)
            CLONE=https://github.com/spyder-ide/spyder-kernels.git
            BRANCH=2.x ;;
    esac
fi

git -C $SPYREPO subrepo clone $CLONE external-deps/$REPO -b $BRANCH -f
