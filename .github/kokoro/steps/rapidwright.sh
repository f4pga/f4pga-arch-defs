#!/bin/bash

export RAPIDWRIGHT_PATH=$(pwd)/github/$KOKORO_DIR/env/RapidWright
mkdir -p "${RAPIDWRIGHT_PATH}"
git clone https://github.com/Xilinx/RapidWright.git "${RAPIDWRIGHT_PATH}"
pushd "${RAPIDWRIGHT_PATH}"
git checkout interchange
make update_jars
popd
