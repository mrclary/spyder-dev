#!/usr/bin/env bash
set -e

ver=$1
root_prefix=$HOME/Library/$ver
prefix=$root_prefix/envs/$ver
menu=$prefix/Menu/spyder-menu.json
bundle=$HOME/Applications/Spyder.app

if [[ ! -e $menu ]]; then
    echo "Error: $menu not found"
    exit 1
fi

source $root_prefix/bin/activate base

rm -rf $bundle
python -c "import menuinst; menuinst.install('$menu', prefix='$prefix')"

if [[ ! -e $bundle ]]; then
    echo "Error: $bundle not created"
    exit 1
fi

echo "$bundle info:"
tree $bundle
cat $bundle/Contents/Info.plist
echo ""
cat $bundle/Contents/MacOS/spyder-script
echo ""
