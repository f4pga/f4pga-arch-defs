#!/bin/bash

export RAPIDWRIGHT_PATH=$(pwd)/github/$KOKORO_DIR/env/RapidWright
mkdir -p "${RAPIDWRIGHT_PATH}"

# Using SymbiFlow/RapidWright fork to control ingestion of upstream merges.
git clone https://github.com/SymbiFlow/RapidWright.git "${RAPIDWRIGHT_PATH}"
pushd "${RAPIDWRIGHT_PATH}"
git checkout interchange
make update_jars
popd
