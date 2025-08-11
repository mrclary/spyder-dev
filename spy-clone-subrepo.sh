#!/usr/bin/env bash
set -e

SPYROOT=$(dirname $(dirname ${BASH_SOURCE:-${(%):-%x}}))
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
        local=$ROOT/python-lsp-server
        : ${branch:=develop}
        ;;
    (qtconsole)
        local=$ROOT/qtconsole
        : ${branch:=main}
        ;;
    (spyder-kernels)
        local=$SPYROOT/spyder-kernels
        : ${branch:=master}
        ;;
    (spyder-remote-services)
        local=$SPYROOT/spyder-remote-services
        : ${branch:=main}
esac

url=$(git -C $local remote get-url $remote) || exit $?

args=("external-deps/$REPO")
opts=("-b" "$branch" "--force")

[[ $subcmd = "pull" ]] && opts+=("-r" "${url}" "-u")
[[ $subcmd = "clone" ]] && args=("${url}" "${args[@]}")
cmd=("git" "-C" "$SPYREPO" "subrepo" "$subcmd" "${args[@]}" "${opts[@]}" "${extra_opts[@]}")
log "command: ${cmd[@]}"
${cmd[@]}
