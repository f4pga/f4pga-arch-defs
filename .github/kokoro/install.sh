#!/bin/bash

SCRIPT_SRC="$(realpath ${BASH_SOURCE[0]})"
SCRIPT_DIR="$(dirname "${SCRIPT_SRC}")"
INSTALL_DIR="$(pwd)/install"
ROOT_DIR="$(pwd)"
GIT_DESCRIBE=$(git describe)

export CMAKE_FLAGS="-GNinja -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}"
export BUILD_TOOL=ninja
source ${SCRIPT_DIR}/common.sh

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
echo "Compressing and uploading install dir"
echo "----------------------------------------"
(
	pushd ${ROOT_DIR}
	tar -cf install | xz -9 -T`nproc` > ${ROOT_DIR}/symbiflow-arch-defs-install-$(git describe).tar.xz
	popd
)
echo "----------------------------------------"

echo
echo "========================================"
echo "Running installed toolchain tests"
echo "----------------------------------------"
(

	pushd build
	export VPR_NUM_WORKERS=${CORES}
	export CTEST_OUTPUT_ON_FAILURE=1
	ctest -R binary_toolchain_test -j${MAX_CORES}
	popd
)
echo "----------------------------------------"
