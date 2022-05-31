#!/usr/bin/env bash

set -e
source $(dirname "$0")/common.sh

enable_vivado 2017.2

export CMAKE_FLAGS="-GNinja"

# Fix Xilinx TCL app store issues with multiple jobs:
# https://support.xilinx.com/s/article/63253?language=en_US
export XILINX_LOCAL_USER_DATA="no"

source $(dirname "$0")/setup-and-activate.sh

pushd build

make_target all_xc7_diff_fasm "Running xc7 vendor tests (make all_xc7_diff_fasm)" 0

popd
