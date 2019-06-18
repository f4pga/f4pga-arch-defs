#!/bin/bash

SCRIPT_SRC="$(realpath ${BASH_SOURCE[0]})"
SCRIPT_DIR="$(dirname "${SCRIPT_SRC}")"

source ${SCRIPT_DIR}/common.sh

echo
echo "========================================"
echo "Running xc7 tests (make all_xc7)"
echo "----------------------------------------"
(
	cd build
	export VPR_NUM_WORKERS=${CORES}
	export MAKE_ARGS="-j${MAX_CORES} --output-sync=target"
	# Run as many tests as we can.  Rerun individually on failure.
	make -k ${MAKE_ARGS} all_xc7 || make all_xc7
)
echo "----------------------------------------"
