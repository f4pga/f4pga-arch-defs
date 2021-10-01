#!/bin/bash

set -e

echo
echo "========================================"
echo "Removing older packages"
echo "----------------------------------------"
sudo apt-get remove -y cmake
echo "----------------------------------------"

echo
echo "========================================"
echo "Update the CA certificates"
echo "----------------------------------------"
sudo apt-get install -y ca-certificates
sudo update-ca-certificates
echo

echo
echo "========================================"
echo "Host not verifying certificate name matches server name"
echo "----------------------------------------"
echo | sudo tee -a /etc/apt/apt.conf.d/80-ignore-ssl-issues <<EOF
// Do not verify peer certificate
Acquire::https::Verify-Peer "false";
// Do not verify that certificate name matches server name
Acquire::https::Verify-Host "false";
EOF
echo "----------------------------------------"

echo
echo "========================================"
echo "Host adding PPAs"
echo "----------------------------------------"
wget --no-check-certificate -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | sudo apt-key add -
sudo apt-add-repository 'deb https://apt.kitware.com/ubuntu/ xenial main'
sudo add-apt-repository ppa:openjdk-r/ppa
echo "----------------------------------------"

echo
echo "========================================"
echo "Host updating packages"
echo "----------------------------------------"
sudo apt-get update
echo "----------------------------------------"

echo
echo "========================================"
echo "Host remove packages"
echo "----------------------------------------"
sudo apt-get remove -y \
	python-pytest \


sudo apt-get autoremove -y

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
        clang-format \
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
        pixz \
        openjdk-11-jdk

if [ -z "${BUILD_TOOL}" ]; then
    export BUILD_TOOL=make
fi

echo "----------------------------------------"

echo
echo "========================================"
echo "Setting up environment env"
echo "----------------------------------------"
(
	echo " Set JAVA 11 as default"
	echo "----------------------------------------"
	sudo update-alternatives --set java /usr/lib/jvm/java-11-openjdk-amd64/bin/java
	java -version
	echo "----------------------------------------"

	echo
	echo " Configuring CMake"
	echo "----------------------------------------"
	make env
	source env/conda/bin/activate symbiflow_arch_def_base
	echo "----------------------------------------"

	echo
	echo " Output information about conda environment"
	echo "----------------------------------------"
	conda info
	conda config --show
)


echo "========================================"
echo "Check core dump config"
echo "----------------------------------------"
ulimit -c unlimited
cat /proc/sys/kernel/core_pattern
sysctl kernel.core_pattern
