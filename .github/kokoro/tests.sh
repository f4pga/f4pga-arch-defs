#!/bin/bash

CALLED=$_
[[ "${BASH_SOURCE[0]}" != "${0}" ]] && SOURCED=1 || SOURCED=0

SCRIPT_SRC="$(realpath ${BASH_SOURCE[0]})"
SCRIPT_DIR="$(dirname "${SCRIPT_SRC}")"

source ${SCRIPT_DIR}/common.sh

echo
echo "========================================"
echo "Running tests"
echo "----------------------------------------"
(
	cd build
	make check_python --output-sync=target
	make test_python --output-sync=target
	make all --output-sync=target
)
echo "----------------------------------------"
