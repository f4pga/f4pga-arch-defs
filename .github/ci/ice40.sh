#!/bin/bash

export CMAKE_FLAGS="-GNinja"
source $(dirname "$0")/setup.sh

set -e
source $(dirname "$0")/common.sh

source env/conda/bin/activate symbiflow_arch_def_base

pushd build

make_target all_ice40 "Running ice40 tests (make all_ice40)"
ninja print_qor > ice40_qor.csv

popd
