#!/bin/bash

source .travis/common.sh
set -e

$SPACER

start_section "symbiflow.merged" "Running ${GREEN}make merged${NC}"
make merged
end_section "symbiflow.merged"

start_section "symbiflow.render" "Running second ${GREEN}make render${NC}"
# TODO(mithro): Make this not fail
make -k render || true
end_section "symbiflow.render"

$SPACER

start_section "symbiflow.test" "Running ${GREEN}make test${NC}"
make test
end_section "symbiflow.test"

$SPACER

start_section "symbiflow.info.1" "Info on ${YELLOW}listfiles${NC}"
utils/listfiles.py | sed -e"s@^$PWD/@@"
end_section "symbiflow.info.1"

start_section "symbiflow.info.2" "Info on ${YELLOW}.gitignore${NC}"
cat .gitignore
end_section "symbiflow.info.2"

start_section "symbiflow.info.3" "Info on ${YELLOW}git status${NC}"
git status
end_section "symbiflow.info.3"

$SPACER

start_section "symbiflow.clean" "Running ${GREEN}make clean${NC}"
make clean
end_section "symbiflow.clean"

$SPACER
