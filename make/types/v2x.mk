# Automatic conversion of Verilog to XML
include $(TOP_DIR)/make/inc/common.mk
include $(TOP_DIR)/make/inc/files.mk

PB_TYPE_GEN_CMD := $(UTILS_DIR)/vlog/vlog_to_pbtype.py
MODEL_GEN_CMD   := $(UTILS_DIR)/vlog/vlog_to_model.py
CMD_LIB = $(wildcard $(UTILS_DIR)/vlog/lib/*.py)

# Default top level module is directory name, a reasonable assumption for non-W
# modules. Can be overridden if needed
ifneq (,$(TOP_MODULE))
TOP_ARG := --top $(TOP_MODULE)
endif

V2X_INPUTS := $(call find_nontemplate_files,$(INC_DIR)/*.sim.v)
ifeq (,$(V2X_INPUTS))
$(error $(INC_DIR)/Makefile.v2x: Unable to find any inputs!)
endif

# xxx.pb_type.xml ----

PB_TYPE_OUTPUTS := $(foreach F,$(V2X_INPUTS),$(patsubst %.sim.v,%.pb_type.xml,$(F)))

# Deps
$(PB_TYPE_OUTPUTS): $(PB_TYPE_GEN_CMD)
$(PB_TYPE_OUTPUTS): $(CMD_LIB)
$(PB_TYPE_OUTPUTS): $(INC_FILE)

# Settings
$(PB_TYPE_OUTPUTS): TOP_ARG := $(TOP_ARG)
$(PB_TYPE_OUTPUTS): PB_TYPE_GEN_CMD := $(PB_TYPE_GEN_CMD)

$(PB_TYPE_OUTPUTS): %.pb_type.xml: %.sim.v
	@$(PB_TYPE_GEN_CMD) $(TOP_ARG) -o $(TARGET) $(PREREQ_FIRST)

OUTPUTS += $(PB_TYPE_OUTPUTS)

# xxx.model.xml ------

MODEL_OUTPUTS := $(foreach F,$(V2X_INPUTS),$(patsubst %.sim.v,%.model.xml,$(F)))

# Deps
$(MODEL_OUTPUTS): $(MODEL_GEN_CMD)
$(MODEL_OUTPUTS): $(CMD_LIB)
$(MODEL_OUTPUTS): $(INC_FILE)

# Settings
$(MODEL_OUTPUTS): TOP_ARG := $(TOP_ARG)
$(MODEL_OUTPUTS): MODEL_GEN_CMD := $(MODEL_GEN_CMD)

$(MODEL_OUTPUTS): %.model.xml: %.sim.v
	@$(MODEL_GEN_CMD) $(TOP_ARG) -o $(TARGET) $(PREREQ_FIRST)

OUTPUTS += $(MODEL_OUTPUTS)
