# Include files
include make/inc/common.mk
include make/inc/files.mk
# Generated files
include make/gen.mk
# Dependency generation
include make/deps.mk
# Conda environment
include make/env.mk
# Rules for converting XXX.sim.v files into images
include make/sim.mk

# ------------------------------------------

# XML merging
merged_xml_name = $(dir $(F))$(basename $(notdir $(1))).merged.xml
MERGE_XML_INPUTS  = $(call find_nontemplate_files,*.xml)
MERGE_XML_OUTPUTS = $(foreach F,$(MERGE_XML_INPUTS),$(call merged_xml_name,$(F)))
MERGE_XML_XSL     := $(abspath $(TOP_DIR)/common/xml/xmlsort.xsl)
MERGE_XML_ARGS    := --nomkdir --nonet --xinclude

$(foreach F,$(MERGE_XML_INPUTS),$(eval $(call _deps_expand_rule,$(call merged_xml_name,$(F)),$(call depend_on_all,$(F)))))

$(MERGE_XML_OUTPUTS):
	xsltproc $(MERGE_XML_ARGS) --output $(TARGET) $(MERGE_XML_XSL) $(PREREQ_FIRST)

# Depend on the XSL script.
$(MERGE_XML_OUTPUTS): $(MERGE_XML_XSL)
# Depend on this Makefile (and it's deps)
#$(MERGE_XML_OUTPUTS): %.merged.xml: $(call ALL,$(INC_MAKEFILE))

merged: $(filter $(CURRENT_DIR)%,$(MERGE_XML_OUTPUTS))
	$(call heading,Merged output XML files)
	@echo "$(PREREQ_ALL)" | sed -e's/ /\n/g' -e's@$(PWD)/@@g'

merged-clean:
	@find $(CURRENT_DIR) -name '*.merged.xml' -delete -print || true

all: merged
clean: merged-clean

# ------------------------------------------

print_vars:
	@$(foreach V,$(DEFINED_VARIABLES),$(info $V=$($V) ($(value $V))))

.PHONY: print_vars

# ------------------------------------------

all:
	@true

.PHONY: all
.DEFAULT_GOAL := all

test:
	$(call heading,Running Python utils tests)
	@$(MAKE) -C utils all $(result)
	#$(call heading,Running Verilog to Routing tests)
	#@$(MAKE) -C tests all $(result)

.PHONY: test

clean:
	@true

dist-clean:
	@true

.PHONY: clean dist-clean
