ifeq ($(PRJXRAY_PART),)
$(error "Please set PRJXRAY_PART")
endif
ifeq ($(PRJXRAY_INT),)
$(error "Please set PRJXRAY_INT")
endif

PRJXRAY_LINT := $(call lc,$(PRJXRAY_INT))

PRJXRAY_INFO = $(TOP_DIR)/third_party/prjxray-db/Info.md
PRJXRAY_DB = $(TOP_DIR)/third_party/prjxray-db/$(PRJXRAY_PART)/
INT_IMPORT = $(TOP_DIR)/artix7/utils/prjxray-int-import.py

$(PRJXRAY_LINT).pb_type.xml: $(INT_IMPORT) $(PRJXRAY_INFO) $(PRJXRAY_DB)/*$(PRJXRAY_LINT)*.db
	$(INT_IMPORT) --part $(PRJXRAY_PART) --tile $(PRJXRAY_INT) --output-pb-type $@

INT_OUTPUTS := $(PRJXRAY_LINT).pb_type.xml $(PRJXRAY_LINT).model.xml

clean_int:
	rm $(INT_OUTPUTS)

clean: clean_int
