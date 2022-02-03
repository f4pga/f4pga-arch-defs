#!/bin/bash

set -e
source $(dirname "$0")/common.sh

enable_vivado 2017.2

export CMAKE_FLAGS="-GNinja"

source $(dirname "$0")/setup.sh

source env/conda/bin/activate symbiflow_arch_def_base

pushd build

make_target all_artix7_200t_diff_fasm "Running xc7 200T vendor tests (make all_xc7_200t_diff_fasm)" 0

popd

