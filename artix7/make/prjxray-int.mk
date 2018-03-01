ifeq ($(PRJXRAY_PART),)
$(error "Please set PRJXRAY_PART")
endif
ifeq ($(PRJXRAY_INT),)
$(error "Please set PRJXRAY_INT")
endif

PRJXRAY_LINT := $(call lc,$(PRJXRAY_INT))

PRJXRAY_INFO := $(TOP_DIR)/third_party/prjxray-db/Info.md
PRJXRAY_DB   := $(wildcard $(TOP_DIR)/third_party/prjxray-db/$(PRJXRAY_PART)/*$(PRJXRAY_LINT)*.db)
INT_IMPORT   := $(TOP_DIR)/artix7/utils/prjxray-int-import.py

$(INC_DIR)/$(PRJXRAY_LINT).pb_type.xml: $(INC_FILE) $(INT_IMPORT) $(PRJXRAY_INFO) $(PRJXRAY_DB)
	$(INT_IMPORT) --part $(PRJXRAY_PART) --tile $(PRJXRAY_INT) --output-pb-type $@

OUTPUTS += $(INC_DIR)/$(PRJXRAY_LINT).pb_type.xml $(INC_DIR)/$(PRJXRAY_LINT).model.xml
