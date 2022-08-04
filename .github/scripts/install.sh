#!/usr/bin/env bash

set -e

INSTALL_DIR="$(pwd)/install"
mkdir -p $INSTALL_DIR

case "$1" in
  eos-s3|ql) export FPGA_FAM=eos-s3 ;;
  *)         export FPGA_FAM=xc7    ;;
esac

echo "Set CMAKE_FLAGS"
case "$FPGA_FAM" in
  xc7)
    INSTALL_FAMILIES='xc7'
  ;;
  eos-s3)
    INSTALL_FAMILIES='qlf_k4n8,pp3'
  ;;
  *)
    echo "Unknown FPGA_FAM <$FPGA_FAM>!"
    exit 1
  ;;
esac
export CMAKE_FLAGS="-GNinja -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -DINSTALL_FAMILIES=${INSTALL_FAMILIES}"

echo "Set environment variables for F4PGA CLI utils"
export F4PGA_INSTALL_DIR="placeholder"
# TODO: We should place the content in subdir F4PGA_FAM, to use the default in f4pga instead of overriding F4PGA_ENV_SHARE here.
case "$FPGA_FAM" in
  xc7)    export F4PGA_SHARE_DIR="$(cd $(dirname "$0"); pwd)/../../install/share/f4pga" ;;
  eos-s3) export F4PGA_SHARE_DIR="${INSTALL_DIR}"/share/f4pga ;;
esac

source $(dirname "$0")/setup-and-activate.sh

echo "----------------------------------------"

pushd build
make_target install "Installing toolchain (make install)"
popd

cp \
  packaging/"$FPGA_FAM"_environment.yml \
  packaging/requirements.txt \
  packaging/"$FPGA_FAM"_requirements.txt \
  $INSTALL_DIR/

echo "----------------------------------------"

heading "Running installed toolchain tests"
pushd build
export VPR_NUM_WORKERS=${MAX_CORES}
export CTEST_OUTPUT_ON_FAILURE=1
case "$FPGA_FAM" in
  xc7)
    ctest -R binary_toolchain_test_xc7* -j${MAX_CORES}
  ;;
  eos-s3)
    heading "Testing installed toolchain on qlf_k4n8"
    ctest -j${MAX_CORES} -R "quicklogic_toolchain_test_.*_qlf_k4n8" -VV
    echo "----------------------------------------"
    heading "Testing installed toolchain on ql_eos_s3"
    ctest -j${MAX_CORES} -R "quicklogic_toolchain_test_.*_ql-eos-s3" -VV
  ;;
esac
popd
echo "----------------------------------------"

heading "Compressing install dir (creating packages)"
rm -rf build
# Remove symbolic links and copy content of the linked files
for file in $(find install -type l)
  do cp --remove-destination $(readlink $file) $file
done

du -ah install
export GIT_HASH=$(git rev-parse --short HEAD)

pushd install
mkdir -p "$FPGA_FAM"_env
mv "$FPGA_FAM"_environment.yml \
  requirements.txt \
  "$FPGA_FAM"_requirements.txt \
  "$FPGA_FAM"_env
popd

case "$FPGA_FAM" in
  xc7)
    tar -I "pixz" -cvf \
      symbiflow-arch-defs-install-xc7-${GIT_HASH}.tar.xz \
      -C install \
        share/f4pga/techmaps \
        share/f4pga/scripts \
        "$FPGA_FAM"_env
    tar -I "pixz" -cvf \
      symbiflow-arch-defs-benchmarks-xc7-${GIT_HASH}.tar.xz \
      -C install \
        benchmarks
    for device in $(ls install/share/f4pga/arch); do
      if [[ $device = xc7* ]]; then
        tar -I "pixz" -cvf \
          symbiflow-arch-defs-$device-${GIT_HASH}.tar.xz \
          -C install \
            share/f4pga/arch/$device
      fi
    done
  ;;
  eos-s3)
    tar -I "pixz" -cvf \
      symbiflow-arch-defs-install-ql-${GIT_HASH}.tar.xz \
      -C install \
        share/f4pga/techmaps \
        share/f4pga/scripts \
        "$FPGA_FAM"_env
    for device in $(ls install/share/f4pga/arch); do
      if [[ $device = ql* ]]; then
        tar -I "pixz" -cvf \
          symbiflow-arch-defs-$device-${GIT_HASH}.tar.xz \
            -C install \
            share/f4pga/arch/$device
      fi
    done
  ;;
esac
rm -rf install
echo "----------------------------------------"
