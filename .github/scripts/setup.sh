#!/bin/bash

source $(dirname "$0")/common.sh
set -e

start_section "symbiflow.install" "Installing packages"
apt update
apt install -y \
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
        ninja-build \
        nodejs \
        openjdk-11-jdk \
        pixz \
        python \
        python3 \
        python3-dev \
        python3-pytest \
        python3-virtualenv \
        python3-yaml \
        psmisc \
        virtualenv \
        wget
end_section "symbiflow.install"

start_section "symbiflow.configure_cmake" "Configuring CMake (make env)"
make env
end_section "symbiflow.configure_cmake"

source env/conda/bin/activate f4pga_arch_def_base

# Output some useful info
start_section "info.conda.env" "Info on ${YELLOW}conda environment${NC}"
conda info
end_section "info.conda.env"

start_section "info.conda.config" "Info on ${YELLOW}conda config${NC}"
conda config --show
end_section "info.conda.config"
