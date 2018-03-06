#!/bin/bash

source .travis/common.sh
set -e

# Git repo fixup
start_section "environment.git" "Fixing ${YELLOW}git checkout${NC}"
set -x
git fetch --unshallow || true
git fetch --tags
git submodule update --recursive --init
git submodule foreach git submodule update --recursive --init
set +x
$SPACER
set -x
git remote -v
git branch -v
git branch -D $TRAVIS_BRANCH
CURRENT_GITREV="$(git rev-parse HEAD)"
git checkout -b $TRAVIS_BRANCH $CURRENT_GITREV
git tag -l
git describe --long
set +x
$SPACER
git status -v
$SPACER
end_section "environment.git"
