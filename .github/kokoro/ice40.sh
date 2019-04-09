#!/bin/bash

CALLED=$_
[[ "${BASH_SOURCE[0]}" != "${0}" ]] && SOURCED=1 || SOURCED=0

SCRIPT_SRC="$(realpath ${BASH_SOURCE[0]})"
SCRIPT_DIR="$(dirname "${SCRIPT_SRC}")"

source ${SCRIPT_DIR}/common.sh

echo
echo "========================================"
echo "Running ice40 tests"
echo "----------------------------------------"
(
	cd build
    make -j ${MAX_CORES} --output-sync=target \
		ice40_up5k_sg48_rrxml_real \
		ice40_hx1k_tq144_rrxml_real \
		ice40_hx8k_ct256_rrxml_real \
		ice40_lp1k_qn84_rrxml_real \
		ice40_lp8k_cm81_rrxml_real
	ls -l ice40/devices/rr_graph*.real.xml
	make -j ${MAX_CORES} --output-sync=target \
		all_ice40
)
echo "----------------------------------------"
