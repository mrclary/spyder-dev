# Command-line tools for managing Spyder development environments

spy-var () {
local funcname=$FUNCNAME
local SOURCE=${BASH_SOURCE:-${(%):-%x}}

help () { cat <<EOF

$funcname [-h] [-u]

Set or unset Spyder development environment variables

Options:
  -h    Display this help and return

  -u    Unset all environment variables and aliases set by this function

EOF
}

local option
while getopts "hu" option; do
    case $option in
        (h) help; return ;;
        (u) local unset_var=0 ;;
    esac
done
shift $(($OPTIND - 1))
unset -f help

if [[ -z $unset_var ]]; then
    echo Setting Spyder environment variables and aliases...
    export SPYDEV=$(dirname $SOURCE)
    local ROOT=$(dirname $SPYDEV)
    export SPYREPO=$ROOT/spyder
    local EXTDEPS=$SPYREPO/external-deps
    alias spy-build-installers="$SPYDEV/spy-build-installers.sh"
    alias spy-clone-subrepo="$SPYDEV/spy-clone-subrepo.sh"
    alias spy-env="$SPYDEV/spy-env.sh"
    alias spy-menuinst="$SPYDEV/spy-menuinst.sh"
    alias spy-update-conda-app="$SPYDEV/spy-update-conda-app.sh"
    alias spy-run-dev="conda run --live-stream -n spy-dev spyder"
    if [[ $OSTYPE == "darwin"* ]]; then
        alias spy-run-app-term="$HOME/Applications/Spyder\ 6.app/Contents/MacOS/spyder-6"
        alias spy-run-app="open -a $HOME/Applications/Spyder\ 6.app --args"
    fi
else
    echo Removing Spyder environment variables and aliases...
    unalias spy-build-installers spy-clone-subrepo spy-env spy-menuinst spy-update-conda-app
    unalias spy-dev-spyder spy-app-spyder 2>/dev/null
    unset -v SPYDEV SPYREPO
fi
}
