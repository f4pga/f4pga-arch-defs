#!/bin/bash

set -e

echo
echo "========================================"
echo "Host install antlr4-runtime"
echo "----------------------------------------"

VERSION=4.9

mkdir antlr4-cpp-runtime-${VERSION}
pushd antlr4-cpp-runtime-${VERSION}

wget https://www.antlr.org/download/antlr4-cpp-runtime-${VERSION}-source.zip
unzip antlr4-cpp-runtime-${VERSION}-source.zip
mkdir build
cd build
cmake ..
make -j
sudo make install

popd

echo "----------------------------------------"
