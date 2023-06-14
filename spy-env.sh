#!/usr/bin/env bash
set -e

SPYROOT=$(cd $(dirname $BASH_SOURCE)/../ 2> /dev/null && pwd -P)
SPYREPO=$SPYROOT/spyder

TYPE="dev"
MAN=mambaforge
PYVER_INIT=3.10

help() { cat <<EOF

$(basename $0) [options] NAME

Create an environment for developing or building Spyder.

Options:
  -h          Display this help

  -t          Envrionment type. One of "dev", "mac-build", or "conda-build". Default
              is "dev". mac-build is a pyenv environment suitable for building the
              macOS standalone application bundle and dmg file. conda-build is a
              conda environment suitable for building the conda-based installers.
              dev is a conda environment for developing Spyder.

  -p          Install external plugins in the environment

  -m MAN      Environment manager. One of "miniconda3", "miniforge3", "mambaforge",
              "micromamba", or "pyenv". Default is "$MAN". Only applies to dev and
              mac-build types.

  -v PYVER    Specify the Python version. Default is ${PYVER_INIT}.x.

  -C OPTIONS  Options passed to environment creation mechanism. Single string of
              space-separated options.

  -I OPTIONS  Options passed to Spyder installation mechanism. Single string of
              space-separated options. Only applies to dev and mac-build types.

  -U OPTIONS  Options passed to environment update mechanism. Single string of
              space-separated options. Only applies to dev and conda-build types.

  NAME        Environment name

Notes:
Following is a list of the essential commands used to build each environment type,
indicating the context for the -C -I -U options.

dev:
    mamba create -n NAME -c conda-forge [C OPTIONS] python=PYVER
    mamba env update -n NAME [U OPTIONS] --file <file>
    mamba run -n NAME --no-capture-output [I OPTIONS] python $SPYREPO/install_dev_repos.py

mac-build:
    pyenv virtualenv [C OPTIONS]
    python -m pip install [I OPTIONS] -f <file> -f <file> ... -e <spyder-repo>
    python <spyder-repo>/install_dev_repos.py --no-install spyder

conda-build:
    mamba create -n NAME -c conda-forge [C OPTIONS] python=PYVER
    mamba env update -n NAME [U OPTIONS] --file <spyder-repo>/installers-conda/build-environment.yml

EOF
}

exec 3>&1  # Additional output descriptor for logging
log(){
    level="INFO"
    echo "$(date "+%Y-%m-%d %H:%M:%S") [$level] [spy-env] -> $@" 1>&3
}

create_opts=()
install_opts=()
update_opts=()

OIFS=$IFS
IFS=' '
while getopts ":ht:pm:v:C:I:U:" option; do
    case $option in
        (h) help; exit ;;
        (t) case $OPTARG in
            (dev|mac-build|conda-build)
                TYPE=$OPTARG ;;
            (*)
                log "Unrecognized value for TYPE: $OPTARG"
                help; exit 1 ;;
            esac ;;
        (p) PLUGINS=1 ;;
        (m) MAN=$OPTARG ;;
        (v) PYVER_INIT=$OPTARG ;;
        (C) create_opts+=($OPTARG) ;;
        (I) install_opts+=($OPTARG) ;;
        (U) update_opts+=($OPTARG) ;;
    esac
done
shift $(($OPTIND - 1))
IFS=$OIFS
unset OIFS

if [[ $# = 0 ]]; then
    log "Please provide environment name"
    exit 1
fi

NAME=$1; shift

if [[ "$TYPE" = "mac-build" ]]; then
    MAN="pyenv"
    log "Building macOS standalone build environment..."

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
    pyenv virtualenv ${create_opts[@]} $PYVER $NAME

    source $HOME/.pyenv/versions/$NAME/bin/activate

    python -m pip install -U pip setuptools wheel

    log "Installing spyder..."
    INSTALLDIR=$SPYREPO/installers/macOS
    SPEC=("importlib-metadata")
    for f in $(ls $INSTALLDIR); do
        [[ "$f" = "req-plugins.txt" && -z $PLUGINS ]] && continue
        [[ "$f" = req-* ]] && SPEC+=("-r" "$INSTALLDIR/$f")
    done
    python -m pip install ${install_opts[@]} ${SPEC[@]} -e $SPYREPO
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

    log "Creating $MAN '$NAME' $TYPE environment..."
    create_opts=("-n" "$NAME" "-c" "conda-forge" "${create_opts[@]}")
    $cmd create ${create_opts[@]} python=$PYVER_INIT
    update_opts=("env" "update" "-n" "$NAME" "${update_opts[@]}")

    if [[ $TYPE == "dev" ]]; then
        # Developer environment
        log "Installing main requirements..."
        $cmd ${update_opts[@]} --file $SPYREPO/requirements/main.yml

        log "Installing platform-specific requirements..."
        if [[ "$OSTYPE" = "darwin"* ]]; then
            $cmd ${update_opts[@]} --file $SPYREPO/requirements/macos.yml
        else
            $cmd ${update_opts[@]} --file $SPYREPO/requirements/linux.yml
        fi

        log "Installing testing requirements..."
        $cmd ${update_opts[@]} --file $SPYREPO/requirements/tests.yml

        if [[ -n $PLUGINS ]]; then
            log "Installing external plugins..."
            $cmd update -n $NAME -c conda-forge --file $SPYROOT/spyder-dev/plugins.txt
        fi

        log "Installing spyder and external_deps..."
        install_opts=("-n" "$NAME" "--no-capture-output" "${install_opts[@]}")
        $cmd run ${install_opts[@]} python $SPYREPO/install_dev_repos.py
    else
        # Conda-based installer build environment
        log "Installing conda-based installer build requirements..."
        $cmd ${update_opts[@]} --file $SPYREPO/installers-conda/build-environment.yml
    fi
fi

if [[ $TYPE != "conda-build" ]]; then
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
fi
