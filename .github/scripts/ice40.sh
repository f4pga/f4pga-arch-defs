#!/usr/bin/env bash

export CMAKE_FLAGS="-GNinja"

source $(dirname "$0")/setup-and-activate.sh

pushd build

make_target all_ice40 "Running ice40 tests (make all_ice40)"
ninja print_qor > ice40_qor.csv

popd
