#!/bin/bash

SCRIPT_SRC="$(realpath ${BASH_SOURCE[0]})"
SCRIPT_DIR="$(dirname "${SCRIPT_SRC}")"

export CMAKE_FLAGS="-GNinja"
export BUILD_TOOL=ninja
source ${SCRIPT_DIR}/common.sh

source ${SCRIPT_DIR}/steps/start_monitor.sh

echo
echo "========================================"
echo "Doing document generation"
echo "----------------------------------------"
set +e
(
	source env/conda/bin/activate symbiflow_arch_def_base
	cd build
	ninja -j ${MAX_CORES} docs
)
echo "----------------------------------------"
set -e

source ${SCRIPT_DIR}/steps/stop_monitor.sh
