#!/bin/bash

SCRIPT_SRC="$(realpath ${BASH_SOURCE[0]})"
SCRIPT_DIR="$(dirname "${SCRIPT_SRC}")"

export CMAKE_FLAGS=-GNinja
export BUILD_TOOL=ninja
source ${SCRIPT_DIR}/common.sh

echo
echo "========================================"
echo "Running xc7 tests (make all_xc7_200t)"
echo "----------------------------------------"
(
	cd build
	export VPR_NUM_WORKERS=${CORES}
	ninja -j${MAX_CORES} all_xc7_200t
	ninja print_qor > xc7_qor.csv
)
echo "----------------------------------------"

source ${SCRIPT_DIR}/package_results.sh
