#!/usr/bin/env bash

set -e

INSTALL_DIR="$(pwd)/install"

export CMAKE_FLAGS="-GNinja -DINSTALL_FAMILIES=qlf_k4n8,pp3 -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}"

export FPGA_FAM=eos-s3
export F4PGA_INSTALL_DIR="placeholder"
source $(dirname "$0")/setup-and-activate.sh

pushd build
make_target all_quicklogic_tests "Running quicklogic OpenFPGA tests (make all_quicklogic_tests)"
popd

echo "----------------------------------------"
