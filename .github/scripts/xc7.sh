#!/usr/bin/env bash

export CMAKE_FLAGS="-GNinja"
source $(dirname "$0")/setup-and-activate.sh

pushd build

make_target all_xc7 "Running xc7 tests (make all_xc7)"
ninja print_qor > xc7_qor.csv

popd
