#!/bin/bash

source .travis/common.sh
set -e

$SPACER

start_section "symbiflow.merged" "Running ${GREEN}make merged${NC}"
make merged
end_section "symbiflow.merged"

start_section "symbiflow.render" "Running ${GREEN}make render-each${NC}"
make render-each
end_section "symbiflow.render"

start_section "symbiflow.gitexclude" "Running ${GREEN}make .git/info/exclude${NC}"
make .git/info/exclude
end_section "symbiflow.gitexclude"

$SPACER

start_section "symbiflow.test" "Running ${GREEN}make test${NC}"
make test
end_section "symbiflow.test"

$SPACER

start_section "symbiflow.info.1" "Info on ${YELLOW}listfiles${NC}"
utils/listfiles.py | sed -e"s@^$PWD/@@"
end_section "symbiflow.info.1"

start_section "symbiflow.info.2" "Info on ${YELLOW}.git/info/exclude${NC}"
cat .git/info/exclude
end_section "symbiflow.info.2"

start_section "symbiflow.info.3" "Info on ${YELLOW}git status${NC}"
git status
end_section "symbiflow.info.3"

$SPACER

start_section "symbiflow.clean" "Running ${GREEN}make clean${NC}"
make clean
end_section "symbiflow.clean"

$SPACER

start_section "symbiflow.redir.1" "Running ${GREEN}make redir${NC}"
make redir
end_section "symbiflow.redir.1"

start_section "symbiflow.redir.1" "Running ${GREEN}make${NC} in ${YELLOW}vpr${NC}"
(
	cd vpr
	make || exit $?
)
end_section "symbiflow.redir.1"

$SPACER
