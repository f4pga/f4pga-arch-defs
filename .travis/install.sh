#!/bin/bash

source .travis/common.sh
set -e

# Git repo fixup
.travis/git-fixup.sh

$SPACER

start_section "environment.conda" "Setting up basic ${YELLOW}conda environment${NC}"

# Getting a newer make, as Travis' make is too old.
make -f make/env.mk make

# Check we have the new make
ls -l $PWD/env/conda/bin/make
hash -r
which make

# Get the rest of the environment
make env

end_section "environment.conda"

$SPACER

# Output some useful info
start_section "info.conda.env" "Info on ${YELLOW}conda environment${NC}"
conda info
end_section "info.conda.env"

start_section "info.conda.config" "Info on ${YELLOW}conda config${NC}"
conda config --show
end_section "info.conda.config"

$SPACER
