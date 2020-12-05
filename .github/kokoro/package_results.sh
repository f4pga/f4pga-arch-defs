#!/bin/bash

set -e

echo
echo "========================================"
echo "Final disk usage"
echo "----------------------------------------"
df -h
echo "----------------------------------------"

echo
echo "========================================"
echo "Packing results"
echo "----------------------------------------"
date
pushd build
find -name "*result*.xml" \
    -o -name "*sponge_log.xml" \
    -o -name ".ninja_log" \
    -o -name "pack.log" \
    -o -name "place.log" \
    -o -name "route.log" \
    -o -name "*_sv2v.v.log" \
    -o -name "*.bit" \
    -o -name "*_qor.csv" \
    -o -name "vivado.log" \
    | xargs tar -cvf ../results.tar
popd
rm -r build
mkdir build
pushd build
tar -xf ../results.tar
rm ../results.tar

popd
# Cleanup conda/RapidWright/etc.
rm -r env
# Cleanup .git and third_party before artifact collection.
rm -r third_party .git

# Make sure working directory doesn't exceed disk space limit!
echo "Working directory size: $(du -sh)"
if [[ $(du -s | cut -d $'\t' -f 1) -gt $(expr 1024 \* 1024 \* 45) ]]; then
    echo "Working directory too large!"
    exit 1
fi
