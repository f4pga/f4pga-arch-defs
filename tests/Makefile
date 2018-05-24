include ../make/inc/common.mk
include ../make/inc/func.mk

VPR ?= vpr
YOSYS ?= yosys

ifneq (,$(ARCH))
include Makefile.$(ARCH)
else
$(warning "You probably want to define $$ARCH.")
endif

ifeq (,$(DEVICE_DIR))
$(error "Please define $$DEVICE_DIR to point to your device directory.")
endif
ifeq (,$(DEVICE))
$(error "Please define $$DEVICE to a value in your device file.")
endif
ifeq (,$(YOSYS_SCRIPT))
$(error "Please define $$YOSYS_SCRIPT to the commands needed for synthesis.")
endif

##########################################################################

arch.merged.stamp:
	cd $(TOP_DIR); make $(DEVICE_FILE)
	date > arch.merged.stamp

.PHONY: arch.merged.stamp

DEVICE_DIR_FULL = $(realpath $(DEVICE_DIR)/$(DEVICE_TYPE))

DEVICE_FILE = $(DEVICE_DIR_FULL)/arch.merged.xml
$(DEVICE_FILE): | arch.merged.stamp
	@true

##########################################################################

OUTPUT_DIR ?= build/$(ARCH)/$(DEVICE)

$(OUTPUT_DIR):
	mkdir -p $@

##########################################################################
## Generate BLIF as start of vpr input.
##########################################################################

# Yosys command
$(OUTPUT_DIR)/%.eblif: %.v | $(OUTPUT_DIR)
	$(YOSYS) -p "$(YOSYS_SCRIPT) opt_clean; write_blif -attr -cname -conn -param $@" $<

# Quick shortcut
#%.eblif: $(OUTPUT_DIR)/%.eblif | $(OUTPUT_DIR)
#	@true

.PRECIOUS: $(OUTPUT_DIR)/%.eblif

# We just have a BLIF file
$(OUTPUT_DIR)/%.eblif: %.eblif | $(OUTPUT_DIR)
	cp $< $@

##########################################################################

ROUTE_CHAN_WIDTH ?= 100
MIN_ROUTE_CHAN_WIDTH_HINT ?= $(ROUTE_CHAN_WIDTH)

# VPR commands
VPR_ARGS ?=
VPR_CMD = $(VPR) $(VPR_ARGS)  $(DEVICE_FILE) --device $(DEVICE) --min_route_chan_width_hint $(MIN_ROUTE_CHAN_WIDTH_HINT) --timing_analysis off
VPR_FULL_CMD = cd $(OUTPUT_DIR); $(VPR_CMD)


$(OUTPUT_DIR)/%.rr_graph.xml: $(OUTPUT_DIR)/%.eblif $(DEVICE_FILE)
	$(VPR_FULL_CMD) $(notdir $<) --route_chan_width $(ROUTE_CHAN_WIDTH) --write_rr_graph $(notdir $@)

$(OUTPUT_DIR)/%.pretty.rr_graph.xml: $(OUTPUT_DIR)/%.rr_graph.xml
	cd $(OUTPUT_DIR); xmlsort $(notdir $<) > $(notdir $@)

$(OUTPUT_DIR)/%.patched.rr_graph.xml: $(OUTPUT_DIR)/%.rr_graph.xml $(RR_PATCH_TOOL)
	cd $(OUTPUT_DIR); $(RR_PATCH_CMD) --read_rr_graph $(notdir $<) --write_rr_graph $(notdir $@)

#%.patched: $(OUTPUT_DIR)/%.eblif $(OUTPUT_DIR)/%.patched.rr_graph.pretty.xml
#	cd $(OUTPUT_DIR); gdb --args $(VPR_CMD) $(notdir $<) --route_chan_width $(ROUTE_CHAN_WIDTH) --read_rr_graph $*.rr_graph.pretty.xml

# ------------------------------------------------------------------------
%.patched.disp: $(OUTPUT_DIR)/%.eblif $(OUTPUT_DIR)/%.patched.rr_graph.xml $(DEVICE_FILE)
	$(VPR_FULL_CMD) $(notdir $<) --route_chan_width $(ROUTE_CHAN_WIDTH) --read_rr_graph $*.patched.rr_graph.xml --disp on

