#!/bin/bash

source .github/travis/common.sh
set -e

$SPACER

start_section "symbiflow.configure_cmake" "Configuring CMake (make env)"
make env
cd build
end_section "symbiflow.configure_cmake"

$SPACER

make_target all_conda "Setting up basic ${YELLOW}conda environment${NC}"

$SPACER

# Output some useful info
start_section "info.conda.env" "Info on ${YELLOW}conda environment${NC}"
env/conda/bin/conda info
end_section "info.conda.env"

start_section "info.conda.config" "Info on ${YELLOW}conda config${NC}"
env/conda/bin/conda config --show
end_section "info.conda.config"

$SPACER

make_target check_python "Check code formatting"

$SPACER

make_target lint_python "Check code style"

$SPACER

make_target test_python "Run Python unit tests"

$SPACER

make_target all_merged_arch_xmls "Build all arch XMLs"

$SPACER

echo "Suppressing all_rrgraph_xmls generation, as the 8k parts cannot be built on travis."
start_section "symbiflow.build_all_rrgraph_xmls" "Build all rrgraph XMLs."
#make all_rrgraph_xmls
end_section "symbiflow.build_all_rrgraph_xmls"

$SPACER

make_target all_route_tests "Complete all routing tests"

$SPACER

echo "Suppressing some xml linting, as the 5k/8k parts cannot be built on travis."
make_target all_xml_lint "Complete all xmllint"

$SPACER

# TODO: Check tests are broken, yosys regression?
#start_section "symbiflow.run_check_tests" "Complete all equivalence tests"
#make all_check_tests
#end_section "symbiflow.run_check_tests"

$SPACER

echo "Suppressing some demo bitstreams, as the 8k parts cannot be built on travis."
make_target all "Building all demo bitstreams"

$SPACER
