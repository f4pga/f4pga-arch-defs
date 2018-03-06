#!/bin/bash

source .travis/common.sh
set -e

# Close the after_success.1 fold travis has created already.
travis_fold end before_cache

start_section "conda.clean.1" "${GREEN}Clean status...${NC}"
conda clean -s --dry-run
end_section "conda.clean.1"

start_section "conda.clean.2" "${GREEN}Cleaning...${NC}"
conda build purge
end_section "conda.clean.2"

start_section "conda.clean.3" "${GREEN}Clean status...${NC}"
conda clean -s --dry-run
end_section "conda.clean.3"
