#!/bin/bash

source .github/travis/common.sh
set -e

# Git repo fixup
.github/travis/git-fixup.sh
