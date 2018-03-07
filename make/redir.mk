# Disable the inbuilt Makefile rules which are useless for us.
.SUFFIXES:
MAKEFLAGS += --no-builtin-rules

COMMON_MK_FILE := $(realpath $(lastword $(MAKEFILE_LIST)))
COMMON_MK_DIR  := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

TOP_DIR   := $(realpath $(COMMON_MK_DIR)/..)

%::
	$(MAKE) -C $(TOP_DIR) $(abspath $@)

render:
	$(MAKE) -C $(TOP_DIR) CURRENT_DIR=$(abspath .) render

view:
	$(MAKE) -C $(TOP_DIR) CURRENT_DIR=$(abspath .) view

clean:
	$(MAKE) -C $(TOP_DIR) CURRENT_DIR=$(abspath .) clean
