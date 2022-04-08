# Command-line tools for developing Spyder

# ---- Path variables
DEVROOT=$(cd `dirname ${BASH_SOURCE}`/../ 2> /dev/null && pwd -P)
SPYREPO=${DEVROOT}/spyder
EXTDEPS=${SPYREPO}/external-deps

# ---- Error function
error () {
    [[ -n "$1" ]] && (echo $1; exit 1)
}

# ---- Deactivate Python environments
deactivate-env () {
    echo "Deactivating virtual environments..."

    eval "$(conda shell.bash hook)"
    while [[ ${CONDA_SHLVL} != 0 ]]; do
        conda deactivate
    done

    if [[ ${OSTYPE} == "darwin"* ]]; then
        eval "$(pyenv init -)"
        eval "$(pyenv virtualenv-init -)"
        [[ -n "${PYENV_ACTIVATE_SHELL}" ]] && pyenv deactivate || true
    fi
}

# ---- Install a subrepo
spy-install-subrepo () {(
    [[ "$1" == "python-lsp-server" ]] && export SETUPTOOLS_SCM_PRETEND_VERSION=`python ${SPYREPO}/pylsp_utils.py`
    python -m pip install --no-deps -e ${EXTDEPS}/$1
)}

# ---- Install all subrepos
spy-install-subrepos () {
    echo "Installing subrepos..."

    if [[ -e "${SPYREPO}/install_subrepos.py" ]]; then
        python -bb -X dev -W error ${SPYREPO}/install_subrepos.py --editable --overwrite-standard
    else
        for dep in $(ls ${EXTDEPS}); do
            spy-install-subrepo ${dep}
        done
    fi
}

# ---- Create conda environment
spy-conda-env () {(set -e
THISFUNC=${FUNCNAME}
help()
{ cat <<EOF

${THISFUNC} [-h] [-v PYVER] ENV
Create fresh conda environment ENV with Python version PYVER and spyder
dependents. Dependents are determined from requirements files

  ENV         Environment name
  -h          Display this help
  -v PYVER    Specify the Python version. Default is 3.9.X

EOF
}

    PYVER=3.9

    while getopts "hv:" option; do
        case ${option} in
            h)
                help
                exit;;
            v)
                PYVER=${OPTARG};;
        esac
    done
    shift $((${OPTIND} - 1))

    ENV=$1

    if [[ -z "${ENV}" ]]; then
        error "Please provide environment name"
    fi

    deactivate-env

    echo "Removing conda '${ENV}' environment..."
    conda env remove -q -y -n ${ENV}

    echo "Building conda '${ENV}' environment..."
    [[ "${OSTYPE}" == "darwin"* ]] && PYAPP=python.app
    conda create -n ${ENV} -q -y -c conda-forge python=${PYVER} ${PYAPP} \
        --file ${SPYREPO}/requirements/conda.txt \
        --file ${SPYREPO}/requirements/tests.txt \
        --file ${DEVROOT}/spyder-dev/plugins.txt

    echo "Activating ${ENV}..."
    conda activate ${ENV}

    echo "Installing spyder and dependencies..."
    pip install --no-deps -e ${SPYREPO}

    install-subrepos
)}

# ---- Clone subrepo
spy-clone-subrepo () {(set -e
THISFUNC=${FUNCNAME}
help()
{ cat <<EOF

${THISFUNC} [-d] [-b <BRANCH>] [-h] REPO
Clone python-lsp-server to spyder subrepo

REPO          Repository to clone. Must be in spyder/external-deps
  -d          Clone local repository; otherwise clone from GitHub
  -b BRANCH   Clone from branch BRANCH; otherwise clone from HEAD
  -h          Print this help message

EOF
}

    while getopts "hdb:" option; do
        case "${option}" in
            h)
                help
                exit;;
            d)
                DEV=true;;
            b)
                BRANCH=${OPTARG};;
        esac
    done
    shift $((${OPTIND} - 1))

    REPO=$1
    if [[ -z "${REPO}" || ! -d "${EXTDEPS}/${REPO}" ]]; then
        error "Please specify a repository from spyder/external-deps."
    fi

    if [[ "${DEV}" = true ]]; then
        CLONE=${DEVROOT}/${REPO}
        : ${BRANCH:=`git -C ${CLONE} branch --show-current`}
    else
        case ${REPO} in
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

#     echo "CLONE = ${CLONE}; DEV = ${DEV}; BRANCH = ${BRANCH}; REPO = ${REPO}"
    git -C ${SPYREPO} subrepo clone ${CLONE} external-deps/${REPO} -b ${BRANCH} -f
)}

# ---- Create build environment
spy-build-env () {(set -e
THISFUNC=${FUNCNAME}
help()
{ cat <<EOF

${THISFUNC} [-h] [-v PYVER] ENV
Create fresh pyenv environment ENV with Python version PYVER and install spyder
dependents. Dependents are determined from the current spyder repo and

  ENV         Environment name
  -h          Display this help
  -v PYVER    Specify the Python version. Default is 3.9.9

EOF
}

    PYVER=3.9.9

    while getopts "hv:" option; do
        case ${option} in
            h)
                help
                exit;;
            v)
                PYVER=${OPTARG};;
        esac
    done
    shift $((${OPTIND} - 1))

    ENV=$1

    if [[ -z "${ENV}" ]]; then
        error "Please specify environment name."
    fi

    if [[ -z `brew list --versions tcl-tk` ]]; then
        echo -e "Installing Tcl/Tk...\n"
        brew install tcl-tk
    else
        echo -e "Tcl/Tk already installed."
    fi
    if [[ -z `pyenv versions | grep ${PYVER}` ]]; then
        echo -e "Installing Python ${PYVER}...\n"
        TKPREFIX=$(brew --prefix tcl-tk)
        export PYTHON_CONFIGURE_OPTS="--enable-framework --with-tcltk-includes=-I${TKPREFIX}/include --with-tcltk-libs='-L${TKPREFIX}/lib -ltcl8.6 -ltk8.6'"
        pyenv install ${PYVER}
    else
        echo -e "Python $"PYVER" already installed."
    fi

    deactivate-env

    if [[ -n `pyenv versions | grep ${ENV}` ]]; then
        echo "Removing pyenv ${ENV} environment..."
        pyenv uninstall -f ${ENV}
    fi

    echo "Building pyenv ${ENV} environment..."
    pyenv virtualenv ${PYVER} ${ENV}

    echo "Activating pyenv ${ENV} environment..."
    pyenv activate ${ENV}

    python -m pip install -U pip setuptools wheel

    echo -e "\nInstalling build dependencies and extras...\n"
    INSTALLDIR=${SPYREPO}/installers/macOS
    REQFILES=()
    for f in $(ls ${INSTALLDIR}); do
        [[ "$f" = req-* ]] && REQFILES+=("-r" "${INSTALLDIR}/$f") || true
    done

    # python -m pip install -e ../py2app

    python -m pip install ${REQFILES[@]} -e ${SPYREPO}

    spy-install-subrepos
)}
