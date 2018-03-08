#!/bin/bash

source .travis/common.sh
set -e

# Close the after_success fold travis has created already.
travis_fold end after_success

if [ x$TRAVIS_BRANCH = x"master" -a x$TRAVIS_EVENT_TYPE != x"cron" -a x$TRAVIS_PULL_REQUEST != xfalse ]; then
	start_section "package.upload" "${GREEN}Package uploading...${NC}"
	echo "TODO!"
	end_section "package.upload"
fi
