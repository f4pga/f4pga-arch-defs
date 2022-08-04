#!/usr/bin/env bash

set -e
source $(dirname "$0")/common.sh

enable_vivado 2017.2

# Fix Xilinx TCL app store issues with multiple jobs:
# https://support.xilinx.com/s/article/63253?language=en_US
export XILINX_LOCAL_USER_DATA="no"

case "$1" in
  a200t) $(dirname "$0")/xc7.sh a200t-vendor ;;
  *)     $(dirname "$0")/xc7.sh vendor ;;
esac
