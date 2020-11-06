#!/bin/bash

SCRIPT_SRC="$(realpath ${BASH_SOURCE[0]})"
SCRIPT_DIR="$(dirname "${SCRIPT_SRC}")"

export CMAKE_FLAGS=-GNinja
export BUILD_TOOL=ninja
source ${SCRIPT_DIR}/common.sh

echo
echo "========================================"
echo "Running ql tests (make all_ql_tests)"
echo "----------------------------------------"
(
	source env/conda/bin/activate symbiflow_arch_def_base

	#FIXME: Integrate the following custom packages with SymbiFlow
	conda uninstall symbiflow-yosys -y
	pip3 uninstall v2x -y 

	# Custom Yosys + the latest SymbiFlow Yosys Plugins
	conda install quicklogic-yosys -c litex-hub -y
	conda install --no-deps symbiflow-yosys-plugins=1.0.0.7_0174_g5e6370a=20201012_171341 -y

	# Custom v2x
	pip3 install git+https://github.com/QuickLogic-Corp/python-symbiflow-v2x@b0c8679c1fc9c90ca1555aab055b25a4a7d83fb6

	cd build
	export VPR_NUM_WORKERS=${CORES}
	ninja -j${MAX_CORES} all_ql_tests
	ninja print_qor > ql_qor.csv
)
echo "----------------------------------------"

source ${SCRIPT_DIR}/package_results.sh
