#!/usr/bin/env bash
set -e

ver=$1
root_prefix=$HOME/Library/spyder-$ver
prefix=$root_prefix/envs/spyder-$ver
menu=$prefix/Menu/spyder-menu.json
bundle=$HOME/Applications/Spyder.app

if [[ ! -e $menu ]]; then
    echo "Error: $menu not found"
    exit 1
fi

source $root_prefix/bin/activate base

if [[ -e $bundle ]]; then
    curr_ver=$(plutil -extract CFBundleShortVersionString raw "$bundle/Contents/Info.plist")
    echo "Uninstalling Spyder.app version $curr_ver ..."
    python -c "import menuinst; menuinst.api.remove('$menu')"
fi

echo "Installing Spyder.app version $ver ..."
python -c "import menuinst; menuinst.api.install('$menu', target_prefix='$prefix')"

if [[ ! -e $bundle ]]; then
    echo "Error: $bundle not created"
    exit 1
fi

echo "$bundle structure:"
tree $bundle
echo ""
echo "$bundle/Contents/Info.plist contents:"
cat $bundle/Contents/Info.plist
echo ""
echo "$bundle/Contents/MacOS/spyder-script contents:"
cat $bundle/Contents/MacOS/spyder-script
echo ""
