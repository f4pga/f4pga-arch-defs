#!/bin/bash

SCRIPT_SRC="$(realpath ${BASH_SOURCE[0]})"
SCRIPT_DIR="$(dirname "${SCRIPT_SRC}")"
INSTALL_DIR="$(pwd)/github/${KOKORO_DIR}/install"

export CMAKE_FLAGS="-GNinja -DINSTALL_FAMILIES=qlf_k4n8,pp3 -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}"
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

	# Run tests
	ninja -j${MAX_CORES} all_quicklogic_tests

	# If successful install the toolchain and test it
	if [ $? -eq 0 ]; then
		ninja -j${MAX_CORES} install

		export CTEST_OUTPUT_ON_FAILURE=1
		echo
		echo "========================================"
		echo "Testing installed toolchain on qlf_k4n8"
		echo "----------------------------------------"
		ctest -j${MAX_CORES} -R "quicklogic_toolchain_test_.*_qlf_k4n8" -VV
		echo "----------------------------------------"
		echo
		echo "========================================"
		echo "Testing installed toolchain on ql_eos_s3"
		echo "----------------------------------------"
		ctest -j${MAX_CORES} -R "quicklogic_toolchain_test_.*_ql-eos-s3" -VV
		echo "----------------------------------------"
	fi

	BUILD_RESULT=$?
	popd
	exit ${BUILD_RESULT}
)
BUILD_RESULT=$?
set -e

echo
echo "========================================"
echo "Compressing and uploading install dir"
echo "----------------------------------------"
(
	du -ah install
	export GIT_HASH=$(git rev-parse --short HEAD)
	tar -I "pixz" -cvf symbiflow-quicklogic-${GIT_HASH}.tar.xz -C install bin share
)
echo "----------------------------------------"

source ${SCRIPT_DIR}/steps/stop_monitor.sh
exit $BUILD_RESULT

