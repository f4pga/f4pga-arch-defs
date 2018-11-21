#!/bin/bash

source .travis/common.sh
set -e

$SPACER

start_section "symbiflow.configure_cmake" "Configuring CMake"
make env
cd build
end_section "symbiflow.configure_cmake"

$SPACER

start_section "symbiflow.conda" "Setting up basic ${YELLOW}conda environment${NC}"
make all_conda
end_section "symbiflow.conda"

$SPACER

# Output some useful info
start_section "info.conda.env" "Info on ${YELLOW}conda environment${NC}"
env/conda/bin/conda info
end_section "info.conda.env"

start_section "info.conda.config" "Info on ${YELLOW}conda config${NC}"
env/conda/bin/conda config --show
end_section "info.conda.config"

$SPACER

start_section "symbiflow.build_all_arch_xmls" "Build all arch XMLs."
make all_merged_arch_xmls
end_section "symbiflow.build_all_arch_xmls"

$SPACER

start_section "symbiflow.build_all_rrgraph_xmls" "Build all rrgraph XMLs."
echo "Supressing all_rrgraph_xmls generatation, as the 8k parts cannot be built on travis."
#make all_rrgraph_xmls
end_section "symbiflow.build_all_rrgraph_xmls"

$SPACER

start_section "symbiflow.route_all_tests" "Complete all routing tests"
make all_route_tests
end_section "symbiflow.route_all_tests"

$SPACER

start_section "symbiflow.xmllint_all_tests" "Complete all xmllint"
echo "Supressing some xml linting, as the 5k/8k parts cannot be built on travis."
make all_xml_lint
end_section "symbiflow.xmllint_all"

$SPACER

start_section "symbiflow.run_check_tests" "Complete all equivilence tests"
# TODO: Check tests are broken, yosys regression?
#make all_check_tests
end_section "symbiflow.run_check_tests"

$SPACER

start_section "symbiflow.build_all_demos" "Building all demo bitstreams"
echo "Supressing some demo bitstreams, as the 8k parts cannot be built on travis."
make all
end_section "symbiflow.build_all_demos"

$SPACER
