#!/bin/bash

SCRIPT_SRC="$(realpath ${BASH_SOURCE[0]})"
SCRIPT_DIR="$(dirname "${SCRIPT_SRC}")"

export CMAKE_FLAGS="-GNinja -DCMAKE_INSTALL_PREFIX=`pwd`/install"
export BUILD_TOOL=ninja
source ${SCRIPT_DIR}/common.sh

echo
echo "========================================"
echo "Running xc7 tests (make all_xc7)"
echo "----------------------------------------"
(
	pushd build
	export VPR_NUM_WORKERS=${CORES}
	ninja -j${MAX_CORES} all_xc7
	ninja print_qor > xc7_qor.csv
	popd
)
echo "----------------------------------------"

echo
echo "========================================"
echo "Running install tests (make install)"
echo "----------------------------------------"
(
	pushd build
	ninja -j${MAX_CORES} install
	popd
)
echo "----------------------------------------"
source ${SCRIPT_DIR}/package_results.sh
