include ../../../make/inc/common.mk
include ../../../make/inc/func.mk

VPR   ?= vpr
YOSYS ?= yosys

ifneq (,$(ARCH))
include $(TOP_DIR)/tests/make/arch/$(ARCH).mk
else
$(error "Please set which $$ARCH you are using.")
endif

##########################################################################
# Sanity check for ARCH file
##########################################################################

ifeq (,$(DEVICE_DIR))
$(error "DEVICE_DIR isn't defined in the ARCH file, please check.")
endif
ifeq (,$(DEVICE_TYPE))
$(error "DEVICE_TYPE isn't defined in the ARCH file, please check.")
endif
ifeq (,$(YOSYS_SCRIPT))
$(error "YOSYS_SCRIPT isn't defined in the ARCH file, please check.")
endif
ifeq (,$(RR_PATCH_TOOL))
$(error "RR_PATCH_TOOL isn't defined in the ARCH file, please check.")
endif
ifeq (,$(RR_PATCH_CMD))
$(error "RR_PATCH_CMD isn't defined in the ARCH file, please check.")
endif

always-run:
	@true
.PHONY: always-run

##########################################################################

# Fully qualified device name
FQDN = $(ARCH)-$(DEVICE_TYPE)-$(DEVICE)

# Were we put files for a specific architecture
OUT_DEV_DIR = $(TOP_DIR)/tests/build/$(FQDN)
$(OUT_DEV_DIR):
	mkdir -p $@

clean-dev:
	rm -rf $(OUT_DEV_DIR)

##########################################################################
# Generate a arch.xml for a device.
##########################################################################
DEVICE_MERGED_FILE = $(DEVICE_DIR)/$(DEVICE_TYPE)/arch.merged.xml
$(DEVICE_MERGED_FILE): always-run
	@cd $(TOP_DIR); make $(DEVICE_MERGED_FILE)

OUT_ARCH_XML = $(OUT_DEV_DIR)/arch.xml
$(OUT_ARCH_XML): $(DEVICE_MERGED_FILE) | $(OUT_DEV_DIR)
	@cp -a $(DEVICE_MERGED_FILE) $(OUT_ARCH_XML)
	@echo "Regenerated arch.xml"

arch.xml: $(OUT_ARCH_XML)
	@true
.PHONY: arch.xml

##########################################################################
# Generate a rr_graph for a device.
##########################################################################

# Generate the "default" rr_graph.xml we are going to patch using wire.
OUT_RRXML_VIRT = $(OUT_DEV_DIR)/rr_graph.virt.xml
$(OUT_RRXML_VIRT): $(TOP_DIR)/common/wire.eblif $(OUT_ARCH_XML)
	cd $(OUT_DEV_DIR); \
	$(VPR) \
		$(OUT_ARCH_XML) \
		--device $(DEVICE) \
		$(TOP_DIR)/common/wire.eblif \
		\
		--route_chan_width 10 \
		--min_route_chan_width_hint 1 \
		--write_rr_graph $(OUT_RRXML_VIRT)
	rm $(OUT_DEV_DIR)/wire.{net,place,route}
	mv $(OUT_DEV_DIR)/vpr_stdout.log $(OUT_DEV_DIR)/rr_graph.virt.out
.PRECIOUS: $(OUT_RRXML_VIRT)

# Generate the "real" rr_graph.xml from the default rr_graph.xml file
OUT_RRXML_REAL = $(OUT_DEV_DIR)/rr_graph.real.xml
$(OUT_RRXML_REAL): $(OUT_RRXML_VIRT) $(OUT_ARCH_XML) $(RR_PATCH_TOOL)
	$(RR_PATCH_CMD) 2>&1 | tee $(OUT_DEV_DIR)/rr_graph.real.out; (exit $${PIPESTATUS[0]})
.PRECIOUS: $(OUT_RRXML_REAL)

# Quick shortcuts
rr_graph.virt.xml: $(OUT_RRXML_VIRT)
	@true
.PHONY: rr_graph.virt.xml

rr_graph.real.xml: $(OUT_RRXML_REAL)
	@true
.PHONY: rr_graph.real.xml

rr_graph.xml: rr_graph.real.xml
	@true
.PHONY: rr_graph.xml

##########################################################################
##########################################################################

SOURCE_E = $(basename $(wildcard *.eblif))
SOURCE_V = $(basename $(wildcard *.v))
SOURCE = $(SOURCE_V)$(SOURCE_E)
$(info SOURCE = $(SOURCE))

OUT_LOCAL = $(PWD)/build-$(FQDN)
$(OUT_LOCAL):
	mkdir -p $@

##########################################################################
# Generate BLIF as start of vpr input.
##########################################################################

OUT_EBLIF=$(OUT_LOCAL)/$(SOURCE).eblif

# We have a Verilog file and use a Yosys command to convert it
ifneq ($(SOURCE_V),)
$(OUT_EBLIF): $(SOURCE).v | $(OUT_LOCAL)
	$(YOSYS) -p "$(YOSYS_SCRIPT) opt_clean; write_blif -attr -cname -conn -param $@" $<
