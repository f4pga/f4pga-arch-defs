#!/usr/bin/env bash

export CMAKE_FLAGS="-GNinja"

source $(dirname "$0")/setup-and-activate.sh

pushd build

make_target all_xc7_200t "Running xc7 200T tests (make all_xc7_200t)"
ninja print_qor > xc7_qor.csv

popd
