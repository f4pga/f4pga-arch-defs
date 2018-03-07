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

CLB_OUTPUTS := $(INC_DIR)/$(PRJXRAY_LCLB).pb_type.xml $(INC_DIR)/$(PRJXRAY_LCLB).model.xml

# Depend on the Makefile config
$(CLB_OUTPUTS): $(INC_FILE)
# Depend on the importer code
$(CLB_OUTPUTS): $(CLB_IMPORT)
# Depend on the prjxray database
$(CLB_OUTPUTS): $(PRJXRAY_INFO) $(PRJXRAY_DB)

# Set the config values on the target
$(CLB_OUTPUTS): INC_DIR := $(INC_DIR)
$(CLB_OUTPUTS): CLB_IMPORT := $(CLB_IMPORT)
$(CLB_OUTPUTS): PRJXRAY_CLB := $(PRJXRAY_CLB)
$(CLB_OUTPUTS): PRJXRAY_LCLB := $(PRJXRAY_LCLB)
$(CLB_OUTPUTS): PRJXRAY_PART := $(PRJXRAY_PART)

# Actual target which will run
$(CLB_OUTPUTS):
	$(call quiet_cmd,$(CLB_IMPORT) --part $(PRJXRAY_PART) --tile $(PRJXRAY_CLB) --output-pb-type $(INC_DIR)/$(PRJXRAY_LCLB).pb_type.xml --output-model $(INC_DIR)/$(PRJXRAY_LCLB).model.xml,$(GENERATED_FROM))

OUTPUTS += $(CLB_OUTPUTS)
