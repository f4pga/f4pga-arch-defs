# Automatic conversion of Verilog to XML
include $(TOP_DIR)/make/inc/files.mk

PB_TYPE_GEN_CMD := $(UTILS_DIR)/vlog/vlog_to_pbtype.py
MODEL_GEN_CMD   := $(UTILS_DIR)/vlog/vlog_to_model.py

# Default top level module is directory name, a reasonable assumption for non-W
# modules. Can be overridden if needed
ifeq (,$(TOP_MODULE))
$(INC_DIR)_TOP_MODULE := $(notdir $(INC_DIR))
else
$(INC_DIR)_TOP_MODULE := $(TOP_MODULE)
endif

$(INC_DIR)_INPUTS  := $(call find_files,$(INC_DIR)/%.v)
$(info $(INC_DIR))
$(info $($(INC_DIR)_INPUTS))
ifeq (,$($(INC_DIR)_INPUTS))
$(error "$(INC_DIR)/Makefile.v2x: Unable to find any inputs!")
endif
$(INC_DIR)_OUTPUTS := $(foreach F,$($(INC_DIR)_INPUTS),$(patsubst %.sim.v,%.pb_type.xml,$(F)) $(patsubst %.sim.v,%.pb_type.xml,$(F)))

$(INC_DIR)/%.pb_type.xml: TOP_MODULE=$($(INC_DIR)_TOP_MODULE)
$(INC_DIR)/%.pb_type.xml: $(PB_TYPE_GEN_CMD)
$(INC_DIR)/%.pb_type.xml: $(INC_FILE)

$(INC_DIR)/%.pb_type.xml: %.sim.v
	$(PB_TYPE_GEN_CMD) --top $(TOP_MODULE) -o $@ $<

$(INC_DIR)/%.model.xml: TOP_MODULE=$($(INC_DIR)_TOP_MODULE)
$(INC_DIR)/%.model.xml: $(MODEL_GEN_CMD)
$(INC_DIR)/%.model.xml: $(INC_FILE)

$(INC_DIR)/%.model.xml: %.sim.v
	$(MODEL_GEN_CMD) --top $(TOP_MODULE) -o $@ $<

OUTPUTS += $($(INC_DIR)_OUTPUTS)
