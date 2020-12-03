#!/bin/bash

# Copied from install.sh
# Only difference is INSTALL_DEVICE in CMAKE_FLAGS and tarball name

SCRIPT_SRC="$(realpath ${BASH_SOURCE[0]})"
SCRIPT_DIR="$(dirname "${SCRIPT_SRC}")"
INSTALL_DIR="$(pwd)/github/${KOKORO_DIR}/install"

export CMAKE_FLAGS="-GNinja -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -DINSTALL_DEVICE=xc7a200t"
export BUILD_TOOL=ninja
source ${SCRIPT_DIR}/common.sh

# This CI was executing the same exact script
# as the XC7 - Install CI, therefore it is now
# set to do nothing.
# TODO: Remove this CI upstream so it does not run at all
echo
echo "========================================"
echo "Doing nothing!"
echo "========================================"
echo
