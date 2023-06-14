#!/usr/bin/env bash
set -e

# Compare patch to installers-conda.patch file on 5.x branch.
# If differences exist other than hash and git version:
#  - merge the 5.x branch into the patch branch
#  - resolve any conflicts
#  - re-run this script and commit the changes to the patch
#    file on the 5.x branch

SPYROOT=$(dirname $(dirname ${BASH_SOURCE:-${(%):-%x}}))
SPYREPO=$SPYROOT/spyder

BRANCH=upstream/5.x
PATCHBRANCH=origin/installers-conda-patch
PATCHFILE=$SPYREPO/installers-conda/resources/installers-conda.patch

cd $SPYREPO

# Checkout branch
echo "Checking out $BRANCH"
# git checkout $BRANCH

# Create patch
git format-patch ..$PATCHBRANCH --stdout > $PATCHFILE

# Compare patch
git diff

# Discard changes?
while [[ -z $action ]]; do
    read -p "Discard changes? [(y)/n]: " action
    [[ -z $action ]] && action=y
    case ${action,,} in
        (y) echo "Restoring $PATCHFILE..."
            git restore $PATCHFILE
            ;;
        (n) echo "Keeping changes in working tree" ;;
        (*) unset action ;;
    esac
done
