ifeq ($(PRJXRAY_PART),)
$(error "Please set PRJXRAY_PART")
endif
ifeq ($(PRJXRAY_CLB),)
$(error "Please set PRJXRAY_CLB")
endif

PRJXRAY_LCLB := $(call lc,$(PRJXRAY_CLB))

PRJXRAY_INFO := $(TOP_DIR)/third_party/prjxray-db/Info.md
PRJXRAY_DB   := $(wildcard $(TOP_DIR)/third_party/prjxray-db/$(PRJXRAY_PART)/*$(PRJXRAY_LCLB)*.db)
CLB_IMPORT   := $(TOP_DIR)/artix7/utils/prjxray-clb-import.py

$(INC_DIR)/$(PRJXRAY_LCLB).pb_type.xml $(INC_DIR)/$(PRJXRAY_LCLB).model.xml: $(INC_FILE) $(CLB_IMPORT) $(PRJXRAY_INFO) $(PRJXRAY_DB)
	$(CLB_IMPORT) --part $(PRJXRAY_PART) --tile $(PRJXRAY_CLB) --output-pb-type $(PRJXRAY_LCLB).pb_type.xml --output-model $(PRJXRAY_LCLB).model.xml

OUTPUTS += $(INC_DIR)/$(PRJXRAY_LCLB).pb_type.xml $(INC_DIR)/$(PRJXRAY_LCLB).model.xml
