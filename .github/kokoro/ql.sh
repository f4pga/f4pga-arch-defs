#!/bin/bash

SCRIPT_SRC="$(realpath ${BASH_SOURCE[0]})"
SCRIPT_DIR="$(dirname "${SCRIPT_SRC}")"

export CMAKE_FLAGS="-GNinja"
export BUILD_TOOL=ninja
source ${SCRIPT_DIR}/common.sh

source ${SCRIPT_DIR}/steps/start_monitor.sh

echo
echo "============================================================"
echo "Running quicklogic OpenFPGA tests (make all_quicklogic_tests)"
echo "------------------------------------------------------------"

set +e
(
	set -e
	source env/conda/bin/activate symbiflow_arch_def_base
	pushd build
	export VPR_NUM_WORKERS=${CORES}
	set +e
	ninja -j${MAX_CORES} all_quicklogic_tests
	BUILD_RESULT=$?
	# FIXME: Not sure if the below will work for QuickLogic now.
	#ninja print_qor > ql_openfpga_qor.csv
	popd
	exit ${BUILD_RESULT}
)
BUILD_RESULT=$?
set -e

echo "----------------------------------------"

source ${SCRIPT_DIR}/steps/stop_monitor.sh
exit $BUILD_RESULT

