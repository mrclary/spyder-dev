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

    export SPYDERAPP=$REPOS/Spyder-IDE/spyder/installers/macOS/dist/Spyder.app
    export SPYPYTHONHOME=$SPYDERAPP/Contents/Resources
    export spyframeworks=$SPYDERAPP/Contents/Frameworks
#     export SPYDER_ARGS="['--debug-info=minimal']"
#     export SPYDER_PID=12345
#     export SPYDER_IS_BOOTSTRAP=False
    export SPYEXECUTABLEPATH=$SPYDERAPP/Contents/MacOS/Spyder

    export CONDA_BLD_PATH=$HOME/.conda/conda-bld

    alias spyderapp="$SPYEXECUTABLEPATH"
    alias spypython="PYTHONHOME=$SPYPYTHONHOME $SPYDERAPP/Contents/MacOS/python"
    alias teststart="spypython $SPYDERAPP/Contents/Resources/lib/python*/spyder/app/start.py"
    alias testrestart="spypython $SPYDERAPP/Contents/Resources/lib/python*/spyder/app/restart.py"

    alias spy-build-installers="$SPYDEV/spy-build-installers.sh"
    alias spy-build-sign-notarize="$SPYDEV/spy-build-sign-notarize.sh"
    alias spy-certkeychain="$ROOT/spyder/installers/macOS/certkeychain.sh"
    alias spy-clone-subrepo="$SPYDEV/spy-clone-subrepo.sh"
    alias spy-codesign="$ROOT/spyder/installers/macOS/codesign.sh"
    alias spy-env="$SPYDEV/spy-env.sh"
    alias spy-install-spyder-kernels="$SPYDEV/spy-install-spyder-kernels.sh"
    alias spy-install-subrepo="$SPYDEV/spy-install-subrepo.sh"
    alias spy-install-subrepos="$SPYDEV/spy-install-subrepos.sh"
    alias spy-menuinst="$SPYDEV/spy-menuinst.sh"
    alias spy-notarize="$ROOT/spyder/installers/macOS/notarize.sh"
    alias spy-update-conda-app="$SPYDEV/spy-update-conda-app.sh"
    alias spy-dev-spyder="mamba run --live-stream -n spy-dev python $SPYREPO/bootstrap.py"
else
    raw_env=($(/usr/bin/env -i bash -c "source $BASH_SOURCE; compgen -va"))
    new_env=($(/usr/bin/env -i bash -c "source $BASH_SOURCE; spy-var; compgen -va"))
    to_remove=($(echo ${raw_env[@]} ${new_env[@]} | tr ' ' '\n' | sort | uniq -u))
#     declare -p to_remove
    unalias ${to_remove[@]} 2> /dev/null
    unset -v ${to_remove[@]} raw_env new_env to_remove 2> /dev/null
fi

unset help unset_var option OPTIND OPTERR
}
