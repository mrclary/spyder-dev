# Command-line tools for managing Spyder development environments

# ---- Path variables
DEVROOT=$(cd $(dirname $BASH_SOURCE)/../ 2> /dev/null && pwd -P)
SPYREPO=$DEVROOT/spyder
EXTDEPS=$SPYREPO/external-deps

# ---- Error function
error () {
    [[ -n "$1" ]] && (echo $1; exit 1)
}

# ---- Shell inits
shell-init () {
    echo "Initializing $1..."
    case $1 in
        (pyenv)
            if [[ -n "$PYENV_ROOT" && -n "$PYENV_VIRTUALENV_INIT" ]]; then
                eval "$(pyenv init --path)"
                eval "$(pyenv init -)"
                eval "$(pyenv virtualenv-init -)"
            else
                error "No PYENV_ROOT or PYENV_VIRTUALENV_INIT"
            fi;;
        (umamba|micromamba)
            if [[ -n "$MAMBA_EXE" ]]; then
                eval "$($MAMBA_EXE shell hook)"
            else
                error "No MAMBA_EXE, falling back to conda"
            fi;;
        (conda)
            if [[ -n "$CONDA_EXE" ]]; then
                eval "$($CONDA_EXE shell.bash hook)"
            else
                error "No CONDA_EXE"
            fi;;
    esac
}

# ---- Deactivate Python environments
deactivate-env () {
    echo "Deactivating virtual environments..."

    while [[ -n $CONDA_SHLVL && $CONDA_SHLVL != 0 ]]; do
        conda deactivate || micromamba deactivate || true
    done

    [[ -n "$PYENV_VERSION" ]] && pyenv deactivate || true
}

# ---- Install a subrepo
spy-install-subrepo () {(
    if [[ "$1" = "python-lsp-server" && -e $SPYREPO/pylsp_utils.py ]]; then
        export SETUPTOOLS_SCM_PRETEND_VERSION=$(python $SPYREPO/pylsp_utils.py)
    fi
    python -m pip install --no-deps -e $EXTDEPS/$1
)}

# ---- Install all subrepos
spy-install-subrepos () {(set -e
    echo "Installing subrepos..."

    if [[ -z "$CONDA_DEFAULT_ENV" && -z "$PYENV_VERSION" ]]; then
        error "Do not install subrepos into base environment. Activate an environment first."
    fi
    if [[ -e "$SPYREPO/install_dev_repos.py" ]]; then
        python -bb -X dev -W error $SPYREPO/install_dev_repos.py --no-install spyder
    else
        for dep in $(ls $EXTDEPS); do
            spy-install-subrepo $dep
        done
    fi
)}