endif

# We just have a BLIF file
ifneq ($(SOURCE_E),)
$(OUT_EBLIF): $(SOURCE).eblif | $(OUT_LOCAL)
	cp $< $@
endif

# Always keep the eblif output
.PRECIOUS: $(OUT_LOCAL)/$(SOURCE).eblif

# Quick shortcut
eblif: $(OUT_LOCAL)/$(SOURCE).eblif
	@true
.PHONY: eblif

synth: $(OUT_LOCAL)/$(SOURCE).eblif
	@true
.PHONY: synth

##########################################################################
# VPR Place and route
##########################################################################

# VPR commands
VPR_ARGS ?=
VPR_ROUTE_CHAN_WIDTH ?= 100
VPR_ROUTE_CHAN_MINWIDTH_HINT ?= $(VPR_ROUTE_CHAN_WIDTH)
VPR_CMD = \
	cd $(OUT_LOCAL); \
	$(VPR) \
		$(OUT_ARCH_XML) \
		$(SOURCE).eblif \
		$(VPR_ARGS) \
		--device $(DEVICE) \
		--min_route_chan_width_hint $(VPR_ROUTE_CHAN_MINWIDTH_HINT) \
		--route_chan_width $(VPR_ROUTE_CHAN_WIDTH) \
		--read_rr_graph $(OUT_RRXML_REAL)

# Add IO placement
ifneq ($(wildcard io.place),)
VPR_CMD += --fix_pins $(PWD)/io.place
endif

VPR_ARGS_FILE=$(OUT_LOCAL)/vpr.args
$(VPR_ARGS_FILE): always-run | $(OUT_LOCAL)
	@echo -- "$(VPR_CMD)" > $(VPR_ARGS_FILE).new
	@if diff -q $(VPR_ARGS_FILE).new $(VPR_ARGS_FILE) >/dev/null 2>&1; then \
		rm $(VPR_ARGS_FILE).new; \
	else \
		echo "VPR command changed!"; \
		mv $(VPR_ARGS_FILE).new $(VPR_ARGS_FILE); \
	fi

VPR_DEPS=$(OUT_LOCAL)/.vpr.deps
$(VPR_DEPS): $(OUT_ARCH_XML) $(OUT_RRXML_REAL) $(VPR_ARGS_FILE) | $(OUT_LOCAL)
	@echo "VPR dependencies changed!"
	@touch $@

# Generate packing.
#-------------------------------------------------------------------------
OUT_NET=$(OUT_LOCAL)/$(SOURCE).net
$(OUT_NET): $(OUT_EBLIF) $(VPR_DEPS)
	$(VPR_CMD) --pack --place
	@mv $(OUT_LOCAL)/vpr_stdout.log $(OUT_LOCAL)/pack.log
.PRECIOUS: $(OUT_NET)

# Generate placement.
#-------------------------------------------------------------------------
OUT_PLACE=$(OUT_LOCAL)/$(SOURCE).place
$(OUT_PLACE): $(OUT_NET) $(VPR_DEPS)
	$(VPR_CMD) --place
	@mv $(OUT_LOCAL)/vpr_stdout.log $(OUT_LOCAL)/place.log
.PRECIOUS: $(OUT_PLACE)

# Generate routing.
#-------------------------------------------------------------------------
OUT_ROUTE=$(OUT_LOCAL)/$(SOURCE).route
$(OUT_ROUTE): $(OUT_PLACE) $(VPR_DEPS)
	$(VPR_CMD) --route
	@mv $(OUT_LOCAL)/vpr_stdout.log $(OUT_LOCAL)/route.log
.PRECIOUS: $(OUT_ROUTE)

# Generate analysis.
#-------------------------------------------------------------------------
OUT_ANALYSIS=$(OUT_LOCAL)/analysis.log
$(OUT_ANALYSIS): $(OUT_ROUTE) $(VPR_DEPS)
	$(VPR_CMD) --analysis --gen_post_synthesis_netlist on
	@mv $(OUT_LOCAL)/vpr_stdout.log $(OUT_ANALYSIS)
.PRECIOUS: $(OUT_ANALYSIS)

# Shortcuts
#-------------------------------------------------------------------------
pack:
	make $(OUT_NET)
.PHONY: pack

place:
	make $(OUT_PLACE)
.PHONY: place

route:
	make $(OUT_ROUTE)
.PHONY: route

analysis:
	make $(OUT_ANALYSIS)
.PHONY: analysis

%.disp:
	make VPR_ARGS="--disp on" $*

%.echo:
	make VPR_ARGS="--echo_file on" $*

##########################################################################
##########################################################################

all: clean route
	@true

clean:
	rm -rf $(OUT_LOCAL)

all-clean:
	rm -rf build-*

dist-clean: all-clean clean-dev
	@true

.PHONY: all clean help
