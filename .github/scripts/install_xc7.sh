#!/usr/bin/env bash

INSTALL_DIR="$(pwd)/install"
mkdir -p $INSTALL_DIR

export CMAKE_FLAGS="-GNinja -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -DINSTALL_FAMILIES=xc7"
source $(dirname "$0")/setup-and-activate.sh

heading "Set environment variables for F4PGA CLI utils"
{
  export FPGA_FAM=xc7
  export F4PGA_INSTALL_DIR="placeholder"
  export F4PGA_BIN_DIR="$(cd $(dirname "$0"); pwd)/../../env/conda/envs/symbiflow_arch_def_base/bin"
  # TODO: We should place the content in subdir F4PGA_FAM, to use the default in f4pga instead of overriding F4PGA_ENV_SHARE here.
  export F4PGA_SHARE_DIR="$(cd $(dirname "$0"); pwd)/../../install/share/f4pga"
}

echo "----------------------------------------"

pushd build
make_target install "Running install tests (make install)"
popd

cp \
  packaging/"$FPGA_FAM"_environment.yml \
  packaging/requirements.txt \
  packaging/"$FPGA_FAM"_requirements.txt \
  $INSTALL_DIR/

echo "----------------------------------------"

heading "Running installed toolchain tests"
(
  pushd build
  export VPR_NUM_WORKERS=${MAX_CORES}
  export CTEST_OUTPUT_ON_FAILURE=1
  ctest -R binary_toolchain_test_xc7* -j${MAX_CORES}
  popd
)
echo "----------------------------------------"

heading "Compressing install dir (creating packages)"
(
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

  tar -I "pixz" -cvf \
    symbiflow-arch-defs-install-xc7-${GIT_HASH}.tar.xz \
    -C install \
      share/f4pga/techmaps \
      share/f4pga/scripts \
      "$FPGA_FAM"_env
  tar -I "pixz" -cvf symbiflow-arch-defs-benchmarks-xc7-${GIT_HASH}.tar.xz -C install benchmarks
  for device in $(ls install/share/f4pga/arch)
  do
    if [[ $device = xc7* ]]; then
      tar -I "pixz" -cvf symbiflow-arch-defs-$device-${GIT_HASH}.tar.xz -C install share/f4pga/arch/$device
    fi
  done
  rm -rf install
)
echo "----------------------------------------"