# ---- Create conda environment
spy-env () {(set -e
THISFUNC=$FUNCNAME
help()
{ cat <<EOF

$THISFUNC [-h] [-v PYVER] [-u] ENV
Create spyder environment ENV with Python version PYVER and spyder dependents.
Dependents are determined from requirements files.

A development type environment installs spyder and core dependencies in develop
mode using pip's -e flag. If a conda environment, conda-forge channel is used.

  ENV         Environment name

  -h          Display this help

  -e          ('conda' | 'umamba' | 'pyenv'). Dev environment interpreter. If
              environment type is 'build' then this option is ignored and a
              pyenv virtual environment is created.

  -t          Environment type. ('build' | 'dev'). Default is 'dev'.

  -v PYVER    Specify the Python version. Default is 3.10.X

EOF
}

CMD=conda
PYVER=3.10

    while getopts ":he:t:v:" option; do
        case $option in
            (h) help; exit;;
            (e) CMD=$OPTARG;;
            (t) TYPE=$OPTARG;;
            (v) PYVER=$OPTARG;;
        esac
    done
    shift $(($OPTIND - 1))

    ENV=$1
    if [[ -z "$ENV" ]]; then
        error "Please provide environment name"
    fi

    [[ "$CMD" = "umamba" ]] && CMD=micromamba || true
    [[ "$TYPE" = "build" ]] && CMD=pyenv || true

    shell-init $CMD
    deactivate-env

    echo "Updating micromamba..."
    umamba_url=https://micro.mamba.pm/api/micromamba
    pushd $SPYREPO/spyder
    if [[ "$OSTYPE" == "darwin"* ]]; then
        curl -Ls $umamba_url/osx-64/latest | tar -xvj bin/micromamba
    else
        wget -qO-$umamba_url/linux-64/latest | tar -xvj /bin/micromamba
    fi
    popd

    if [[ "$CMD" != "pyenv" ]]; then
        echo "Building $CMD '$ENV' environment..."
        # [[ "$OSTYPE" == "darwin"* ]] && SPEC=("python.app") || SPEC=()
        SPEC=()
        SPEC+=("--file" "$SPYREPO/requirements/conda.txt")
        SPEC+=("--file" "$SPYREPO/requirements/tests.txt")
        SPEC+=("--file" "$DEVROOT/spyder-dev/plugins.txt")
        $CMD create -n $ENV -q -y -c conda-forge python=$PYVER ${SPEC[@]}
    else
        if [[ -z "$(brew list --versions tcl-tk)" ]]; then
            echo -e "Installing Tcl/Tk...\n"
            brew install tcl-tk
        else
            echo -e "Tcl/Tk already installed."
        fi

        PYVER=$(pyenv install --list | egrep "^\s*$PYVER[0-9.]*" | tail -1)
        if [[ -z "$(pyenv versions | grep $PYVER)" ]]; then
            echo -e "Installing Python $PYVER...\n"
            TKPREFIX=$(brew --prefix tcl-tk)
            PCO=("--enable-framework" "--with-tcltk-includes=-I$TKPREFIX/include")
            PCO+=("--with-tcltk-libs='-L$TKPREFIX/lib -ltcl8.6 -ltk8.6'")
            export PYTHON_CONFIGURE_OPTS="${PCO[@]}"
            pyenv install $PYVER
        else
            echo -e "Python $PYVER already installed."
        fi

        echo "Building $CMD '$ENV' environment..."
        pyenv virtualenv -f $PYVER $ENV
    fi

    echo "Activating $ENV..."
    $CMD activate $ENV

    echo "Installing spyder and dependencies..."
    if [[ "$CMD" = pyenv ]]; then
        python -m pip install -U pip setuptools wheel
    fi

    if [[ "$TYPE" = "build" ]]; then
        INSTALLDIR=$SPYREPO/installers/macOS
        SPEC=()
        for f in $(ls $INSTALLDIR); do
            [[ "$f" = req-* ]] && SPEC+=("-r" "$INSTALLDIR/$f") || true
        done
    else
        SPEC=("--no-deps")
    fi

    python -m pip install ${SPEC[@]} -e $SPYREPO
    spy-install-subrepos
)}

# ---- Clone subrepo
spy-clone-subrepo () {(set -e
THISFUNC=$FUNCNAME
help()
{ cat <<EOF

$THISFUNC [-d] [-b <BRANCH>] [-h] REPO
Clone python-lsp-server to spyder subrepo

REPO          Repository to clone. Must be in spyder/external-deps
  -d          Clone local repository; otherwise clone from GitHub
  -b BRANCH   Clone from branch BRANCH; otherwise clone from HEAD
  -h          Print this help message

EOF
}

    while getopts "hdb:" option; do
        case "$option" in
            h)
                help
                exit;;
            d)
                DEV=true;;
            b)
                BRANCH=$OPTARG;;
        esac
    done
    shift $(($OPTIND - 1))

    REPO=$1
    if [[ -z "$REPO" || ! -d "$EXTDEPS/$REPO" ]]; then
        error "Please specify a repository from spyder/external-deps."
    fi

    if [[ "$DEV" = true ]]; then
        CLONE=$DEVROOT/$REPO
        ${BRANCH:=$(git -C $CLONE branch --show-current)}
    else
        case $REPO in
            python-lsp-server)
                CLONE=https://github.com/python-lsp/python-lsp-server.git
                BRANCH=develop;;
            qdarkstyle)
                CLONE=https://github.com/ColinDuquesnoy/QDarkStyleSheet.git
                BRANCH=develop;;
            qtconsole)
                CLONE=https://github.com/jupyter/qtconsole.git
                BRANCH=4.2.x;;
            spyder-kernels)
                CLONE=https://github.com/spyder-ide/spyder-kernels.git
                BRANCH=2.x;;
        esac
    fi

#     echo "CLONE = $CLONE; DEV = $DEV; BRANCH = $BRANCH; REPO = $REPO"
    git -C $SPYREPO subrepo clone $CLONE external-deps/$REPO -b $BRANCH -f
)}
