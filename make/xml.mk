# Include files
include make/inc/common.mk
include make/inc/files.mk

# XML merging
# ------------------------------------------------------------------------
merged_xml_name = $(dir $(F))$(basename $(notdir $(1))).merged.xml
MERGE_XML_INPUTS  = $(call find_nontemplate_files,*.xml)
MERGE_XML_OUTPUTS = $(foreach F,$(MERGE_XML_INPUTS),$(call merged_xml_name,$(F)))
MERGE_XML_XSL     := $(abspath $(TOP_DIR)/common/xml/xmlsort.xsl)
MERGE_XML_ARGS    := --nomkdir --nonet --xinclude

$(foreach F,$(MERGE_XML_INPUTS),$(eval $(call _deps_expand_rule,$(call merged_xml_name,$(F)),$(call depend_on_all,$(F)))))

$(MERGE_XML_OUTPUTS):
	$(call quiet_cmd,xsltproc $(MERGE_XML_ARGS) --output $(TARGET) $(MERGE_XML_XSL) $(PREREQ_FIRST),$(GENERATED_FROM))

# Depend on the XSL script.
$(MERGE_XML_OUTPUTS): $(MERGE_XML_XSL)
# Depend on this Makefile (and it's deps)
#$(MERGE_XML_OUTPUTS): %.merged.xml: $(call ALL,$(INC_MAKEFILE))

merged: $(filter $(FILTER_PATH)%,$(MERGE_XML_OUTPUTS))
	$(call heading,Merged output XML files)
	@echo "$(PREREQ_ALL)" | sed -e's/ /\n/g' -e's@$(PWD)/@@g'

merged-clean:
	@find $(FILTER_PATH) -name '*.merged.xml' -delete -print || true

all: merged
clean: merged-clean
