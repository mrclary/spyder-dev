#!/usr/bin/env bash
set -e

help() { cat <<EOF

$(basename $0) [options] VER

Install and/or uninstall Spyder application launch shortcut.

Options:
  -h          Display this help

  -u          Uninstall the shortcut. If neither -u nor -i are specified,
              the shortcut will be uninstalled then installed.

  -i          Install the shortcut. If neither -u nor -i are specified,
              the shortcut will be uninstalled then installed.

  VER         Base version to install/uninstall, e.g. 6

EOF
}

# exec 3>&1  # Additional output descriptor for logging
log(){
    level="INFO"
    echo "$(date "+%Y-%m-%d %H:%M:%S") [$level] [spy-menuinst] -> $@" #1>&3
}

UNINSTALL=0  # Default to uninstall
INSTALL=0    # Default to install

while getopts ":huiv:" option; do
    case $option in
        (h) help; exit ;;
        (u) UNINSTALL=0 && unset INSTALL ;;
        (i) unset UNINSTALL && INSTALL=0 ;;
    esac
done
shift $(($OPTIND - 1))
ver=$1

if [[ -z "$ver" ]]; then
    log "Please provide version."
    help
    exit 1
fi

if [[ "$OSTYPE" = "darwin"* ]]; then
    root_prefix=$HOME/Library/spyder-$ver
else
    root_prefix=$HOME/.local/spyder-$ver
fi
[[ -f "${root_prefix}/.nonadmin" ]] && mode="user" || mode="system"
prefix=$root_prefix/envs/spyder-runtime
menu=$prefix/Menu/spyder-menu.json

if [[ ! -e "$menu" ]]; then
    log "Error: $menu not found"
    exit 1
fi

source $root_prefix/bin/activate base

shortcut=$(python - <<EOF
from menuinst.api import _load
menu, menu_items = _load("$menu", target_prefix="$prefix", base_prefix="$root_prefix", _mode="$mode")
print(menu_items[0]._paths()[0])
EOF
)

if [[ -n "$UNINSTALL" ]]; then
    if [[ -e "$shortcut" ]]; then
        log "Uninstalling ${shortcut} ..."
        python -c "import menuinst; menuinst.api.remove('$menu', target_prefix='$prefix', base_prefix='$root_prefix')"
    else
        log "$shortcut already uninstalled."
    fi
else
    log "Skip uninstall."
fi

if [[ -n "$INSTALL" ]]; then
    log "Installing $shortcut ..."
    python -c "import menuinst; menuinst.api.install('$menu', base_prefix='$root_prefix', target_prefix='$prefix')"

    if [[ ! -e "$shortcut" ]]; then
        log "Error: $shortcut not created"
        exit 1
    fi

    if [[ "$OSTYPE" = "darwin"* ]]; then
        log "$shortcut structure:"
        tree $shortcut
        log "$shortcut/Contents/Info.plist contents:"
        cat $shortcut/Contents/Info.plist
        log "$shortcut/Contents/MacOS/spyder*-script contents:"
        cat $shortcut/Contents/MacOS/spyder*-script
        echo ""
    else
        log "Contents of ${shortcut}:"
        cat $shortcut
    fi
else
    log "Skip install."
fi
