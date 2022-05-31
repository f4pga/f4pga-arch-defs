#!/usr/bin/env bash

export CMAKE_FLAGS="-GNinja -DLIGHT_BUILD=ON"
source $(dirname "$0")/setup.sh

set -e
source $(dirname "$0")/common.sh

pushd build

make_target check_python "Check code formatting"

make_target lint_python "Check code style"

make_target test_python "Run Python unit tests"

make_target all_merged_arch_xmls "Build all arch XMLs"

make_target all_rrgraph_xmls "Build all rrgraph XMLs."

make_target all_route_tests "Complete all routing tests"

make_target all_xml_lint "Complete all xmllint"

make_target all "Building all demo bitstreams"

popd
