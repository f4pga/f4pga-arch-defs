#!/bin/bash

SCRIPT_SRC="$(realpath ${BASH_SOURCE[0]})"
SCRIPT_DIR="$(dirname "${SCRIPT_SRC}")"

source ${SCRIPT_DIR}/common.sh

echo
echo "========================================"
echo "Running testarch tests"
echo "----------------------------------------"
(
	cd build
	VPR_NUM_WORKERS=${CORES} make -j ${MAX_CORES} --output-sync=target \
		all_testarch
)
echo "----------------------------------------"
