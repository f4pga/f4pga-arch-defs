#!/bin/bash

source .github/travis/common.sh
set -e

$SPACER

start_section "symbiflow.configure_cmake" "Configuring CMake (make env)"
make env
cd build
end_section "symbiflow.configure_cmake"

$SPACER

run_section "symbiflow.conda" "Setting up basic ${YELLOW}conda environment${NC}" "make all_conda"

$SPACER

# Output some useful info
start_section "info.conda.env" "Info on ${YELLOW}conda environment${NC}"
env/conda/bin/conda info
end_section "info.conda.env"

start_section "info.conda.config" "Info on ${YELLOW}conda config${NC}"
env/conda/bin/conda config --show
end_section "info.conda.config"

$SPACER

run_section "symbiflow.format" "Check code formatting" "make check_python"

$SPACER

run_section "symbiflow.lint" "Check code style" "make lint_python"

$SPACER

run_section "symbiflow.run_v2x_tests" "Run v2x unit tests" "make all_v2x_tests"

$SPACER

run_section "symbiflow.run_python_tests" "Run Python unit tests" "make test_python"

$SPACER

run_section "symbiflow.build_all_arch_xmls" "Build all arch XMLs" "make all_merged_arch_xmls"

$SPACER

echo "Suppressing all_rrgraph_xmls generation, as the 8k parts cannot be built on travis."
start_section "symbiflow.build_all_rrgraph_xmls" "Build all rrgraph XMLs."
#make all_rrgraph_xmls
end_section "symbiflow.build_all_rrgraph_xmls"

$SPACER

run_section "symbiflow.route_all_tests" "Complete all routing tests" "make all_route_tests"

$SPACER

echo "Suppressing some xml linting, as the 5k/8k parts cannot be built on travis."
run_section "symbiflow.xmllint_all" "Complete all xmllint" "make all_xml_lint"

$SPACER

# TODO: Check tests are broken, yosys regression?
#start_section "symbiflow.run_check_tests" "Complete all equivalence tests"
#make all_check_tests
#end_section "symbiflow.run_check_tests"

$SPACER

echo "Suppressing some demo bitstreams, as the 8k parts cannot be built on travis."
run_section "symbiflow.build_all_demos" "Building all demo bitstreams" "make all"

$SPACER
