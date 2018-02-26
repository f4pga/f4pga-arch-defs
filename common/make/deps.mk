# Disable Makefile's inbuilt implicit rules which are useless.
.SUFFIXES:

# Work out our location on the file system
SELF_FILE := $(realpath $(lastword $(MAKEFILE_LIST)))
SELF_DIR := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
INC_MAKEFILE := $(word $(shell echo $(words $(MAKEFILE_LIST))-1 | bc),$(MAKEFILE_LIST))
INC_MAKEDIR := $(dir $(INC_MAKEFILE))

UTILS_DIR := $(realpath $(SELF_DIR)/../../utils)

# Human readable aliases for the 'Automatic Variables' because I can never
# remember what $@ / $< etc mean.
# See [10.5.3 Automatic Variables](https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html)
TARGET = $@
TARGET_DIR = $(@D)
TARGET_FILE = $(@F)
PREREQ_FIRST = $<
PREREQ_FIRST_DIR = $(<D)
PREREQ_FIRST_FILE = $(<F)

PREREQ_NEWER = $?
PREREQ_ALL = $^
TARGET_STEM = $*

ifeq (1,$(V))
ECHO=/bin/echo
else
ECHO=/bin/true
endif

# ------------------------------------------

NEWEST_TOOL := $(UTILS_DIR)/newest.py

# Create a directory to store all the dependency output so it doesn't pollute
# the current directory. To make sure this directory exists, dependency rules
# should have a `| $(DEPDIR)` in their prerequisites.
DEPDIR := .d
$(DEPDIR):
	@mkdir -p $(DEPDIR)

# To allow a target to depend on just the file, the file and it dependencies,
# or only a files dependencies the following targets are automatically created
# for all files.
# - `$(call ONLY,xxx)` - Depend on only the file
# - `$(call DEPS,xxx)` - Depend on the files dependencies
# - `$(call ALL,xxx)`  - Depend on the file and it's dependencies
ONLY  = $(1)
DEPS  = $(subst ./,,$(dir $(1)))$(DEPDIR)/$(notdir $(1)).deps
ALL   = $(call ONLY,$(1)) $(call DEPS,$(1))
DEPMK = $(subst ./,,$(dir $(1)))$(DEPDIR)/$(notdir $(1)).mk

FILES = $(sort \
		$(wildcard $(1)) \
		$(filter $(subst *,%,$(1)),$(MUX_GEN_OUTPUTS)) \
		$(filter $(subst *,%,$(1)),$(NTEMPLATES_OUTPUTS)) \
	)

DEP_FILES = $(foreach F,$(call FILES,*),$(call DEPS,$(F)))

$(DEP_FILES): $(call DEPS,%): $(call ONLY,%) | $(DEPDIR)
	@$(ECHO) "Making .DEPS file for $(TARGET)"
	@$(NEWEST_TOOL) --output $(TARGET) $(PREREQ_ALL)


# ------------------------------------------

clean:
	@for D in $$(find . -mindepth 1 -maxdepth 1 -type d -not \( -prune -name .\* \)); do \
		if [ -e $$D/Makefile ]; then $(MAKE) -C $$D clean; fi; \
	done
	rm -rf $(DEPDIR)

.PHONY: clean

test:
	@for D in $$(find . -mindepth 1 -maxdepth 1 -type d -not \( -prune -name .\* \)); do \
		if [ -e $$D/Makefile ]; then $(MAKE) -C $$D test || exit 1; fi; \
	done


.PHONY: test

all:
	@for D in $$(find . -mindepth 1 -maxdepth 1 -type d -not \( -prune -name .\* -o -name \*test\* \)); do \
		if [ "$$D" != "tests" -a -e "$$D/Makefile" ]; then $(MAKE) -C $$D all || exit 1; fi; \
	done


.PHONY: all
.DEFAULT: all

# ------------------------------------------

# mux_gen.py
ifneq (,$(wildcard Makefile.mux))
MUX_GEN=1
-include Makefile.mux
include $(SELF_DIR)/mux.mk
endif


# ------------------------------------------

NTEMPLATE_PREFIX := ntemplate
NTEMPLATES := $(call FILES,$(NTEMPLATE_PREFIX).*)
ifneq (,$(NTEMPLATES))
include $(SELF_DIR)/N.mk
endif

# ------------------------------------------

DEPS_MAKEFILE_TOOL  := $(UTILS_DIR)/deps_makefile.py
DEPS_MAKEFILE_TOOL_FILES := $(DEPS_MAKEFILE_TOOL) $(UTILS_DIR)/lib/deps.py

DEPS_MAKEFILE_INPUTS = Makefile
DEPS_MAKEFILE_OUTPUTS = $(call DEPMK,Makefile)

