#!/bin/bash

source .travis/common.sh
set -e

# Close the after_failure fold travis has created already.
travis_fold end after_failure

start_section "failure.output" "${RED}Failure output...${NC}"
echo "TODO!"
end_section "failure.output"

$SPACER
