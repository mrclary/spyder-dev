# Command-line tools for managing Spyder development environments

spy-var () {
help () { cat <<EOF

$FUNCNAME [-h] [-u]

Set or unset Spyder development environment variables

Options:
  -h    Display this help and return

  -u    Unset all environment variables and aliases set by this function

EOF
}

local me=${BASH_SOURCE:-${(%):-%x}}

while getopts "hu" option; do
    case $option in
        (h) help; return ;;
        (u) unset_var=0 ;;
    esac
done
shift $(($OPTIND - 1))

if [[ -z $unset_var ]]; then
    echo Setting Spyder environment variables and aliases...
    export SPYDEV=$(dirname $me)
    ROOT=$(dirname $SPYDEV)
    export SPYREPO=$ROOT/spyder
    EXTDEPS=$SPYREPO/external-deps
    alias spy-build-installers="$SPYDEV/spy-build-installers.sh"
    alias spy-clone-subrepo="$SPYDEV/spy-clone-subrepo.sh"
    alias spy-env="$SPYDEV/spy-env.sh"
    alias spy-menuinst="$SPYDEV/spy-menuinst.sh"
    alias spy-update-conda-app="$SPYDEV/spy-update-conda-app.sh"
    alias spy-dev-spyder="mamba run --live-stream -n spy-dev python $SPYREPO/bootstrap.py"
    if [[ $OSTYPE == "darwin"* ]]; then
        alias spy-app-spyder="$HOME/Applications/Spyder.app/Contents/MacOS/spyder"
    fi

else
    echo Removing Spyder environment variables and aliases...
    local raw_v=($(/usr/bin/env -i bash -c "source $me ; compgen -v"))
    local raw_a=($(/usr/bin/env -i bash -c "source $me ; compgen -a"))
    local new_v=($(/usr/bin/env -i bash -c "source $me ; spy-var &>/dev/null; compgen -v"))
    local new_a=($(/usr/bin/env -i bash -c "source $me ; spy-var &>/dev/null; compgen -a"))
    local to_rem_v=($(echo ${raw_v[@]} ${new_v[@]} | tr ' ' '\n' | sort | uniq -u))
    local to_rem_a=($(echo ${raw_a[@]} ${new_a[@]} | tr ' ' '\n' | sort | uniq -u))

    unalias ${to_rem_a[@]}
    unset -v ${to_rem_v[@]}
fi
unset -f help
unset -v option unset_var OPTERR OPTARG
}
