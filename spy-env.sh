#!/usr/bin/env bash
set -e

SPYROOT=$(cd $(dirname $BASH_SOURCE)/../ 2> /dev/null && pwd -P)
SPYREPO=$SPYROOT/spyder

MAN=mambaforge
PYVER_INIT=3.10

help() { cat <<EOF

$(basename $0) [-h] [-m MAN] [-v PYVER] NAME [--]

Create spyder environment ENV with Python version PYVER and spyder dependents.
Dependents are determined from requirements files.

Spyder and core dependencies are installed in develop mode using pip's -e flag.
If a conda environment, conda-forge channel is used.

Options:
  -h          Display this help

  -m MAN      Environment manager. One of "miniconda3", "miniforge3", "mambaforge",
              "micromamba", or "pyenv". Default is "$MAN".

  -v PYVER    Specify the Python version. Default is ${PYVER}.x.

  NAME        Environment name

  --          Additional options for create and install

EOF
}

exec 3>&1  # Additional output descriptor for logging
log(){
    level="INFO"
    echo "$(date "+%Y-%m-%d %H:%M:%S") [$level] [spy-env] -> $@" 1>&3
}

while getopts ":hm:v:" option; do
    case $option in
        (h) help; exit ;;
        (m) MAN=$OPTARG ;;
        (v) PYVER_INIT=$OPTARG ;;
    esac
done
shift $(($OPTIND - 1))

if [[ $# = 0 ]]; then
    log "Please provide environment name"
    exit 1
fi

NAME=$1; shift

# Remaining arguments passed to create and install
create_opts=()
run_opts=()
for opt in $@; do
    create_opts+=("$opt")
    case $opt in
        (-v|--verbose)
            run_opts+=("$opt") ;;
        (-d|--dry-run)
            dry_run=0 ;;
    esac
done

if [[ "$MAN" = "pyenv" ]]; then
    if [[ -z "$(brew list --versions tcl-tk)" ]]; then
        log "Installing Tcl/Tk..."
        brew install tcl-tk
    else
        log "Tcl/Tk already installed."
    fi

    PYVER=$(pyenv install --list | egrep "^\s*${PYVER_INIT}[0-9.]*" | tail -1 | xargs)
    if [[ -z "$PYVER" ]]; then
        log "Python $PYVER_INIT is not available."
        exit 1
    fi

    if [[ -z "$(pyenv versions | grep $PYVER)" ]]; then
        log "Installing Python $PYVER..."
        TKPREFIX=$(brew --prefix tcl-tk)
        PCO=()
        # PCO+=("--enable-universalsdk" "--with-universal-archs=universal2")
        PCO+=("--enable-framework" "--with-tcltk-includes=-I$TKPREFIX/include")
        PCO+=("--with-tcltk-libs='-L$TKPREFIX/lib -ltcl8.6 -ltk8.6'")
        export PYTHON_CONFIGURE_OPTS="${PCO[@]}"
        pyenv install $PYVER
    else
        log "Python $PYVER already installed."
    fi

    log "Building $MAN '$NAME' environment..."
    create_opts+=("$PYVER" "$NAME")
    pyenv virtualenv ${create_opts[@]}

    source $HOME/.pyenv/versions/$NAME/bin/activate

    python -m pip install -U pip setuptools wheel

    log "Installing spyder..."
    INSTALLDIR=$SPYREPO/installers/macOS
    SPEC=("importlib-metadata")
    for f in $(ls $INSTALLDIR); do
        [[ "$f" = req-* ]] && SPEC+=("-r" "$INSTALLDIR/$f") || true
    done
    install_opts=("${run_opts[@]}" "${SPEC[@]}" "-e" "$SPYREPO")
    python -m pip install ${install_opts[@]}
    python $SPYREPO/install_dev_repos.py --no-install spyder
else
    # Determine conda flavor package manager command
    while [[ -z "$cmd" ]]; do
        case $MAN in
            (mambaforge)
                cmd="$(which mamba)" ;;
            (micromamba)
                cmd="$MAMBA_EXE" ;;
            (miniconda3|miniforge3)
                cmd="$(which conda)" ;;
            (*)
                log "Unrecognized environment manager '$MAN'"
                exit 1 ;;
        esac

        if [[ ! -e "$cmd" || "$cmd" != *"$MAN"* ]]; then
            if [[ "$MAN" = "miniconda3" ]]; then
                log "$MAN not available"; exit 1
            else
                unset cmd
                log "$MAN not available; falling back to miniconda3"
                MAN=miniconda3
            fi
        fi
    done

    log "Building $MAN '$NAME' environment..."
    create_opts=("-n" "$NAME" "${create_opts[@]}")
    create_opts+=("-c" "conda-forge" "python=$PYVER_INIT")
    $cmd create ${create_opts[@]}
    update_opts=("env" "update" "-n" "$NAME")
    $cmd ${update_opts[@]} --file $SPYREPO/requirements/main.yml
    if [[ "$OSTYPE" = "darwin"* ]]; then
        $cmd ${update_opts[@]} --file $SPYREPO/requirements/macos.yml
    else
        $cmd ${update_opts[@]} --file $SPYREPO/requirements/linux.yml
    fi
    $cmd ${update_opts[@]} --file $SPYREPO/requirements/tests.yml
    $cmd --no-banner update -n $NAME -c conda-forge --file $SPYROOT/spyder-dev/plugins.txt

    log "Installing spyder..."
    run_opts+=("--no-capture-output")
    if [[ "$MAN" = *"mamba"* ]]; then
        run_opts+=("--no-banner")
    fi
    $cmd run ${run_opts[@]} -n $NAME python $SPYREPO/install_dev_repos.py
fi

log "Updating micromamba in the spyder repo..."
cd $SPYREPO/spyder
umamba_url=https://micro.mamba.pm/api/micromamba
arch_=$(arch)
[[ "$arch_" = "i386" || "$arch_" = "x86_64" ]] && arch_=64
if [[ "$OSTYPE" = "darwin"* ]]; then
    curl -Ls $umamba_url/osx-$arch_/latest | tar -xvj bin/micromamba
else
    wget -qO- $umamba_url/linux-$arch_/latest | tar -xvj bin/micromamba
fi
