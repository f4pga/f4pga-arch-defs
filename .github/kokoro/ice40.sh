#!/bin/bash

SCRIPT_SRC="$(realpath ${BASH_SOURCE[0]})"
SCRIPT_DIR="$(dirname "${SCRIPT_SRC}")"

source ${SCRIPT_DIR}/common.sh

echo
echo "========================================"
echo "Running ice40 tests (make all_ice40)"
echo "----------------------------------------"
(
	cd build
	export VPR_NUM_WORKERS=${CORES}
	export MAKE_ARGS="-j${MAX_CORES} --output-sync=target"
	# Run as many tests as we can.    Rerun individually on failure.
	make -k ${MAKE_ARGS} all_ice40 || make all_ice40
	make print_qor > ice40_qor.csv
)
echo "----------------------------------------"
