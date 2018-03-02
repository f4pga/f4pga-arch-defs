include $(COMMON_MK_DIR)/files.mk
include $(COMMON_MK_DIR)/func.mk

# Dependency functions
# -------------------------------

# Allow people to depend on either;
#  * depend_on_only - Only the file directly.
#  * depend_on_deps - On the dependencies of a file.
#  * depend_on_all  - On both the file directly and it's dependencies.
DEPS_EXT=.d
depend_on_only  = $(1)
depend_on_deps  = $(subst ./,,$(dir $(1)))$(notdir $(1))$(DEPS_EXT)
depend_on_all   = $(call depend_on_only,$(1)) $(call depend_on_deps,$(1))

DEPMK_EXT=.dmk
deps_makefile  = $(subst ./,,$(dir $(1)))$(notdir $(1))$(DEPMK_EXT)

# Add a dependency from X onto Y
define _add_dependency

ONTO := $(1)
FROM := $(2)

ifneq (,$$(call find_files,$$(FROM)))

$$(call depend_on_deps,$$(ONTO)): $$(call depend_on_all,$$(FROM))

else

$$(warning File $$(FROM) is missing! (and no generation rule either!))

ifeq (1,$(V))
$$(warning Found files in same directory: $$(call find_files,$$(dir $$(FROM))*))
endif

endif

undefine FROM
undefine ONTO

endef

# $(call add_dependency,filex,included_file1 included_file2)
# Creates the following dependency chain,
# a.d: b b.d
add_dependency = $(foreach DEP,$(2),$(eval $(call _add_dependency,$(1),$(DEP))))

# Create a target that can be referenced which is a file and all it's
# dependencies.
#
# We need this target as some rules need *only* the file, so if we add the
# dependency directly to the file they can't depend on just that.
#
# This file also *must* exist, otherwise the things depending on it will always
# get rerun.
# ------------------
#NEWEST_TOOL := $(UTILS_DIR)/newest.py

DEPS_FILES := $(foreach F,$(call find_files,*),$(call depend_on_deps,$(F)))

$(DEPS_FILES): $(call depend_on_deps,%): $(call depend_on_only,%)
	@touch $(TARGET)

#	$(NEWEST_TOOL) --output $(TARGET) $(PREREQ_ALL)

# ------------------------------------------
# Generate XML dependencies
# ------------------------------------------
DEPS_XML_INPUTS  := $(call find_nontemplate_files,*.xml)
DEPS_XML_OUTPUTS := $(foreach F,$(DEPS_XML_INPUTS),$(call deps_makefile,$(F)))

$(DEPS_XML_OUTPUTS): $(call deps_makefile,%.xml): $(call depend_on_only,%.xml)
	@$(DEPS_XML_TOOL) $(PREREQ_FIRST)

# Depend on the XML dependency generation tool
DEPS_XML_TOOL := $(UTILS_DIR)/deps_xml.py
DEPS_XML_TOOL_FILES := $(DEPS_XML_TOOL) $(UTILS_DIR)/lib/deps.py
$(DEPS_XML_OUTPUTS): $(call deps_makefile,%.xml): $(DEPS_XML_TOOL_FILES)

ifneq ($(MAKECMDGOALS),clean)
-include $(DEPS_XML_OUTPUTS)
endif

# ------------------------------------------
# Generate Verilog dependencies
# ------------------------------------------
DEPS_VERILOG_INPUTS  := $(call find_nontemplate_files,*.v)
DEPS_VERILOG_OUTPUTS := $(foreach F,$(DEPS_VERILOG_INPUTS),$(call deps_makefile,$(F)))

$(DEPS_VERILOG_OUTPUTS): $(call deps_makefile,%.v): $(call depend_on_only,%.v)
	@$(DEPS_VERILOG_TOOL) $(PREREQ_FIRST)

# Depend on the Verilog dependency generation tool
DEPS_VERILOG_TOOL := $(UTILS_DIR)/deps_verilog.py
DEPS_VERILOG_TOOL_FILES := $(DEPS_VERILOG_TOOL) $(UTILS_DIR)/lib/deps.py

$(DEPS_VERILOG_OUTPUTS): $(call deps_makefile,%.v): $(DEPS_VERILOG_TOOL_FILES)

ifneq ($(MAKECMDGOALS),clean)
-include $(DEPS_VERILOG_OUTPUTS)
endif
