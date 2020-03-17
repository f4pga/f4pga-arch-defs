#!/bin/bash

SCRIPT_SRC="$(realpath ${BASH_SOURCE[0]})"
SCRIPT_DIR="$(dirname "${SCRIPT_SRC}")"
INSTALL_DIR="$(pwd)/install"

export CMAKE_FLAGS="-GNinja -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}"
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
	export VPR_NUM_WORKERS=${CORES}
	ninja -j${MAX_CORES} install
	popd
)
echo "----------------------------------------"

echo
echo "========================================"
echo "Running installed toolchain tests"
echo "----------------------------------------"
(

	# add conda bin to path (we'll use yosys from conda)
	export PATH=$(pwd)/build/env/conda/bin:$PATH
	# add installed toolchain to PATH
	export PATH=${INSTALL_DIR}/bin:$PATH
	# install python deps
	pip install -r xc7/tests/install_test/requirements.txt
	pushd build
	export VPR_NUM_WORKERS=${CORES}
	export CTEST_OUTPUT_ON_FAILURE=1
	ctest -R binary_toolchain_test -j${MAX_CORES}
	popd
)
echo "----------------------------------------"

source ${SCRIPT_DIR}/package_results.sh
