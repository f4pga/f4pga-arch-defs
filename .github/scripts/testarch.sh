#!/usr/bin/env bash

export CMAKE_FLAGS="-GNinja"

source $(dirname "$0")/setup-and-activate.sh

pushd build

make_target all_testarch "Running testarch tests (make all_testarch)"

popd
