# Command-line tools for managing Spyder development environments

spy-var () {
help () { cat <<EOF

$FUNCNAME [-h] [-u]

Set or unset Spyder development environment variables

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
    SPYROOT=$(cd $(dirname ${BASH_SOURCE:-${(%):-%x}})/../ 2> /dev/null && pwd -P)
    SPYREPO=$SPYROOT/spyder
    EXTDEPS=$SPYREPO/external-deps

    export SPYDERAPP=$REPOS/Spyder-IDE/spyder/installers/macOS/dist/Spyder.app
    export SPYPYTHONHOME=$SPYDERAPP/Contents/Resources
    export spyframeworks=$SPYDERAPP/Contents/Frameworks
#     export SPYDER_ARGS="['--debug-info=minimal']"
#     export SPYDER_PID=12345
#     export SPYDER_IS_BOOTSTRAP=False
    export SPYEXECUTABLEPATH=$SPYDERAPP/Contents/MacOS/Spyder

    alias spyderapp="$SPYEXECUTABLEPATH"
    alias spypython="PYTHONHOME=$SPYPYTHONHOME $SPYDERAPP/Contents/MacOS/python"
    alias teststart="spypython $SPYDERAPP/Contents/Resources/lib/python*/spyder/app/start.py"
    alias testrestart="spypython $SPYDERAPP/Contents/Resources/lib/python*/spyder/app/restart.py"
    alias spy-install-subrepo="$SPYROOT/spyder-dev/spy-install-subrepo.sh"
    alias spy-install-subrepos="$SPYROOT/spyder-dev/spy-install-subrepos.sh"
    alias spy-env="$SPYROOT/spyder-dev/spy-env.sh"
    alias spy-clone-subrepo="$SPYROOT/spyder-dev/spy-clone-subrepo.sh"
    alias spy-certkeychain="$SPYROOT/spyder/installers/macOS/certkeychain.sh"
    alias spy-codesign="$SPYROOT/spyder/installers/macOS/codesign.sh"
    alias spy-notarize="$SPYROOT/spyder/installers/macOS/notarize.sh"
    alias spy-build-sign-notarize="$SPYROOT/spyder-dev/spy-build-sign-notarize.sh"
else
    raw_env=($(/usr/bin/env -i bash -c "source $BASH_SOURCE; compgen -va"))
    new_env=($(/usr/bin/env -i bash -c "source $BASH_SOURCE; spy-var; compgen -va"))
    to_remove=($(echo ${raw_env[@]} ${new_env[@]} | tr ' ' '\n' | sort | uniq -u))
#     declare -p to_remove
    unalias ${to_remove[@]} 2> /dev/null
    unset -v ${to_remove[@]} raw_env new_env to_remove
fi

unset help unset_var option OPTIND OPTERR
}
