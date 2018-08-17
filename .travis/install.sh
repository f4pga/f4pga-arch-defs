#!/bin/bash

source .travis/common.sh
set -e

# Git repo fixup
.travis/git-fixup.sh
