#!/usr/bin/env bash

set -e

INSTALL_DIR="$(pwd)/install"

export CMAKE_FLAGS="-GNinja -DINSTALL_FAMILIES=qlf_k4n8,pp3 -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}"

export FPGA_FAM=eos-s3
export F4PGA_INSTALL_DIR="placeholder"
source $(dirname "$0")/setup-and-activate.sh

pushd build
make_target all_quicklogic_tests "Running quicklogic OpenFPGA tests (make all_quicklogic_tests)"
make_target install "Installing quicklogic toolchain (make install)"
popd

heading "Running installed toolchain tests"
(
	pushd build
	export CTEST_OUTPUT_ON_FAILURE=1
	export F4PGA_ENV_SHARE=${INSTALL_DIR}/share/symbiflow
	export F4PGA_ENV_BIN=${INSTALL_DIR}/bin/
	heading "Testing installed toolchain on qlf_k4n8"
	ctest -j${MAX_CORES} -R "quicklogic_toolchain_test_.*_qlf_k4n8" -VV
	echo "----------------------------------------"
	heading "Testing installed toolchain on ql_eos_s3"
	ctest -j${MAX_CORES} -R "quicklogic_toolchain_test_.*_ql-eos-s3" -VV
	echo "----------------------------------------"
	popd
)

heading "Compressing and uploading install dir"
(
	du -ah install
	export GIT_HASH=$(git rev-parse --short HEAD)
	tar -I "pixz" -cvf symbiflow-quicklogic-${GIT_HASH}.tar.xz -C install bin share
)
echo "----------------------------------------"
