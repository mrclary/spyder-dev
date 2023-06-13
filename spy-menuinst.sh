#!/usr/bin/env bash
set -e

ver=$1
root_prefix=$HOME/Library/spyder-$ver
prefix=$root_prefix/envs/spyder-$ver
menu=$prefix/Menu/spyder-menu.json
if [[ $OSTYPE = "darwin"* ]]; then
    shortcut=$HOME/Applications/Spyder.app
else
    shortcut=$HOME/.local/share/applicatons/spyder_spyder.desktop
fi

if [[ ! -e $menu ]]; then
    echo "Error: $menu not found"
    exit 1
fi

source $root_prefix/bin/activate base

if [[ -e $shortcut && $OSTYPE = "darwin"* ]]; then
    curr_ver=$(plutil -extract CFshortcutShortVersionString raw "$shortcut/Contents/Info.plist")
    echo "Uninstalling Spyder.app bundle version ${curr_ver}..."
    python -c "import menuinst; menuinst.api.remove('$menu')"
fi

if [[ $OSTYPE = "darwin"* ]]; then
    echo "Installing Spyder.app bundle..."
else
    echo "Installing Spyder shortcut..."
fi
python -c "import menuinst; menuinst.api.install('$menu', target_prefix='$prefix')"

if [[ ! -e $shortcut ]]; then
    echo "Error: $shortcut not created"
    exit 1
fi

if [[ $OSTYPE = "darwin"* ]]; then
    echo "$shortcut structure:"
    tree $shortcut
    echo ""
    echo "$shortcut/Contents/Info.plist contents:"
    cat $shortcut/Contents/Info.plist
    echo ""
    echo "$shortcut/Contents/MacOS/spyder-script contents:"
    cat $shortcut/Contents/MacOS/spyder-script
    echo ""
else
    echo "Contents of ${shortcut}:"
    cat $shortcut
    echo ""
fi
