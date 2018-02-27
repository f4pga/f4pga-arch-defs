include $(COMMON_MK_DIR)/files.mk
include $(COMMON_MK_DIR)/func.mk

# Generate dependencies from files.
# ------------------

## Then ntemplates
#MAKEFILES_N := $(call find_files,*/Makefile.N)
#FILES_INPUT_N :=
#FILES_OUTPUT_N :=
#include $(MAKEFILES_N)
#FILES_INPUT_N := $(sort $(FILES_INPUT_N))
#FILES_OUTPUT_N := $(sort $(FILES_OUTPUT_N))

# ------------------------------------------
# Generate XML dependencies
# ------------------------------------------
DEPS_XML_INPUTS  := $(call find_nontemplate_files,*.xml)
DEPS_XML_OUTPUTS := $(foreach F,$(DEPS_XML_INPUTS),$(call depend_on_deps,$(F)))

$(DEPS_XML_OUTPUTS): $(call depend_on_deps,%.xml): $(call depend_on_only,%.xml)
	@$(DEPS_XML_TOOL) $(PREREQ_FIRST)

# Depend on the XML dependency generation tool
DEPS_XML_TOOL := $(UTILS_DIR)/deps_xml.py
DEPS_XML_TOOL_FILES := $(DEPS_XML_TOOL) $(UTILS_DIR)/lib/deps.py
$(DEPS_XML_OUTPUTS): $(call depend_on_deps,%.xml): $(DEPS_XML_TOOL_FILES)

ifneq ($(MAKECMDGOALS),clean)
-include $(DEPS_XML_OUTPUTS)
endif

# ------------------------------------------
# Generate Verilog dependencies
# ------------------------------------------
DEPS_VERILOG_INPUTS  := $(call find_nontemplate_files,*.v)
DEPS_VERILOG_OUTPUTS := $(foreach F,$(DEPS_VERILOG_INPUTS),$(call depend_on_deps,$(F)))

$(DEPS_VERILOG_OUTPUTS): $(call depend_on_deps,%.v): $(call depend_on_only,%.v)
	@$(DEPS_VERILOG_TOOL) $(PREREQ_FIRST)

# Depend on the Verilog dependency generation tool
DEPS_VERILOG_TOOL := $(UTILS_DIR)/deps_verilog.py
DEPS_VERILOG_TOOL_FILES := $(DEPS_VERILOG_TOOL) $(UTILS_DIR)/lib/deps.py

$(DEPS_VERILOG_OUTPUTS): $(call depend_on_deps,%.v): $(DEPS_VERILOG_TOOL_FILES)

ifneq ($(MAKECMDGOALS),clean)
-include $(DEPS_VERILOG_OUTPUTS)
endif
