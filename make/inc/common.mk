ifeq (,$(INC_COMMON_MK))
INC_COMMON_MK := 1

# Disable the inbuilt Makefile rules which are useless for us.
.SUFFIXES:
MAKEFLAGS += --no-builtin-rules

# Make Python dictionary order deterministic.
PYTHONHASHSEED := 0
export PYTHONHASHSEED

SHELL := /bin/bash

# Location information.
COMMON_MK_FILE := $(realpath $(lastword $(MAKEFILE_LIST)))
COMMON_MK_DIR  := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

TOP_DIR   := $(realpath $(COMMON_MK_DIR)/../..)
UTILS_DIR := $(realpath $(TOP_DIR)/utils)

# Human readable aliases for the 'Automatic Variables' because I can never
# remember what $@ / $< etc mean.
# See [10.5.3 Automatic Variables](https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html)
TARGET = $@
TARGET_DIR = $(@D)
TARGET_FILE = $(@F)
PREREQ_FIRST = $<
PREREQ_FIRST_DIR = $(<D)
PREREQ_FIRST_FILE = $(<F)

PREREQ_NEWER = $?
PREREQ_ALL = $^
TARGET_STEM = $*

# For verbose..
ifeq (,$(V))
ECHO = @true
else
ECHO = @echo
endif

endif

ifeq (,$(CURRENT_DIR))
FILTER_PATH := $(TOP_DIR)
else
override CURRENT_DIR := $(realpath $(CURRENT_DIR))
FILTER_PATH := $(realpath $(CURRENT_DIR))
endif

FILTER_IN    := $(FILTER_PATH)/*
FILTER_BELOW := $(FILTER_PATH)/**
FILTER_STRIP := $(FILTER_PATH)/

include $(TOP_DIR)/make/inc/env.mk
