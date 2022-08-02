#!/usr/bin/env bash

set -e
source $(dirname "$0")/common.sh

enable_vivado 2017.2

# Fix Xilinx TCL app store issues with multiple jobs:
# https://support.xilinx.com/s/article/63253?language=en_US
export XILINX_LOCAL_USER_DATA="no"

export CMAKE_FLAGS="-GNinja"
source $(dirname "$0")/setup-and-activate.sh

pushd build

case "$1" in
  a200t)
    make_target all_artix7_200t_diff_fasm "Running xc7 200T vendor tests (make all_xc7_200t_diff_fasm)" 0
  ;;
  *)
    make_target all_xc7_diff_fasm "Running xc7 vendor tests (make all_xc7_diff_fasm)" 0
  ;;
esac

popd
