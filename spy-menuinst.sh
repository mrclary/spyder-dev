#!/usr/bin/env bash
set -e

# Default is conda-based install location
bp=$HOME/.local/spyder-6
_bp=$HOME/miniforge3  # secondary default
if [[ "$OSTYPE" = "darwin"* ]]; then
    bp=$HOME/Library/spyder-6
    _bp=/usr/local/Caskroom/miniforge/base
fi
tp=$bp/envs/spyder-runtime

help() { cat <<EOF

$(basename $0) [options]

Install and/or uninstall Spyder application launch shortcut.

Options:
  -h          Display this help

  -u          Uninstall the shortcut. If neither -u nor -i are specified,
              the shortcut will be uninstalled then installed.

  -i          Install the shortcut. If neither -u nor -i are specified,
              the shortcut will be uninstalled then installed.

  -t TARGET   Target environment name, located in $HOME/.conda/envs.
              The base environment used is
              $_bp

              If not provided, the target prefix is
              $tp
              and the base prefix is
              $bp

EOF
}

# exec 3>&1  # Additional output descriptor for logging
log(){
    level="INFO"
    echo "$(date "+%Y-%m-%d %H:%M:%S") [$level] [spy-menuinst] -> $@" #1>&3
}

UNINSTALL=0  # Default to uninstall
INSTALL=0    # Default to install

while getopts ":huit:n" option; do
    case $option in
        (h) help; exit ;;
        (u) UNINSTALL=0 && unset INSTALL ;;
        (i) unset UNINSTALL && INSTALL=0 ;;
        (t) bp=$_bp; tp=$HOME/.conda/envs/$OPTARG ;;
        (n) name=1 ;;
    esac
done
shift $(($OPTIND - 1))

[[ -f "${tp}/.nonadmin" ]] && mode="user" || mode="system"
menu=$tp/Menu/spyder-menu.json

if [[ ! -e "$menu" ]]; then
    log "Error: $menu not found"
    exit 1
fi

source $bp/bin/activate base

shortcut=$(python - <<EOF
from menuinst.api import _load
menu, menu_items = _load("$menu", target_prefix="$tp", base_prefix="$bp", _mode="$mode")
print(menu_items[0]._paths()[0])
EOF
)

if [[ -n "$name" ]]; then
    echo $shortcut
    exit
fi

if [[ -n "$UNINSTALL" ]]; then
    if [[ -e "$shortcut" ]]; then
        log "Uninstalling ${shortcut} ..."
        python -c "import menuinst; menuinst.api.remove('$menu', target_prefix='$tp', base_prefix='$bp')"
    else
        log "$shortcut already uninstalled."
    fi
else
    log "Skip uninstall."
fi

if [[ -n "$INSTALL" ]]; then
    log "Installing $shortcut ..."
    python -c "import menuinst; menuinst.api.install('$menu', base_prefix='$bp', target_prefix='$tp')"

    if [[ ! -e "$shortcut" ]]; then
        log "Error: $shortcut not created"
        exit 1
    fi

    if [[ "$OSTYPE" = "darwin"* ]]; then
        log "$shortcut structure:"
        tree "$shortcut"
        log "$shortcut/Contents/Info.plist contents:"
        cat "$shortcut/Contents/Info.plist"
        log "$shortcut/Contents/MacOS/spyder"*-script contents:
        cat "$shortcut/Contents/MacOS/spyder"*-script
        echo ""
    else
        log "Contents of ${shortcut}:"
        cat "$shortcut"
    fi
else
    log "Skip install."
fi