$(call DEPMK,Makefile): $(call ONLY,Makefile) | $(DEPDIR)
	@$(ECHO) "Generating deps for '$(PREREQ_FIRST)' into '$(TARGET)' using '$(DEPS_MAKEFILE_TOOL)'"
	@$(DEPS_MAKEFILE_TOOL) $(PREREQ_FIRST)
	@$(NEWEST_TOOL) --output $(TARGET) $(PREREQ_ALL)

# Depend on the MAKEFILE dependency generation tool
$(call DEPMK,Makefile): $(DEPS_MAKEFILE_TOOL_FILES)
$(call DEPMK,Makefile): Makefile

-include $(DEPS_MAKEFILE_OUTPUTS)

# ------------------------------------------
#
# XML dependencies
DEPS_XML_TOOL := $(UTILS_DIR)/deps_xml.py
DEPS_XML_TOOL_FILES := $(DEPS_XML_TOOL) $(UTILS_DIR)/lib/deps.py

DEPS_XML_INPUTS = $(call FILES,*.xml)
DEPS_XML_OUTPUTS = $(foreach F,$(DEPS_XML_INPUTS),$(call DEPMK,$(F)))

$(DEPS_XML_OUTPUTS): $(call DEPMK,%.xml): $(call ONLY,%.xml) | $(DEPDIR)
	@$(ECHO) "Generating deps for '$(PREREQ_FIRST)' into '$(TARGET)' using '$(DEPS_XML_TOOL)'"
	@$(DEPS_XML_TOOL) $(PREREQ_FIRST)
	@$(NEWEST_TOOL) --output $(TARGET) $(PREREQ_ALL)

# Depend on the XML dependency generation tool
$(DEPS_XML_OUTPUTS): $(call DEPMK,%.xml): $(DEPS_XML_TOOL_FILES)
# Depend on this Makefile (and it's deps)
$(DEPS_XML_OUTPUTS): $(call DEPMK,%.xml): $(call ALL,$(INC_MAKEFILE))

-include $(DEPS_XML_OUTPUTS)

# ------------------------------------------

# Verilog dependencies
DEPS_VERILOG_TOOL := $(UTILS_DIR)/deps_verilog.py
DEPS_VERILOG_TOOL_FILES := $(DEPS_VERILOG_TOOL) $(UTILS_DIR)/lib/deps.py

DEPS_VERILOG_INPUTS = $(call FILES,*.v)
DEPS_VERILOG_OUTPUTS = $(call F,$(DEPS_VERILOG_INPUTS),$(call DEPMK,$(F)))

$(DEPS_VERILOG_OUTPUTS): $(call DEPMK,%.mk): $(call ONLY,%.v) | $(DEPDIR)
	@$(ECHO) "Generate deps for '$(PREREQ_FILST)' into '$(TARGET)' using '$(DEPS_VERILOG_TOOL)'"
	@$(DEPS_VERILOG) $(PREREQ_FIRST)
	@$(NEWEST_TOOL) --output $(TARGET) $(PREREQ_ALL)

# Depend on the Verilog dependency generation tool
$(DEPS_VERILOG_OUTPUTS): $(call DEPMK,%.v): $(DEPS_VERILOG_TOOL_FILES)
# Depend on this Makefile (and it's deps)
$(DEPS_VERILOG_OUTPUTS): $(call DEPMK,%.v): $(call ALL,$(INC_MAKEFILE))

-include $(DEPS_VERILOG_OUTPUTS)

# ------------------------------------------

# XML merging
MERGE_XML_DIR := .merged
$(MERGE_XML_DIR):
	@mkdir -p $(MERGE_XML_DIR)

MERGE_XML_INPUTS  = $(call FILES,*.xml)
MERGE_XML_OUTPUTS = $(addprefix $(MERGE_XML_DIR)/,$(MERGE_XML_INPUTS))
MERGE_XML_XSL     := $(realpath $(SELF_DIR)/../xml/xmlsort.xsl)
MERGE_XML_ARGS    := --nomkdir --nonet --xinclude

$(MERGE_XML_OUTPUTS): $(MERGE_XML_DIR)/%.xml: $(call ALL,%.xml) | $(MERGE_XML_DIR)
	xsltproc $(MERGE_XML_ARGS) --output $(TARGET) $(MERGE_XML_XSL) $(PREREQ_FIRST)

# Make sure the directory already exists
$(MERGE_XML_OUTPUTS): $(MERGE_XML_DIR)/%.xml: $(MERGE_XML_XSL)
# Depend on this Makefile (and it's deps)
$(MERGE_XML_OUTPUTS): $(MERGE_XML_DIR)/%.xml: $(call ALL,$(INC_MAKEFILE))

all: $(MERGE_XML_OUTPUTS)

clean: clean_merged

clean_merged:
	rm -rf .merged

# ------------------------------------------
