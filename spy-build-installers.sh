#!/usr/bin/env bash
set -e

script_path=${BASH_SOURCE:-${(%):-%x}}
here=$(dirname $script_path)
src_inst_dir=$(dirname $here)/spyder/installers-conda

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
install_opts=()

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

SPYTMPDIR=${TMPDIR:-/tmp/}spyder
mkdir -p $SPYTMPDIR

# ---- Build conda packages
if [[ -n $BUILDCONDA ]]; then
    log "Removing cached Spyder conda package..."
    [[ "$OSTYPE" == "darwin"* ]] && rm -rf $HOME/.conda/conda-bld/osx-64/spyder-6*
    [[ "$OSTYPE" == "linux"* ]] && rm -rf $HOME/.conda/conda-bld/linux-64/spyder-6*
    rm -f $HOME/.conda/conda-bld/channeldata.json

    log "Building conda packages..."
    python $src_inst_dir/build_conda_pkgs.py ${build_conda_opts[@]}
    log "Building conda packages complete"
else
    log "Not building conda packages"
fi

# ---- Build keychain
if [[ (-n $BUILDPKG || -n $NOTARIZE) && $OSTYPE = "darwin"* ]]; then
    _codesign=$(which codesign)
    if [[ $_codesign =~ ${CONDA_PREFIX}.* ]]; then
        # Find correct codesign
        log "Moving $_codesign..."
        mv $_codesign ${_codesign}.bak
    fi

    APPCERT=$(op read "op://Personal/Apple Developer Program/Developer ID Application Certificate")
    INSTCERT=$(op read "op://Personal/Apple Developer Program/Developer ID Installer Certificate")
    AUTHCERT=$(op read "op://Personal/Apple Developer Program/Developer ID Certification Authority")
    CERTPASS=$(op read "op://Personal/Apple Developer Program/Certificate Password")
    APPPASS=$(op read "op://Personal/Apple Developer Program/Application Password")

    trap "$src_inst_dir/certkeychain.sh -c" EXIT
    echo $AUTHCERT | base64 --decode > $SPYTMPDIR/certificate.cer
    $src_inst_dir/certkeychain.sh $CERTPASS $APPCERT $INSTCERT $SPYTMPDIR/certificate.cer
    CNAME=$(security find-identity -p codesigning -v | pcre2grep -o1 "\(([0-9A-Z]+)\)")
    [[ -n "$CNAME" ]] && build_pkg_opts+=("--cert-id=$CNAME")
fi

# ---- Build installer pkg
if [[ -n $BUILDPKG ]]; then
    log "Removing cached Spyder package for constructor..."
    [[ "$OSTYPE" == "darwin"* ]] && rm -rf $HOME/.conda/constructor/osx-64/spyder-6*
    [[ "$OSTYPE" == "linux"* ]] && rm -rf $HOME/.conda/constructor/linux-64/spyder-6*

    log "Building installer..."
    python $src_inst_dir/build_installers.py ${build_pkg_opts[@]}
else
    log "Not building installer"
fi

pkg_name="$(python $src_inst_dir/build_installers.py --artifact-name ${build_pkg_opts[@]})"

if [[ -n $INSTALL ]]; then
    [[ $OSTYPE = "darwin"* ]] && root_prefix=$HOME/Library/spyder-* || root_prefix=$HOME/.local/spyder-*
    root_prefix=$(dirname $root_prefix)/$(basename $root_prefix)
    u_spy_exe=$root_prefix/uninstall-spyder.sh

    # Remove previous install
    log "Uninstalling previous installation..."
    [[ -f $u_spy_exe ]] && $u_spy_exe -f

    # Run installer
    log "Installing Spyder..."
    if [[ "$pkg_name" =~ ^.*\.pkg$ ]]; then
        tail -F /var/log/install.log &
        trap "kill -s TERM $!" EXIT
        installer -pkg $pkg_name -target CurrentUserHomeDirectory
    else
        # export CONDA_VERBOSITY=3
        "$pkg_name" ${install_opts[@]}
    fi

    # Get shortcut path
    [[ -e "$prefix/.nonadmin" ]] && mode=user || mode=system
    shortcut=$($root_prefix/bin/python $root_prefix/bin/menuinst_cli.py shortcut --mode=$mode)

    # Show install results
    log "Install info:"
    echo -e "Contents of ${root_prefix}:"
    ls -al $root_prefix
    echo -e "\nContents of $root_prefix/uninstall-spyder.sh:"
    cat $root_prefix/uninstall-spyder.sh
    echo ""
    if [[ "$OSTYPE" = "darwin"* && -e "$shortcut" ]]; then
        tree $shortcut
        echo ""
        cat $shortcut/Contents/Info.plist
        echo ""
        cat $shortcut/Contents/MacOS/spyder*script
        echo ""
    elif [[ "$OSTYPE" = "linux" && -e "$shortcut" ]]; then
        cat $shortcut
        echo ""
    else
        log "$shortcut does not exist"
    fi
else
    log "Not installing"
fi

if [[ -n "$NOTARIZE" && "$OSTYPE" = "darwin"* ]]; then
    $src_inst_dir/notarize.sh ${notarize_opts[@]} $pkg_name
else
    log "Not notarizing"
fi
