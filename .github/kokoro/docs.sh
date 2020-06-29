#!/bin/bash

CALLED=$_
[[ "${BASH_SOURCE[0]}" != "${0}" ]] && SOURCED=1 || SOURCED=0

SCRIPT_SRC="$(realpath ${BASH_SOURCE[0]})"
SCRIPT_DIR="$(dirname "${SCRIPT_SRC}")"

source ${SCRIPT_DIR}/common.sh

echo
echo "========================================"
echo "Doing document generation"
echo "----------------------------------------"
(
	source env/conda/bin/activate symbiflow_arch_def_base
	cd build
	make -j ${CORES} --output-sync=target \
		docs
)
echo "----------------------------------------"
