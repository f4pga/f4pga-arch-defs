#!/bin/bash

source .travis/common.sh
set -e

start_section "symbiflow.files.1" "Info on ${YELLOW}files${NC} before running"
./.travis/compare-files.sh
end_section "symbiflow.files.1"

$SPACER

start_section "symbiflow.merged" "Running ${GREEN}make merged${NC}"
make merged
end_section "symbiflow.merged"

#start_section "symbiflow.render" "Running ${GREEN}make render${NC}"
#make render
#end_section "symbiflow.render"

$SPACER

start_section "symbiflow.gitexclude" "Running ${GREEN}make .git/info/exclude${NC}"
make .git/info/exclude
end_section "symbiflow.gitexclude"

start_section "symbiflow.info.1" "Info on ${YELLOW}.git/info/exclude${NC}"
cat .git/info/exclude
end_section "symbiflow.info.1"

$SPACER

start_section "symbiflow.files.2" "Info on ${YELLOW}files${NC} after running"
./.travis/compare-files.sh
end_section "symbiflow.files.2"

$SPACER

start_section "symbiflow.test" "Running ${GREEN}make test${NC}"
make test
end_section "symbiflow.test"

#start_section "symbiflow.files.3" "Info on ${YELLOW}files${NC} after testing"
#./.travis/compare-files.sh
#end_section "symbiflow.files.3"

$SPACER

start_section "symbiflow.clean" "Running ${GREEN}make clean${NC}"
make clean
end_section "symbiflow.clean"

start_section "symbiflow.files.4" "Info on ${YELLOW}files${NC} after clean"
./.travis/compare-files.sh
end_section "symbiflow.files.4"

$SPACER

start_section "symbiflow.redir.1" "Running ${GREEN}make redir${NC}"
make redir
end_section "symbiflow.redir.1"

start_section "symbiflow.redir.2" "Running ${GREEN}make${NC} inside ${PURPLE}vpr${NC} directory"
(
	cd vpr
	make || exit $?
)
end_section "symbiflow.redir.2"

$SPACER
