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
	echo
	echo "make check_python"
	make check_python --output-sync=target

	echo
	echo "make test_python"
	make test_python --output-sync=target

	echo
	echo "make all"
	make all --output-sync=target
)
echo "----------------------------------------"
