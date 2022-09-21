#!/usr/bin/env bash
set -e

help(){ cat <<EOF
$(basename $0) [-h] [-a | [-c] [-p] [-n] [-i]] [-v] [-C] [-P] [-N]
Build conda packages, build package installer, notarize the package, and/or
install the package for user.

Options:
  -h          Display this help

  -a          Perform all operations: build conda packages; build package
              installer; notarize package installer; and install package.
              Equivalent to -c -p -n -i

  -c          Build conda packages for Spyder and external-deps. Uses
              build_conda_pkgs.py.

  -p          Build package installer (.pkg). Uses build_installers.py

  -n          Notarize the package installer. Uses notarize.sh

  -i          Install the package to the current user

  -C OPTIONS  Options for building conda packages. This should be a single
              string of space-separated options, e.g.
              "--debug --skip-external-deps"

  -P OPTIONS  Options for building the package installer. This should be a
              single string of space-separated options, e.g.
              "--no-local --debug"

  -N OPTIONS  Options for notarizing the package installer. This should be a
              single string of space-separated options, e.g.
              "-v -p PASSWORD"

EOF
}

exec 3>&1  # Additional output descriptor for logging
log(){
    level="INFO"
    date "+%Y-%m-%d %H:%M:%S [$level] [build] -> $1" 1>&3
}

build_conda_opts=()
build_pkg_opts=()
notarize_opts=()

OIFS=$IFS
IFS=' '
while getopts ":hacpniC:P:N:" option; do
    case $option in
        (h) help; exit ;;
        (a) ALL=0 ;;
        (c) BUILDCONDA=0 ;;
        (p) BUILDPKG=0 ;;
        (n) NOTARIZE=0 ;;
        (i) INSTALL=0 ;;
        (C) build_conda_opts+=($OPTARG) ;;
        (P) build_pkg_opts+=($OPTARG) ;;
        (N) notarize_opts+=($OPTARG) ;;
    esac
done
shift $(($OPTIND - 1))
IFS=$OIFS
unset OIFS

if [[ -n $all ]]; then
    BUILDCONDA=0
    BUILDPKG=0
    NOTARIZE=0
    INSTALL=0
fi

here=$(dirname ${BASH_SOURCE:-${(%):-%x}})
inst_dir=$(cd $here/../spyder/installers-conda 2> /dev/null && pwd)

# ---- Build conda packages
if [[ -n $BUILDCONDA ]]; then
    log "Building conda packages..."
    python $inst_dir/build_conda_pkgs.py ${build_conda_opts[@]}
fi

# ---- Build installer pkg
if [[ -n $BUILDPKG || -n $NOTARIZE ]]; then
    CNAME=$(security find-identity -p codesigning -v | pcregrep -o1 "\(([0-9A-Z]+)\)")
    log "Certificate ID: $CNAME"
fi

if [[ -n $BUILDPKG ]]; then
    log "Bulding installer pkg..."
    export CONSTRUCTOR_SIGNING_IDENTITY=$CNAME
    export CONSTRUCTOR_NOTARIZATION_IDENTITY=$CNAME
    python $inst_dir/build_installers.py ${build_pkg_opts[@]}
fi

if [[ -n $NOTARIZE || -n $INSTALL ]]; then
    pkg_name="$(python $inst_dir/build_installers.py --artifact-name)"
fi

if [[ -n $NOTARIZE ]]; then
    _codesign=$(which codesign)
    if [[ $_codesign =~ ${CONDA_PREFIX}.* ]]; then
        # Find correct codesign
        log "Moving $_codesign"
        mv $_codesign ${_codesign}.bak
    fi

    $inst_dir/notarize.sh $pkg_name ${notarize_opts[@]}
fi

if [[ -n $INSTALL ]]; then
    # Remove previous install
    log "Removing previous artifacts..."
    app_path=~/Applications/Spyder.app
    rm -rf $app_path
    rm -rf ~/Library/spyder-5.4.0.dev0
    rm -rf $inst_dir/dist/pkg

    # Run installer
    log "Installing Spyder standalone application..."
    # pkgutil --expand $inst_dir/dist/$pkg_name $inst_dir/dist/pkg
    installer -dumplog -pkg $pkg_name -target CurrentUserHomeDirectory

    if [[ -e "$app_path" ]]; then
        log "Spyder.app info:"
        tree $app_path
        cat $app_path/Contents/MacOS/Spyder
        echo ""
    else
        log "$app_path does not exist"
    fi
fi
