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

INT_OUTPUTS := $(INC_DIR)/$(PRJXRAY_LINT).pb_type.xml $(INC_DIR)/$(PRJXRAY_LINT).model.xml

# Depend on the Makefile config
$(INT_OUTPUTS): $(INC_FILE)
# Depend on the importer code
$(INT_OUTPUTS): $(INT_IMPORT)
# Depend on the prjxray database
$(INT_OUTPUTS): $(PRJXRAY_INFO) $(PRJXRAY_DB)

# Set the config values on the target
$(INT_OUTPUTS): INT_IMPORT := $(INT_IMPORT)
$(INT_OUTPUTS): PRJXRAY_INT := $(PRJXRAY_INT)
$(INT_OUTPUTS): PRJXRAY_PART := $(PRJXRAY_PART)

# Actual build rule
$(INT_OUTPUTS):
	$(call quiet_cmd,$(INT_IMPORT) --part $(PRJXRAY_PART) --tile $(PRJXRAY_INT) --output-pb-type $(TARGET),$(GENERATED_FROM))

OUTPUTS += $(INT_OUTPUTS)
