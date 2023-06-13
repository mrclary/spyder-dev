#!/usr/bin/env bash
set -e

script_path=${BASH_SOURCE:-${(%):-%x}}
here=$(dirname $script_path)
src_inst_dir=$(cd $here/../spyder/installers-conda 2> /dev/null && pwd)

if [[ -z $CONDA_PREFIX || -z $(which constructor) ]]; then
    echo "Activate a conda environment with constructor installed to use $(basename $script_path)"
    exit 1
fi

help(){ cat <<EOF
$(basename $script_path) [options]

Build conda packages, build package installer, notarize the package, and/or
install the package for user.

Options:
  -h          Display this help

  -a          Perform all operations: build conda packages; build package
              installer; notarize package installer; and install package.
              Equivalent to -c -p -n -i

  -c          Build conda packages for Spyder and external-deps. Uses
              build_conda_pkgs.py.

  -p          Build package installer (.pkg/.sh). Uses build_installers.py

  -n          Notarize the package installer. Uses notarize.sh

  -i          Install the package to the current user

  -C OPTIONS  Options for building conda packages. This should be a single
              string of space-separated options, e.g.
              "--debug --build spyder"

  -P OPTIONS  Options for building the package installer. This should be a
              single string of space-separated options, e.g.
              "--no-local --debug"

  -N OPTIONS  Options for notarizing the package installer. This should be a
              single string of space-separated options, e.g.
              "-v -p PASSWORD". macOS only.

  -I OPTIONS  Options for installing the package installer. This should be a
              single string of space-separated options, e.g. "-bfk". .sh
              installers only.

------------------------------------------------------------------------------

$(python $src_inst_dir/build_conda_pkgs.py --help)

------------------------------------------------------------------------------

$(python $src_inst_dir/build_installers.py --help)

------------------------------------------------------------------------------

$($src_inst_dir/notarize.sh -h)

EOF
}

exec 3>&1  # Additional output descriptor for logging
log(){
    level="INFO"
    echo "$(date "+%Y-%m-%d %H:%M:%S") [$level] [build] -> $@" 1>&3
}

build_conda_opts=()
build_pkg_opts=()
notarize_opts=()

OIFS=$IFS
IFS=' '
while getopts ":hacpniC:P:N:I:" option; do
    case $option in
        (h) help | less; exit ;;
        (a) ALL=0 ;;
        (c) BUILDCONDA=0 ;;
        (p) BUILDPKG=0 ;;
        (n) NOTARIZE=0 ;;
        (i) INSTALL=0 ;;
        (C) build_conda_opts+=($OPTARG) ;;
        (P) build_pkg_opts+=($OPTARG) ;;
        (N) notarize_opts+=($OPTARG) ;;
        (I) install_opts+=($OPTARG) ;;
    esac
done
shift $(($OPTIND - 1))
IFS=$OIFS
unset OIFS

if [[ -n $ALL ]]; then
    BUILDCONDA=0
    BUILDPKG=0
    NOTARIZE=0
    INSTALL=0
fi

# ---- Build conda packages
export CONDA_BLD_PATH=$HOME/.conda/conda-bld

if [[ -n $BUILDCONDA ]]; then
    log "Building conda packages..."
    python $src_inst_dir/build_conda_pkgs.py ${build_conda_opts[@]}
    log "Building conda packages complete"
else
    log "Not building conda packages"
fi

# ---- Build keychain
if [[ (-n $BUILDPKG || -n $NOTARIZE) && $OSTYPE = "darwin"* ]]; then
    trap "security list-keychain -s login.keychain; rm -rf certificate.p12" EXIT
    source "$here/~cert/cert.sh"
    $src_inst_dir/certkeychain.sh $MACOS_CERTIFICATE_PWD $MACOS_CERTIFICATE $MACOS_INSTALLER_CERTIFICATE "$here/~cert/DeveloperIDG2CA.cer"
fi

# ---- Build installer pkg
if [[ -n $BUILDPKG ]]; then
    log "Building installer..."
    if [[ $OSTYPE = "darwin"* ]]; then
        _codesign=$(which codesign)
        if [[ $_codesign =~ ${CONDA_PREFIX}.* ]]; then
            # Find correct codesign
            log "Moving $_codesign..."
            mv $_codesign ${_codesign}.bak
        fi

        CNAME=$(security find-identity -p codesigning -v | pcre2grep -o1 "\(([0-9A-Z]+)\)")
        build_pkg_opts+=("--cert-id=$CNAME")
    fi
    python $src_inst_dir/build_installers.py ${build_pkg_opts[@]}
else
    log "Not building installer"
fi

if [[ -n $INSTALL || -n $NOTARIZE ]]; then
    pkg_name="$(python $src_inst_dir/build_installers.py --artifact-name)"
    base_name=$(echo $pkg_name | pcre2grep -io1 ".*(spyder-\d+.\d+.\d+(.dev\d+)?).*")
fi

if [[ -n $INSTALL ]]; then
    # Remove previous install
    log "Uninstall previous installation..."
    if [[ $OSTYPE = "darwin"* ]]; then
        shortcut_path=$HOME/Applications/Spyder.app
        inst_dir=$HOME/Library/$base_name
        rm -rf $src_inst_dir/dist/pkg
    else
        shortcut_path=$HOME/.local/share/applications/spyder.desktop
        inst_dir=$HOME/.local/$base_name
    fi
    rm -rf $shortcut_path
    rm -rf $inst_dir

    # Run installer
    log "Installing Spyder standalone application..."
    if [[ $OSTYPE = "darwin"* ]]; then
        # pkgutil --expand-full $src_inst_dir/dist/$pkg_name $src_inst_dir/dist/pkg
        installer -dumplog -pkg $pkg_name -target CurrentUserHomeDirectory 2>&1

        if [[ -e "$shortcut_path" ]]; then
            log "Spyder.app info:"
            tree $shortcut_path
            cat $shortcut_path/Contents/Info.plist
            echo ""
            cat $shortcut_path/Contents/MacOS/spyder-script
            echo ""
        else
            log "$shortcut_path does not exist"
        fi
    else
        "$pkg_name" ${install_opts[@]}
    fi
else
    log "Not installing"
fi

if [[ -n $NOTARIZE && $OSTYPE = "darwin"* ]]; then
    $src_inst_dir/notarize.sh ${notarize_opts[@]} $pkg_name
else
    log "Not notarizing"
fi
