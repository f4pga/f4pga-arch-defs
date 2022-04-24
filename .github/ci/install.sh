#!/bin/bash

INSTALL_DIR="$(pwd)/install"
mkdir -p $INSTALL_DIR

export CMAKE_FLAGS="-GNinja -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -DINSTALL_FAMILIES=xc7"
source $(dirname "$0")/setup-and-activate.sh

heading "Installing gsutil"
(
    apt -qqy update && apt -qqy install curl
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    apt -qqy update && apt -qqy install google-cloud-cli
)
echo "----------------------------------------"

pushd build
make_target install "Running install tests (make install)"
popd

cp environment.yml install/

echo "----------------------------------------"

heading "Install f4pga CLI through pip"
{
	pip3 install https://github.com/chipsalliance/f4pga/archive/main.zip#subdirectory=f4pga
	export F4PGA_FAM=xc7
	export F4PGA_ENV_BIN="$(cd $(dirname "$0")/../../env/conda/envs/symbiflow_arch_def_base/bin; pwd)"
	export F4PGA_ENV_SHARE="$(cd $(dirname "$0")/../../install/share/symbiflow; pwd)"
}
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
	tar -I "pixz" -cvf symbiflow-arch-defs-install-${GIT_HASH}.tar.xz -C install share/symbiflow/techmaps share/symbiflow/scripts environment.yml
	tar -I "pixz" -cvf symbiflow-arch-defs-benchmarks-${GIT_HASH}.tar.xz -C install benchmarks
	for device in $(ls install/share/symbiflow/arch)
	do
		tar -I "pixz" -cvf symbiflow-arch-defs-$device-${GIT_HASH}.tar.xz -C install share/symbiflow/arch/$device
	done
	rm -rf install
)
echo "----------------------------------------"

GCP_PATH=symbiflow-arch-defs/artifacts/prod/foss-fpga-tools/symbiflow-arch-defs/continuous/install

heading "Uploading packages"
(
    if [ "$UPLOAD_PACKAGES" = "true" ]; then
        TIMESTAMP=$(date +'%Y%m%d-%H%M%S')
        for package in $(ls *.tar.xz)
        do
            gsutil cp ${package} gs://${GCP_PATH}/${TIMESTAMP}/
        done
    else
        echo "Not uploading packages as not requested by the CI"
    fi
)
echo "----------------------------------------"
