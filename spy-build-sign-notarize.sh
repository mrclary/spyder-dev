#!/usr/bin/env bash
set -e

SPYROOT=$(dirname $(dirname ${BASH_SOURCE:-${(%):-%x}}))
SITEPKGS=$(python -c "import site; print(site.getsitepackages()[0])")
build_opts=()
sign_opts=()

while getopts ":habsdnlu" option; do
    case $option in
        (h) help; exit ;;
        (a) all=true ;;
        (b) build=true ;;
        (s) sign=true ;;
        (d) dmg=true ;;
        (n) notarize=true ;;
        (l) build_opts+=("--lite") ;; # build lite
        (u) sign_opts=("-u") ;;
    esac
done
shift $(($OPTIND - 1))

if [[ -n $all ]]; then
    build=true
    sign=true
    dmg=true
    notarize=true
fi

cd "$SPYROOT/spyder/installers/macOS"

if [[ -n $sign || -n $notarize ]]; then
    CERT=$(op read "op://Personal/Apple Developer Program/Developer ID Application Certificate")
    CERTPASS=$(op read "op://Personal/Apple Developer Program/Certificate Password")
    APPPASS=$(op read "op://Personal/Apple Developer Program/Application Password")
#     trap "security list-keychain -s login.keychain; rm -rf certificate.p12" EXIT
#     ./certkeychain.sh $CERT $CERTPASS
fi

if [[ -n $build ]]; then
    # Patch Black
    black=$SITEPKGS/black-24.1.1.dist-info/top_level.txt
    [[ ! -e "$black" ]] && touch $black

    python setup.py ${build_opts[@]} --dist-dir dist

    # Patch Black
    cp -v $SITEPKGS/629853fdff261ed89b74__mypyc* dist/Spyder.app/Contents/Resources/lib/python*/
fi

if [[ -n $sign && -d dist/Spyder.app ]]; then
    pil=$(python -c "import PIL, os; print(os.path.dirname(PIL.__file__))")
    rm -v dist/Spyder.app/Contents/Frameworks/liblzma.5.dylib
    cp -v ${pil}/.dylibs/liblzma.5.dylib dist/Spyder.app/Contents/Frameworks/
    ./codesign.sh ${sign_opts[@]} dist/Spyder.app
fi

if [[ -n $dmg ]]; then
    python setup.py --no-app --dmg --dist-dir dist
fi
if [[ -n $sign && -f dist/Spyder.dmg ]]; then
    ./codesign.sh ${sign_opts[@]} dist/Spyder.dmg
fi
if [[ -n $notarize && -f dist/Spyder.dmg ]]; then
    ./~notarize.sh -p $APPPASS dist/Spyder.dmg
fi
