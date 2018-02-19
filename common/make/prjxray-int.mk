
SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
TOP_DIR := $(realpath $(SELF_DIR)/../../)

.SUFFIXES:

ifeq ($(PRJXRAY_PART),)
$(error "Please set PRJXRAY_PART")
endif
ifeq ($(PRJXRAY_INT),)
$(error "Please set PRJXRAY_INT")
endif

PRJXRAY_LINT := $(shell echo $(PRJXRAY_INT) | tr A-Z a-z)

PRJXRAY_INFO = $(TOP_DIR)/third_party/prjxray-db/Info.md
PRJXRAY_DB = $(TOP_DIR)/third_party/prjxray-db/$(PRJXRAY_PART)/
INT_IMPORT = $(TOP_DIR)/utils/prjxray-int-import.py

pb_type.xml: $(INT_IMPORT) $(PRJXRAY_INFO) $(PRJXRAY_DB)/*$(PRJXRAY_LINT)*.db
	$(INT_IMPORT) --part $(PRJXRAY_PART) --tile $(PRJXRAY_INT) --output-pb-type $@

all: pb_type.xml
	@true

clean:
	rm -f pb_type.xml

.DEFAULT_GOAL := all
