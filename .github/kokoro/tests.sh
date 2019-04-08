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
	make check_python --output-sync=target --warn-undefined-variables
	make test_python --output-sync=target --warn-undefined-variables
)
echo "----------------------------------------"
