#!/bin/bash

SCRIPT_SRC="$(realpath ${BASH_SOURCE[0]})"
SCRIPT_DIR="$(dirname "${SCRIPT_SRC}")"

export CMAKE_FLAGS="-GNinja"
export BUILD_TOOL=ninja
source ${SCRIPT_DIR}/common.sh

source ${SCRIPT_DIR}/steps/start_monitor.sh

echo
echo "========================================"
echo "Running testarch tests (make all_testarch)"
echo "----------------------------------------"
set +e
(
	source env/conda/bin/activate symbiflow_arch_def_base
	cd build
	export VPR_NUM_WORKERS=${CORES}
	# Run as many tests as we can.       Rerun individually on failure.
	ninja -j${MAX_CORES} all_testarch || make all_testarch
)
echo "----------------------------------------"
set -e

source ${SCRIPT_DIR}/steps/stop_monitor.sh
source ${SCRIPT_DIR}/package_results.sh
