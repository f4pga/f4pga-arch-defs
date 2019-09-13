#!/bin/bash

set -e

echo
echo "========================================"
echo "Host updating packages"
echo "----------------------------------------"
sudo apt-get update
echo "----------------------------------------"

echo
echo "========================================"
echo "Host install packages"
echo "----------------------------------------"
sudo apt-get install -y \
        bash \
        bison \
        build-essential \
        ca-certificates \
        cmake \
        colordiff \
        coreutils \
        curl \
        flex \
        git \
        graphviz \
        inkscape \
        jq \
        make \
        nodejs \
        psmisc \
        python \
        python3 \
        python3-dev \
        python3-virtualenv \
        python3-yaml \
        virtualenv \
        ninja-build \

if [ -z "${BUILD_TOOL}" ]; then
    export BUILD_TOOL=make
fi

echo "----------------------------------------"

echo
echo "========================================"
echo "Setting up environment env"
echo "----------------------------------------"
(
	echo
	echo " Configuring CMake"
	echo "----------------------------------------"
	make env
	cd build
	echo "----------------------------------------"

	echo
	echo " Setting up basic conda environment"
	echo "----------------------------------------"
	${BUILD_TOOL} all_conda

	echo
	echo " Output information about conda environment"
	echo "----------------------------------------"
	env/conda/bin/conda info
	env/conda/bin/conda config --show
)
