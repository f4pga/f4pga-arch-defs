#!/bin/bash

source $(dirname "$0")/common.sh
set -e

start_section "symbiflow.configure_cmake" "Configuring CMake (make env)"
make env
source env/conda/bin/activate symbiflow_arch_def_base
cd build
end_section "symbiflow.configure_cmake"

# Output some useful info
start_section "info.conda.env" "Info on ${YELLOW}conda environment${NC}"
conda info
end_section "info.conda.env"

start_section "info.conda.config" "Info on ${YELLOW}conda config${NC}"
conda config --show
end_section "info.conda.config"

make_target check_python "Check code formatting"

make_target lint_python "Check code style"

make_target test_python "Run Python unit tests"

make_target all_merged_arch_xmls "Build all arch XMLs"

start_section "symbiflow.build_all_rrgraph_xmls" "Build all rrgraph XMLs."
make all_rrgraph_xmls
end_section "symbiflow.build_all_rrgraph_xmls"

make_target all_route_tests "Complete all routing tests"

echo "Suppressing some xml linting, as the 5k/8k parts cannot be built on GH actions."
MAKE_JOBS=1	# workaround for possible race condition
make_target all_xml_lint "Complete all xmllint"

# TODO: Check tests are broken, yosys regression?
#start_section "symbiflow.run_check_tests" "Complete all equivalence tests"
#make all_check_tests
#end_section "symbiflow.run_check_tests"

echo "Suppressing some demo bitstreams, as the 8k parts cannot be built on GH actions."
make_target all "Building all demo bitstreams"
