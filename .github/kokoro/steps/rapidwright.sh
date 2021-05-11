#!/bin/bash

RAPIDWRIGHT_TAG="v2020.2.4-beta"

export RAPIDWRIGHT_PATH=$(pwd)/github/$KOKORO_DIR/env/RapidWright
mkdir -p "${RAPIDWRIGHT_PATH}"

# Using SymbiFlow/RapidWright fork to control ingestion of upstream merges.
git clone https://github.com/Xilinx/RapidWright.git "${RAPIDWRIGHT_PATH}"
pushd "${RAPIDWRIGHT_PATH}"
git checkout $RAPIDWRIGHT_TAG
make update_jars
pushd interchange
make all
popd
popd
