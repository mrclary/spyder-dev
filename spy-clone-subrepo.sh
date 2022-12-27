#!/usr/bin/env bash
set -e

SPYROOT=$(cd $(dirname $BASH_SOURCE)/../ 2> /dev/null && pwd -P)
ROOT=$(dirname $SPYROOT)
SPYREPO=$SPYROOT/spyder
EXTDEPS=$SPYREPO/external-deps

help() { cat <<EOF

$(basename $0) [-h] [-c] [-r upstream|fork|local] [-b BRANCH] [-O OPTIONS] REPO

Pull to subrepo REPO

Options:
  -h          Print this help message.

  -c          Use subrepo clone instead of pull.

  -r REMOTE   Pull from REMOTE. Must be one of "upstream", "fork",
              or "local". If not provided, "upstream" is used.

  -b BRANCH   Pull from branch BRANCH. "HEAD" will be used if the option
              is not provided.

  -O OPTIONS  Additional options passed to subrepo pull (or clone). This should
              be a single string of space-separated options.

  REPO        Repository to pull. Must be in spyder/external-deps.

EOF
}

exec 3>&1  # Additional output descriptor for logging
log(){
    level="INFO"
    echo "$(date "+%Y-%m-%d %H:%M:%S") [$level] [clone-subrepo] -> $@" 1>&3
}

subcmd=pull
remote=upstream
extra_opts=()

OIFS=$IFS
IFS=' '
while getopts "hcr:b:O:" option; do
    case "$option" in
        (h) help; exit ;;
        (c) subcmd=clone ;;
        (r) remote=$OPTARG ;;
        (b) branch=$OPTARG ;;
        (O) extra_opts+=($OPTARG) ;;
    esac
done
shift $(($OPTIND - 1))
IFS=$OIFS
unset OIFS

REPO=$1
if [[ -z "$REPO" || ! -d "$EXTDEPS/$REPO" ]]; then
    log "Please specify a repository from spyder/external-deps."
    exit 1
fi
shift

extra_opts+=($@)

case $REPO in
    (python-lsp-server)
        upstream=https://github.com/python-lsp/python-lsp-server.git
        fork=https://github.com/mrclary/python-lsp-server.git
        local=$ROOT/python-lsp-server
        : ${branch:=develop}
        ;;
    (qdarkstyle)
        upstream=remote=https://github.com/ColinDuquesnoy/QDarkStyleSheet.git
        fork=remote=https://github.com/mrclary/QDarkStyleSheet.git
        local=$ROOT/qdarkstyle
        : ${branch:=develop}
        ;;
    (qtconsole)
        upstream=https://github.com/jupyter/qtconsole.git
        fork=https://github.com/mrclary/qtconsole.git
        local=$ROOT/qtconsole
        : ${branch:=master}
        ;;
    (spyder-kernels)
        upstream=https://github.com/spyder-ide/spyder-kernels.git
        fork=https://github.com/mrclary/spyder-kernels.git
        local=$SPYROOT/spyder-kernels
        : ${branch:=2.x}
        ;;
esac

if [[ -z ${!remote} ]]; then
    log "Unknown remote option: \"${remote}\". Using $upstream"
    remote=upstream
fi

args=("external-deps/$REPO")
opts=("-b" "$branch")
# "-f")
[[ $subcmd = "pull" ]] && opts+=("-r" "${!remote}" "-u")
[[ $subcmd = "clone" ]] && args=("${!remote}" "${args[@]}")
cmd=("git" "-C" "$SPYREPO" "subrepo" "$subcmd" "${args[@]}" "${opts[@]}" "${extra_opts[@]}")
log "command: ${cmd[@]}"
${cmd[@]}
