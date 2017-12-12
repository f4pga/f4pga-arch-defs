VPR ?= vpr
YOSYS ?= yosys

ifneq (,$(ARCH))
include Makefile.$(ARCH)
else
$(warning "You probably want to define $$ARCH.")
endif

ifeq (,$(ARCH_DIR))
$(error "Please define $$ARCH_DIR to point to your architecture directory.")
endif
ifeq (,$(DEVICE))
$(error "Please define $$DEVICE to a value in your architecture file.")
endif
ifeq (,$(YOSYS_CMD))
$(error "Please define $$YOSYS_CMD to the commands needed for synthesis.")
endif

ARCH_DIR_FULL = $(shell realpath $(ARCH_DIR)/$(ARCH_TYPE))

ARCH_FILE = $(ARCH_DIR_FULL)/merged.xml
$(ARCH_FILE):
	cd $(ARCH_DIR_FULL); make merged.xml

OUTPUT_DIR ?= build/$(ARCH)/$(DEVICE)

$(OUTPUT_DIR):
	mkdir -p $@

# Yosys command
$(OUTPUT_DIR)/%.blif: %.v $(OUTPUT_DIR)
	$(YOSYS) -p "$(YOSYS_CMD) opt_clean; write_blif $@" $<

$(OUTPUT_DIR)/%.blif: %.blif $(OUTPUT_DIR)
	cp $< $@

# VPR commands
VPR_CMD = $(VPR) $(ARCH_FILE) --device $(DEVICE)

$(OUTPUT_DIR)/%.rr_graph.xml: $(OUTPUT_DIR)/%.blif $(ARCH_FILE)
	$(VPR_CMD) $< --write_rr_graph $@

%.disp: $(OUTPUT_DIR)/%.blif $(ARCH_FILE)
	$(VPR_CMD) $< --disp on

%.echo: $(OUTPUT_DIR)/%.blif $(ARCH_FILE)
	$(VPR_CMD) $< --echo_file on

%.gdb: $(OUTPUT_DIR)/%.blif $(ARCH_FILE)
	gdb --args $(VPR_CMD) $< --echo_file on --disp on

help:
	@echo ""
	@echo "For each blif file in this directory you can:"
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
	rm -f *.echo chan_details.txt seg_details.txt *.place *.route *.net *.rpt *.echo.blif *.rr_graph.xml vpr_stdout.log
	rm -rf build

.PHONY: clean help %.gdb %.echo %.disp $(ARCH_FILE)
