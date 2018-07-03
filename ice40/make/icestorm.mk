
ICESTORM_DB := $(TOP_DIR)/third_party/icestorm/icebox/icebox.py

ICESTORM_LAYOUT_LIST := $(TOP_DIR)/ice40/utils/ice40_list_layout_in_icebox.py
ICESTORM_LAYOUT_PARTS := $(shell $(ICESTORM_LAYOUT_LIST))

ICESTORM_LAYOUT_OUTPUTS := $(foreach P,$(ICESTORM_LAYOUT_PARTS),$(INC_DIR)/$(P).fixed_layout.xml $(INC_DIR)/$(P).pinmap.csv)

ICESTORM_LAYOUT_IMPORT := $(TOP_DIR)/ice40/utils/ice40_import_layout_from_icebox.py
# Depend on the importer code
$(ICESTORM_LAYOUT_OUTPUTS): $(ICESTORM_LAYOUT_LIST)
$(ICESTORM_LAYOUT_OUTPUTS): $(ICESTORM_LAYOUT_IMPORT)
# Depend on the icestorm database
$(ICESTORM_LAYOUT_OUTPUTS): $(ICESTORM_DB)

$(ICESTORM_LAYOUT_OUTPUTS): INC_DIR := $(INC_DIR)
$(ICESTORM_LAYOUT_OUTPUTS): ICESTORM_LAYOUT_IMPORT := $(ICESTORM_LAYOUT_IMPORT)

# Actual build rule
$(ICESTORM_LAYOUT_OUTPUTS):
	$(call quiet_cmd,cd $(INC_DIR); $(ICESTORM_LAYOUT_IMPORT))

OUTPUTS += $(ICESTORM_LAYOUT_OUTPUTS)
