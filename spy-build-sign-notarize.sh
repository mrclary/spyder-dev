#!/usr/bin/env bash
set -e

SPYROOT=$(cd $(dirname $BASH_SOURCE)/../ && pwd -P)

build_opts=()
sign_opts=()

while getopts ":habsdznlu" option; do
    case $option in
        (h) help; exit ;;
        (a) all=0 ;;
        (b) build=0 ;;
        (s) sign=0 ;;
        (d) dmg=0 ;;
        (z) signdmg=0 ;;
        (n) notarize=0 ;;
        (l) build_opts+=("--lite") ;; # build lite
        (u) sign_opts=("-u") ;;
    esac
done
shift $(($OPTIND - 1))

if [[ -n $all ]]; then
    build=0
    sign=0
    dmg=0
    signdmg=0
    notarize=0
fi

cd "$SPYROOT/spyder/installers/macOS"

[[ -n $build ]] && python setup.py ${build_opts[@]}
# certkeychain.sh $CERT $PASS
[[ -n $sign ]] && ./codesign.sh ${sign_opts[@]} dist/Spyder.app
# ./notarize.sh -p "dmxe-uloq-qamy-yfil" dist/Spyder.app
[[ -n $dmg ]] && python setup.py --no-app --dmg
[[ -n $signdmg ]] && ./codesign.sh dist/Spyder.dmg
[[ -n $notarize ]] && ./notarize.sh -p @keychain:spyder-ide dist/Spyder.dmg
