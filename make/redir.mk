# Disable the inbuilt Makefile rules which are useless for us.
.SUFFIXES:
MAKEFLAGS += --no-builtin-rules

SHELL := /bin/bash

REDIR_LINK := $(abspath $(lastword $(MAKEFILE_LIST)))
REDIR_LINK_DIR := $(dir $(REDIR_LINK))
REDIR_MK_FILE := $(realpath $(REDIR_LINK))
COMMON_MK_DIR := $(dir $(REDIR_MK_FILE))

TOP_DIR   := $(realpath $(COMMON_MK_DIR)/..)

Makefile:
	@true

phony:
	@true

.PHONY: phony

%:: phony
	$(MAKE) -C $(TOP_DIR) $(abspath $@)

all: phony
	$(MAKE) -C $(TOP_DIR) CURRENT_DIR=$(REDIR_LINK_DIR) all

merged: phony
	$(MAKE) -C $(TOP_DIR) CURRENT_DIR=$(REDIR_LINK_DIR) merged

files: phony
	$(MAKE) -C $(TOP_DIR) CURRENT_DIR=$(REDIR_LINK_DIR) files

render: phony
	$(MAKE) -C $(TOP_DIR) CURRENT_DIR=$(REDIR_LINK_DIR) render

render.%: phony
	$(MAKE) -C $(TOP_DIR) CURRENT_DIR=$(REDIR_LINK_DIR) $@

view: phony
	$(MAKE) -C $(TOP_DIR) CURRENT_DIR=$(REDIR_LINK_DIR) view

view.%: phony
	$(MAKE) -C $(TOP_DIR) CURRENT_DIR=$(REDIR_LINK_DIR) $@

clean: phony
	$(MAKE) -C $(TOP_DIR) CURRENT_DIR=$(REDIR_LINK_DIR) clean

.DEFAULT_GOAL := all
