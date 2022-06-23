#!/usr/bin/env bash
set -e

SPYROOT=$(cd $(dirname $BASH_SOURCE)/../ 2> /dev/null && pwd -P)
SPYREPO=$SPYROOT/spyder

ROOT=$HOME/opt
MAN=mambaforge
PYVER_INIT=3.10
TYPE=dev

help() { cat <<EOF

$THISFUNC [-h] [-m MAN] [-t TYPE] [-v PYVER] -n NAME [--]
Create spyder environment ENV with Python version PYVER and spyder dependents.
Dependents are determined from requirements files.

A development type environment installs spyder and core dependencies in develop
mode using pip's -e flag. If a conda environment, conda-forge channel is used.

  NAME        Environment name

  -h          Display this help

  -m MAN      Environment manager. One of "miniconda3", "miniforge3", "mambaforge",
              "micromamba", or "pyenv". Default is "$MAN". If environment type
              is "build" then this option is ignored and a pyenv is used.

  -t TYPE     Environment type. One of "build" or "dev". Default is "dev".

  -v PYVER    Specify the Python version. Default is ${PYVER}.x.

  --          Additional options for create and install

EOF
}

while getopts ":hm:n:t:v:" option; do
    case $option in
        (h) help; exit ;;
        (m) MAN=$OPTARG ;;
        (n) NAME=$OPTARG ;;
        (t) TYPE=$OPTARG ;;
        (v) PYVER_INIT=$OPTARG ;;
    esac
done
shift $(($OPTIND - 1))

if [[ -z "$NAME" ]]; then
    echo "Please provide environment name"; exit 1
fi

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

[[ "$TYPE" = "build" ]] && MAN=pyenv

if [[ "$MAN" = "pyenv" ]]; then
    if [[ -z "$(brew list --versions tcl-tk)" ]]; then
        echo -e "Installing Tcl/Tk...\n"
        brew install tcl-tk
    else
        echo "Tcl/Tk already installed."
    fi

    PYVER=$(pyenv install --list | egrep "^\s*${PYVER_INIT}[0-9.]*" | tail -1 | xargs)
    if [[ -z "$PYVER" ]]; then
        echo "Python $PYVER_INIT is not available."
        exit 1
    fi

    if [[ -z "$(pyenv versions | grep $PYVER)" ]]; then
        echo "Installing Python $PYVER..."
        TKPREFIX=$(brew --prefix tcl-tk)
        PCO=()
        # PCO+=("--enable-universalsdk" "--with-universal-archs=universal2")
        PCO+=("--enable-framework" "--with-tcltk-includes=-I$TKPREFIX/include")
        PCO+=("--with-tcltk-libs='-L$TKPREFIX/lib -ltcl8.6 -ltk8.6'")
        export PYTHON_CONFIGURE_OPTS="${PCO[@]}"
        pyenv install $PYVER
    else
        echo "Python $PYVER already installed."
    fi

    echo "Building $MAN '$NAME' environment..."
    create_opts+=("$PYVER" "$NAME")
    pyenv virtualenv ${create_opts[@]}

    source $HOME/.pyenv/versions/$NAME/bin/activate

    echo "Installing spyder..."
    python -m pip install -U pip setuptools wheel
    if [[ "$TYPE" = "build" ]]; then
        INSTALLDIR=$SPYREPO/installers/macOS
        SPEC=()
        for f in $(ls $INSTALLDIR); do
            [[ "$f" = req-* ]] && SPEC+=("-r" "$INSTALLDIR/$f") || true
        done
    fi
    install_opts=("${run_opts[@]}" "${SPEC[@]}" "-e" "$SPYREPO")
    python -m pip install ${install_opts[@]}
    $SPYROOT/spyder-dev/spy-install-subrepos.sh
else
    # Determine conda flavor package manager command
    while [[ -z "$cmd" ]]; do
        case $MAN in
            (mambaforge)
                cmd="$ROOT/$MAN/bin/mamba" ;;
            (micromamba)
                cmd="$ROOT/$MAN/bin/micromamba" ;;
            (miniconda3|miniforge3)
                cmd="$ROOT/$MAN/bin/conda" ;;
            (*)
                echo "Unrecognized environment manager '$MAN'"
                exit 1 ;;
        esac

        if [[ -e "$cmd" ]]; then
            if [[ "$MAN" = micromamba ]]; then
                export MAMBA_ROOT_PREFIX=${MAMBA_ROOT_PREFIX:-"$ROOT/$MAN"}
            fi
        else
            if [[ "$MAN" = "miniconda3" ]]; then
                echo "$MAN not available"; exit 1
            else
                unset cmd
                echo "$MAN not available; falling back to miniconda3"
                MAN=miniconda3
            fi
        fi
    done

    echo "Building $MAN '$NAME' environment..."
    create_opts=("-n" "$NAME" "${create_opts[@]}")
    create_opts+=("-c" "conda-forge" "python=$PYVER_INIT")
    # [[ "$OSTYPE" == "darwin"* ]] && create_opts+=("python.app")
    create_opts+=("--file=$SPYREPO/requirements/conda.txt")
    create_opts+=("--file=$SPYREPO/requirements/tests.txt")
    create_opts+=("--file=$SPYROOT/spyder-dev/plugins.txt")
    $cmd create ${create_opts[@]}

    echo "Installing spyder..."
    run_opts+=("--no-banner")
    $cmd run ${run_opts[@]} -n $NAME python -m pip install --no-deps -e $SPYREPO
    $cmd run ${run_opts[@]} -n $NAME $SPYROOT/spyder-dev/spy-install-subrepos.sh
fi

echo "Updating micromamba in the spyder repo..."
cd $SPYREPO/spyder
umamba_url=https://micro.mamba.pm/api/micromamba
arch_=$(arch)
[[ "$arch_" = "i386" ]] && arch_=64
if [[ "$OSTYPE" == "darwin"* ]]; then
    curl -Ls $umamba_url/osx-$arch_/latest | tar -xvj bin/micromamba
else
    wget -qO-$umamba_url/linux-$arch_/latest | tar -xvj /bin/micromamba
fi
