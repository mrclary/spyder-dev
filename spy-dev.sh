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

while getopts "hu" option; do
    case $option in
        (h) help; return ;;
        (u) unset_var=0 ;;
    esac
done
shift $(($OPTIND - 1))

if [[ -z $unset_var ]]; then
    export SPYDEV=$(dirname ${BASH_SOURCE:-${(%):-%x}})
    ROOT=$(dirname $SPYDEV)
    export SPYREPO=$ROOT/spyder
    EXTDEPS=$SPYREPO/external-deps

    export CONDA_BLD_PATH=$HOME/.conda/conda-bld

    alias spyderapp="$HOME/Applications/Spyder.app/Contents/MacOS/spyder"

    alias spy-build-installers="$SPYDEV/spy-build-installers.sh"
    alias spy-build-sign-notarize="$SPYDEV/spy-build-sign-notarize.sh"
    alias spy-clone-subrepo="$SPYDEV/spy-clone-subrepo.sh"
    alias spy-env="$SPYDEV/spy-env.sh"
    alias spy-install-spyder-kernels="$SPYDEV/spy-install-spyder-kernels.sh"
    alias spy-install-dev-repos="mamba run --live-stream -n spy-dev python $SPYREPO/install_dev_repos.py"
    alias spy-menuinst="$SPYDEV/spy-menuinst.sh"
    alias spy-update-conda-app="$SPYDEV/spy-update-conda-app.sh"
    alias spy-dev-spyder="mamba run --live-stream -n spy-dev python $SPYREPO/bootstrap.py"
else
    raw_env=($(/usr/bin/env -i bash -c "source $BASH_SOURCE; compgen -va"))
    new_env=($(/usr/bin/env -i bash -c "source $BASH_SOURCE; spy-var; compgen -va"))
    to_remove=($(echo ${raw_env[@]} ${new_env[@]} | tr ' ' '\n' | sort | uniq -u))
    unalias ${to_remove[@]} 2> /dev/null
    unset -v ${to_remove[@]} raw_env new_env to_remove 2> /dev/null
fi

unset help unset_var option OPTIND OPTERR
}
