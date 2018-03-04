# Include files
include make/inc/common.mk
include make/inc/files.mk
# Generated files
include make/gen.mk
# Dependency generation
include make/deps.mk

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

# ------------------------------------------

MINICONDA_FILE := Miniconda3-latest-Linux-x86_64.sh
MINICONDA_URL  := https://repo.continuum.io/miniconda/$(MINICONDA_FILE)

CONDA_BIN_DIR := $(abspath ./env/conda/bin/)

CONDA := $(CONDA_BIN_DIR)/conda
CONDA_YOSYS := $(CONDA_BIN_DIR)/yosys
CONDA_VPR   := $(CONDA_BIN_DIR)/vpr

env/$(MINICONDA_FILE):
	mkdir -p env
	wget $(MINICONDA_URL) -O $(TARGET)

$(CONDA): env/$(MINICONDA_FILE)
	sh $(PREREQ_FIRST) -p env/conda -b -f
	$(CONDA) config --system --set always_yes yes

env/conda/envs: $(CONDA)
	$(CONDA) config --system --add envs_dirs $(TARGET)

env/conda/pkgs: $(CONDA)
	$(CONDA) config --system --add pkgs_dirs $(TARGET)

# TODO(mithro): Move to a "conda-symbiflow-packages" rather then leaching off
# the TimVideos packages.
env/conda/.timvideos.channel: $(CONDA) env/conda/envs env/conda/pkgs
	$(CONDA) config --add channels timvideos

CONDA_SETUP := $(CONDA) env/conda/envs env/conda/pkgs env/conda/.timvideos.channel

$(CONDA_YOSYS): $(CONDA_SETUP)
	$(CONDA) install yosys

$(CONDA_VPR): $(CONDA_SETUP)
	$(CONDA) install vtr

env: $(CONDA_YOSYS) $(CONDA_VPR)
	@echo $(PREREQ_ALL)

# If the environment exists, put it into the path.
ifneq (,$(wildcard $(abspath env)))
PATH := $(CONDA)/bin:$(PATH)
endif

# ------------------------------------------

print_vars:
	@$(foreach V,$(DEFINED_VARIABLES),$(info $V=$($V) ($(value $V))))

.PHONY: print_vars

# ------------------------------------------

all: .gitignore $(MERGE_XML_OUTPUTS)
	@echo "----"
	@echo " MERGE_XML_OUTPUT output files"
	@echo "$(MERGE_XML_OUTPUTS)" | sed -e's/ /\n/g'

.PHONY: all
.DEFAULT_GOAL := all

clean:
	@rm -rvf .deps
	@rm -vf $(FILES_GENERATED)
	@find -name '*.d' -delete -print || true
	@find -name '*.dmk' -delete -print || true
	@find -name '*.merged.xml' -delete -print || true
	@rm -vf .gitignore .gitignore.gen

.PHONY: clean
