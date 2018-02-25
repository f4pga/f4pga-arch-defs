
SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
TOP_DIR := $(realpath $(SELF_DIR)/../../)

.SUFFIXES:

ifeq ($(PRJXRAY_PART),)
$(error "Please set PRJXRAY_PART")
endif
ifeq ($(PRJXRAY_CLB),)
$(error "Please set PRJXRAY_CLB")
endif

PRJXRAY_LCLB := $(shell echo $(PRJXRAY_CLB) | tr A-Z a-z)

PRJXRAY_INFO = $(TOP_DIR)/third_party/prjxray-db/Info.md
PRJXRAY_DB = $(TOP_DIR)/third_party/prjxray-db/$(PRJXRAY_PART)/
CLB_IMPORT = $(TOP_DIR)/artix7/utils/prjxray-clb-import.py

pb_type.xml: $(CLB_IMPORT) $(PRJXRAY_INFO) $(PRJXRAY_DB)/*$(PRJXRAY_LCLB)*.db
	$(CLB_IMPORT) --part $(PRJXRAY_PART) --tile $(PRJXRAY_CLB) --output-pb-type $@ --output-model /dev/null

model.xml: $(CLB_IMPORT) $(PRJXRAY_INFO) $(PRJXRAY_DB)/*$(PRJXRAY_LCLB)*.db
	$(CLB_IMPORT) --part $(PRJXRAY_PART) --tile $(PRJXRAY_CLB) --output-pb-type /dev/null --output-model $@

all: pb_type.xml model.xml
	@true

clean:
	rm pb_type.xml

.DEFAULT_GOAL := all
