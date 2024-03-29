#!/usr/bin/env bash

export CMAKE_FLAGS="-GNinja"
source $(dirname "$0")/setup-and-activate.sh

pushd build

case "$1" in
  a200t-vendor) make_target all_artix7_200t_diff_fasm "Running xc7 200T vendor tests (make all_xc7_200t_diff_fasm)" 0 ;;
  vendor)       make_target all_xc7_diff_fasm "Running xc7 vendor tests (make all_xc7_diff_fasm)" 0 ;;
  a200t)        make_target all_xc7_200t "Running xc7 200T tests (make all_xc7_200t)" ;;
  *)            make_target all_xc7 "Running xc7 tests (make all_xc7)" ;;
esac

ninja print_qor > xc7_qor.csv

popd