%.patched.echo: $(OUTPUT_DIR)/%.eblif $(OUTPUT_DIR)/%.patched.rr_graph.xml $(DEVICE_FILE)
	$(VPR_FULL_CMD) $(notdir $<) --route_chan_width $(ROUTE_CHAN_WIDTH) --read_rr_graph $*.patched.rr_graph.xml --echo_file on --full_stats on

%.patched.verilog: $(OUTPUT_DIR)/%.eblif $(OUTPUT_DIR)/%.patched.rr_graph.xml $(DEVICE_FILE)
	$(VPR_FULL_CMD) $(notdir $<) --route_chan_width $(ROUTE_CHAN_WIDTH) --read_rr_graph $*.patched.rr_graph.xml --gen_post_synthesis_netlist on

%.rr_graph.xml: $(OUTPUT_DIR)/%.rr_graph.xml | $(OUTPUT_DIR)
	@true

%.pretty.rr_graph.xml: $(OUTPUT_DIR)/%.pretty.rr_graph.xml | $(OUTPUT_DIR)
	@true

.PRECIOUS: $(OUTPUT_DIR)/%.rr_graph.xml
.PRECIOUS: $(OUTPUT_DIR)/%.patched.rr_graph.xml
.PRECIOUS: $(OUTPUT_DIR)/%.pretty.rr_graph.pretty.xml
# ------------------------------------------------------------------------

%.disp: $(OUTPUT_DIR)/%.eblif $(DEVICE_FILE)
	$(VPR_FULL_CMD) $(notdir $<) --disp on

%.echo: $(OUTPUT_DIR)/%.eblif $(DEVICE_FILE)
	$(VPR_FULL_CMD) $(notdir $<) --echo_file on --full_stats on

%.verilog: $(OUTPUT_DIR)/%.eblif $(DEVICE_FILE)
	$(VPR_FULL_CMD) $(notdir $<) --gen_post_synthesis_netlist on

%.gdb: $(OUTPUT_DIR)/%.eblif $(DEVICE_FILE)
	cd $(OUTPUT_DIR); gdb --args $(VPR_CMD) $(notdir $<) --echo_file on --gen_post_synthesis_netlist on


ALL_OUTPUT = $(patsubst %.v,$(OUTPUT_DIR)/%.rr_graph.xml,$(wildcard *.v)) $(patsubst %.eblif,$(OUTPUT_DIR)/%.rr_graph.xml,$(wildcard *.eblif))

#	$(call quiet_cmd,make const.echo,Ran $(GREEN)const$(NC)test)
# Re-enable when https://github.com/YosysHQ/yosys/pull/537 landed.
#	$(call quiet_cmd,make vlut.echo,Ran $(PURPLE)Verilog $(GREEN)lut$(NC)test)
# Re-enable when can exclude from testarch.
#	$(call quiet_cmd,make mlut.echo,Ran $(GREEN)mlut$(NC)test)
all:
	@echo -e "Running all tests for $(PURPLE)$(DEVICE)$(NC)in $(YELLOW)$(ARCH)$(NC)"
	$(call quiet_cmd,make wire.echo,Ran $(PURPLE)  eBLIF $(GREEN)wire$(NC)test)
	$(call quiet_cmd,make vwire.echo,Ran $(PURPLE)Verilog $(GREEN)wire$(NC)test)
	@echo
	$(call quiet_cmd,make ff.echo,Ran $(PURPLE)  eBLIF $(GREEN)ff$(NC)test)
	$(call quiet_cmd,make vff.echo,Ran $(PURPLE)Verilog $(GREEN)ff$(NC)test)
	@echo
	$(call quiet_cmd,make lut.echo,Ran $(PURPLE)  eBLIF $(GREEN)lut$(NC)test)
	@echo

.PHONY: all
.DEFAULT_GOAL := all

help:
	@echo ""
	@echo "For each eblif file in this directory you can:"
	@echo " make xx.disp 		- Display the vpr process."
	@echo " make xx.echo 		- Generate useful debugging echo files."
	@echo " make xx.gdb  		- Run vpr process under gdb."
	@echo " make xx.rr_graph.xml	- Generate rr_graph.xml file."
	@echo ""
	@echo "You can set the following"
	@echo " ARCH=<directory containing merged.xml architecture definition>"
	@echo " VPR=<path to vpr>"
	@echo " YOSYS=<path to yosys>"
	@echo ""

clean:
	rm -rf build

.PHONY: all clean help %.gdb %.echo %.disp
