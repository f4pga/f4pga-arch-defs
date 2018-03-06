include $(COMMON_MK_DIR)/files.mk
include $(COMMON_MK_DIR)/func.mk

# Dependency functions
# -------------------------------

# Allow people to depend on either;
#  * depend_on_only - Only the file directly.
#  * depend_on_deps - On the dependencies of a file.
#  * depend_on_all  - On both the file directly and it's dependencies.
DEPS_EXT=.d

deps_dir = $(TOP_DIR)/.deps$(subst $(TOP_DIR),,$(1))

depend_on_only  = $(1)
depend_on_deps  = $(call deps_dir,$(subst ./,,$(dir $(1)))$(notdir $(1))$(DEPS_EXT))
depend_on_all   = $(call depend_on_only,$(1)) $(call depend_on_deps,$(1))


DEPMK_EXT=.dmk
deps_makefile  = $(call deps_dir,$(subst ./,,$(dir $(1)))$(notdir $(1))$(DEPMK_EXT))

# Add a dependency from X onto Y
define _deps_rule
$(1): $(2)
endef

define _deps_expand_rule

# Force expansion of arguments right now
DEPS_EXPANDED_ONTO := $(1)
DEPS_EXPANDED_FROM := $(2)

$$(eval $$(call _deps_rule,$$(DEPS_EXPANDED_ONTO),$$(DEPS_EXPANDED_FROM)))

undefine DEPS_EXPANDED_ONTO
undefine DEPS_EXPANDED_FROM

endef

define _add_dependency

ADD_DEP_ONTO := $(1)
ADD_DEP_FROM := $(2)

ifneq (,$$(call find_files,$$(FROM)))

$$(eval $$(call _deps_expand_rule,$$(call depend_on_deps,$$(ADD_DEP_ONTO)),$$(call depend_on_all,$$(ADD_DEP_FROM))))

else

$$(warning File $$(ADD_DEP_FROM) is missing! (and no generation rule either!))

ifeq (2,$(V))
$$(warning Found files in same directory: $$(call find_files,$$(dir $$(ADD_DEP_FROM))*))
endif

endif

undefine ADD_DEP_FROM
undefine ADD_DEP_ONTO

endef

MKDIR_TARGET = @mkdir -p $(dir $(TARGET))

# Create a target that can be referenced which is a file and all it's
# dependencies.
#
# We need this target as some rules need *only* the file, so if we add the
# dependency directly to the file they can't depend on just that.
#
# This file also *must* exist, otherwise the things depending on it will always
# get rerun.

# $(call add_dependency,filex,included_file1 included_file2)
# Creates the following dependency chain,
# a.d: b b.d
add_dependency = $(foreach DEP,$(2),$(eval $(call _add_dependency,$(1),$(DEP))))

ifeq (,$(call should_not_include))

ifeq (2,$(V))
$(info ==========================================================================)
$(info Setting up .d files.)
$(info --------------------------------------------------------------------------)
endif

NEEDS_DEPS_FILES := $(call find_files,*)

$(foreach F,$(NEEDS_DEPS_FILES),$(eval $(call _deps_expand_rule,$(call depend_on_deps,$(F)),$(F))))

DEPS_FILES := $(foreach F,$(NEEDS_DEPS_FILES),$(call depend_on_deps,$(F)))

$(DEPS_FILES):
	$(MKDIR_TARGET)
	@touch $(TARGET)


#	$(NEWEST_TOOL) --output $(TARGET) $(PREREQ_ALL)

ifeq (2,$(V))
$(info)
$(info Finished setting up .d files.)
$(info --------------------------------------------------------------------------)
endif

#---------------------------------------------------------------------------------

ifeq (2,$(V))
$(info ==========================================================================)
$(info Setting up .dmk generation for XML files.)
$(info --------------------------------------------------------------------------)
endif

DEPS_XML_INPUTS  := $(call find_nontemplate_files,*.xml)
DEPS_XML_OUTPUTS := $(foreach F,$(DEPS_XML_INPUTS),$(call deps_makefile,$(F)))

$(foreach F,$(DEPS_XML_INPUTS),$(eval $(call _deps_expand_rule,$(call deps_makefile,$(F)),$(F))))

$(DEPS_XML_OUTPUTS):
	$(MKDIR_TARGET)
	@$(DEPS_XML_TOOL) $(PREREQ_FIRST)

# Depend on the XML dependency generation tool
DEPS_XML_TOOL := $(UTILS_DIR)/deps_xml.py
DEPS_XML_TOOL_FILES := $(DEPS_XML_TOOL) $(UTILS_DIR)/lib/deps.py
$(DEPS_XML_OUTPUTS): $(DEPS_XML_TOOL_FILES)

-include $(DEPS_XML_OUTPUTS)

ifeq (2,$(V))
$(info)
$(info Finished setting up .dmk generation for XML files.)
$(info --------------------------------------------------------------------------)
endif

#---------------------------------------------------------------------------------

ifeq (2,$(V))
$(info ==========================================================================)
$(info Setting up .dmk generation for Verilog files.)
$(info --------------------------------------------------------------------------)
endif

DEPS_VERILOG_INPUTS  := $(call find_nontemplate_files,*.v)
DEPS_VERILOG_OUTPUTS := $(foreach F,$(DEPS_VERILOG_INPUTS),$(call deps_makefile,$(F)))

$(foreach F,$(DEPS_VERILOG_INPUTS),$(eval $(call _deps_expand_rule,$(call deps_makefile,$(F)),$(F))))

$(DEPS_VERILOG_OUTPUTS):
	$(MKDIR_TARGET)
	@$(DEPS_VERILOG_TOOL) $(PREREQ_FIRST)

# Depend on the Verilog dependency generation tool
DEPS_VERILOG_TOOL := $(UTILS_DIR)/deps_verilog.py
DEPS_VERILOG_TOOL_FILES := $(DEPS_VERILOG_TOOL) $(UTILS_DIR)/lib/deps.py

$(DEPS_VERILOG_OUTPUTS): $(DEPS_VERILOG_TOOL_FILES)

-include $(DEPS_VERILOG_OUTPUTS)

ifeq (2,$(V))
$(info)
$(info Finished setting up .dmk generation for Verilog files.)
$(info --------------------------------------------------------------------------)
endif

endif
