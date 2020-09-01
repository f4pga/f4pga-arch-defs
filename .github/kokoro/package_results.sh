#!/bin/bash

set -e

echo
echo "========================================"
echo "Packing results"
echo "----------------------------------------"
date
cd build
find -name "*result*.xml" \
    -o -name "*sponge_log.xml" \
    -o -name ".ninja_log" \
    -o -name "pack.log" \
    -o -name "place.log" \
    -o -name "route.log" \
    -o -name "*_sv2v.v.log" \
    -o -name "*.bit" \
    -o -name "*_qor.csv" \
    | xargs tar -cvf ../results.tar
cd ..
rm -r build
mkdir build
cd build
tar -xf ../results.tar
rm ../results.tar
