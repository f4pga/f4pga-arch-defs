#!/bin/bash

INSTALL_DIR="$(pwd)/install"

export CMAKE_FLAGS="-GNinja -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -DINSTALL_FAMILIES=xc7"
source $(dirname "$0")/setup.sh

set -e
source $(dirname "$0")/common.sh

source env/conda/bin/activate symbiflow_arch_def_base

pushd build
make_target install "Running install tests (make install)"
popd

cp environment.yml install/

heading "Running installed toolchain tests"
(
	pushd build
	export VPR_NUM_WORKERS=${MAX_CORES}
	export CTEST_OUTPUT_ON_FAILURE=1
	ctest -R binary_toolchain_test_xc7* -j${MAX_CORES}
	popd
)
echo "----------------------------------------"

heading "Compressing and uploading install dir"
(
	rm -rf build

	# Remove symbolic links and copy content of the linked files
	for file in $(find install -type l)
		do cp --remove-destination $(readlink $file) $file
	done

	du -ah install
	export GIT_HASH=$(git rev-parse --short HEAD)
	tar -I "pixz" -cvf symbiflow-arch-defs-install-${GIT_HASH}.tar.xz -C install bin share/symbiflow/techmaps share/symbiflow/scripts environment.yml
	tar -I "pixz" -cvf symbiflow-arch-defs-benchmarks-${GIT_HASH}.tar.xz -C install benchmarks
	for device in $(ls install/share/symbiflow/arch)
	do
		tar -I "pixz" -cvf symbiflow-arch-defs-$device-${GIT_HASH}.tar.xz -C install share/symbiflow/arch/$device
	done
	rm -rf install
)
echo "----------------------------------------"
