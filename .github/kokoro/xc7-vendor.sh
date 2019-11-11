#!/bin/bash

SCRIPT_SRC="$(realpath ${BASH_SOURCE[0]})"
SCRIPT_DIR="$(dirname "${SCRIPT_SRC}")"

export CMAKE_FLAGS=-GNinja
export BUILD_TOOL=ninja
source ${SCRIPT_DIR}/common.sh

echo
echo "========================================"
echo "Running xc7 vendor tests (make all_xc7_diff_fasm)"
echo "----------------------------------------"
(
	cd build
	export VPR_NUM_WORKERS=${CORES}
	# Disabled until tested
	#ninja -j${MAX_CORES} all_xc7_diff_fasm
)
echo "----------------------------------------"

source ${SCRIPT_DIR}/package_results.sh
