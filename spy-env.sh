#!/usr/bin/env bash
set -e

SPYROOT=$(dirname $(dirname ${BASH_SOURCE:-${(%):-%x}}))
SPYREPO=$SPYROOT/spyder

TYPE="dev"
MAN=mambaforge
PYVER_INIT=3.11

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
while getopts ":ht:pv:n:C:I:U:" option; do
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
        (v) PYVER_INIT=$OPTARG ;;
        (n) NAME=$OPTARG ;;
        (C) create_opts+=($OPTARG) ;;
        (I) install_opts+=($OPTARG) ;;
        (U) update_opts+=($OPTARG) ;;
    esac
done
shift $(($OPTIND - 1))
IFS=$OIFS
unset OIFS

if [[ "$TYPE" = "mac-build" ]]; then
    NAME=${NAME:-spy-build}

    log "Building '$NAME' macOS standalone build environment..."

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
        PCO=()
        # PCO+=("--enable-universalsdk" "--with-universal-archs=universal2")
        PCO+=("--enable-framework")
        PCO+=("--with-tcltk-includes='$(pkg-config tk tcl --cflags)'")
        PCO+=("--with-tcltk-libs='$(pkg-config tk tcl --libs)'")
        export PYTHON_CONFIGURE_OPTS="${PCO[@]}"
        pyenv install $PYVER
    else
        log "Python $PYVER already installed."
    fi

    log "Building '$NAME' pyenv environment..."
    pyenv virtualenv ${create_opts[@]} $PYVER $NAME

    source $HOME/.pyenv/versions/$NAME/bin/activate

    python -m pip install -U pip setuptools wheel

    log "Installing micromamba in Spyder repo..."
    pushd $SPYREPO
    [[ "$(arch)" == "arm64" ]] && platform=osx-arm64 || platform=osx-64
    curl -Ls https://micro.mamba.pm/api/micromamba/${platform}/latest | tar -xvj bin/micromamba
    install_name_tool -change @rpath/libc++.1.dylib /usr/lib/libc++.1.dylib bin/micromamba
    popd

    log "Installing spyder..."
    INSTALLDIR=$SPYREPO/installers/macOS
    SPEC=("importlib-metadata")
    for f in $(ls $INSTALLDIR); do
        [[ "$f" = "req-plugins.txt" && -z $PLUGINS ]] && continue
        [[ "$f" = req-* ]] && SPEC+=("-r" "$INSTALLDIR/$f")
    done
    python -m pip install ${install_opts[@]} ${SPEC[@]} -e $SPYREPO
    python $SPYREPO/install_dev_repos.py --not-editable --no-install spyder
else
    if [[ -z "$NAME" ]]; then
        [[ "$TYPE" == "dev" ]] && NAME=spy-dev || NAME=spy-inst
    fi
    log "Creating conda '$NAME' $TYPE environment..."

    CONDA_CHANNEL_PRIORITY=flexible
    cmd=$(which conda)

    create_opts=("-n" "$NAME" "-c" "conda-forge" "--override-channels" "${create_opts[@]}")
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
        install_opts=("-n" "$NAME" "--live-stream" "${install_opts[@]}")
        $cmd run ${install_opts[@]} python $SPYREPO/install_dev_repos.py
    else
        # Conda-based installer build environment
        log "Installing conda-based installer build requirements..."
        $cmd ${update_opts[@]} --file $SPYREPO/installers-conda/build-environment.yml
    fi
fi
