#!/bin/bash

source .travis/common.sh
set -e

# Close the after_success.1 fold travis has created already.
travis_time_finish
travis_fold end after_failure.1

start_section "failure.output" "${RED}Failure output...${NC}"
echo "TODO!"
end_section "failure.output"

$SPACER
