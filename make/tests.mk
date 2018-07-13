TESTS_MK_DIR := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
TEST_DIR     := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
TOP_DIR      := $(realpath $(TESTS_MK_DIR)/..)

include $(TOP_DIR)/make/inc/common.mk
include $(TOP_DIR)/make/inc/func.mk

VPR   ?= vpr
YOSYS ?= yosys

# FIXME: We could probably detect the architecture using the path.
ifeq (,$(ARCH))
$(error "Please set which $$ARCH you are using.")
endif

# set variables based on BOARD
-include $(TOP_DIR)/$(ARCH)/make/tools.mk
-include $(TOP_DIR)/$(ARCH)/make/boards.mk
# Fully qualified device name
FQDN = $(ARCH)-$(DEVICE_TYPE)-$(DEVICE)

TEST_DIR = $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
OUT_LOCAL = $(TEST_DIR)/build-$(FQDN)
$(info OUT_LOCAL = $(OUT_LOCAL))

# include common ARCH specific rules and variables
include $(TOP_DIR)/$(ARCH)/make/tests.mk

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
ifeq (,$(OUT_LOCAL))
$(error "OUT_LOCAL isn't defined in the ARCH file, please check.")
endif

always-run:
	@true
.PHONY: always-run

##########################################################################
$(info OUT_LOCAL = $(OUT_LOCAL))

$(OUT_LOCAL):
	mkdir -p $@

# Were we put files for a specific architecture
OUT_DEV_DIR = $(TOP_DIR)/$(ARCH)/build/$(FQDN)
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
		--device $(DEVICE_FULL) \
		$(TOP_DIR)/common/wire.eblif \
		\
		--route_chan_width 100 \
		--echo_file on \
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

SOURCE_E = $(wildcard *.eblif)
SOURCE_V = $(filter-out %_tb.v,$(wildcard *.v))
SOURCE = $(basename $(SOURCE_V)$(SOURCE_E))
$(info SOURCE = $(SOURCE))

SOURCE_F = $(abspath $(SOURCE_V)$(SOURCE_E))

SOURCES = $(SOURCE_E) $(SOURCE_V)

ifneq ($(words $(SOURCES)),1)
ifeq ($(words $(SOURCES)),0)
$(error "No sources found!")
endif
$(error "Multiple sources found! $(SOURCES)")
endif


##########################################################################
# Generate BLIF as start of vpr input.
##########################################################################

OUT_EBLIF=$(OUT_LOCAL)/$(SOURCE).eblif

# We have a Verilog file and use a Yosys command to convert it
ifneq ($(SOURCE_V),)
$(OUT_EBLIF): $(SOURCE_F) | $(OUT_LOCAL)
	$(YOSYS) -p "$(YOSYS_SCRIPT)" $<

EQUIV_READ = read_verilog $(SOURCE_F)

endif

# We just have a BLIF file
ifneq ($(SOURCE_E),)
$(OUT_EBLIF): $(SOURCE_F) | $(OUT_LOCAL)
	cp $< $@

EQUIV_READ = read_blif -wideports $(SOURCE_F)
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
# Simulation
##########################################################################

TB=$(basename $(wildcard $(SOURCE)_tb.v))
ifneq ($(TB),)

TB_F=$(abspath $(TB).v)

$(OUT_LOCAL)/$(TB).vpp: $(TB_F) $(SOURCE_F) | $(OUT_LOCAL)
	iverilog -v -DVCDFILE=\"$(OUT_LOCAL)/$(TB).vcd\" -DCLK_MHZ=0.001 -o $@ $^ $(TOP_DIR)/env/conda/share/yosys/$(CELLS_SIM)

$(OUT_LOCAL)/$(TB).vcd: $(OUT_LOCAL)/$(TB).vpp | $(OUT_LOCAL)
	vvp -v -N $<

.PRECIOUS: $(OUT_LOCAL)/$(TB).vcd

testbench: $(OUT_LOCAL)/$(TB).vcd
	@true

testbench.view: $(OUT_LOCAL)/$(TB).fixed.vcd
	gtkwave $^

.PHONY: testbench

else

$(warning Test has no test bench!)

endif

#-------------------------------------------------------------------------


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
		$(OUT_EBLIF) \
		$(VPR_ARGS) \
		--device $(DEVICE_FULL) \
		--min_route_chan_width_hint $(VPR_ROUTE_CHAN_MINWIDTH_HINT) \
		--route_chan_width $(VPR_ROUTE_CHAN_WIDTH) \
		--read_rr_graph $(OUT_RRXML_REAL) \
		--clock_modeling_method route \
		--constant_net_method route


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

# Generate IO constraints file.
#-------------------------------------------------------------------------
ifneq ($(INPUT_IO_FILE),)
OUT_IO=$(OUT_LOCAL)/io.place
$(OUT_IO): $(OUT_EBLIF) $(INPUT_IO_FILE) $(OUT_ARCH_XML)
	$(PLACE_TOOL_CMD) --out $(OUT_IO)

VPR_CMD := $(VPR_CMD) --fix_pins $(OUT_IO)
else
OUT_IO=
endif

# Generate packing.
#-------------------------------------------------------------------------
OUT_NET=$(OUT_LOCAL)/$(SOURCE).net
$(OUT_NET): $(OUT_EBLIF) $(OUT_IO) $(VPR_DEPS)
	$(VPR_CMD) --pack --place
	@mv $(OUT_LOCAL)/vpr_stdout.log $(OUT_LOCAL)/pack.log
.PRECIOUS: $(OUT_NET)

# Generate placement.
#-------------------------------------------------------------------------
OUT_PLACE=$(OUT_LOCAL)/$(SOURCE).place
$(OUT_PLACE): $(OUT_NET) $(OUT_IO) $(VPR_DEPS)
	$(VPR_CMD) --place
	@mv $(OUT_LOCAL)/vpr_stdout.log $(OUT_LOCAL)/place.log
.PRECIOUS: $(OUT_PLACE)

# Generate routing.
#-------------------------------------------------------------------------
OUT_ROUTE=$(OUT_LOCAL)/$(SOURCE).route
$(OUT_ROUTE): $(OUT_PLACE) $(OUT_IO) $(VPR_DEPS)
	$(VPR_CMD) --route
	@mv $(OUT_LOCAL)/vpr_stdout.log $(OUT_LOCAL)/route.log
.PRECIOUS: $(OUT_ROUTE)

# Generate analysis.
#-------------------------------------------------------------------------
OUT_ANALYSIS=$(OUT_LOCAL)/analysis.log
$(OUT_ANALYSIS): $(OUT_ROUTE) $(OUT_IO) $(VPR_DEPS)
	$(VPR_CMD) --analysis --gen_post_synthesis_netlist on
	@mv $(OUT_LOCAL)/vpr_stdout.log $(OUT_ANALYSIS)
.PRECIOUS: $(OUT_ANALYSIS)

$(OUT_LOCAL)/top_post_synthesis.v: $(OUT_ANALYSIS)
$(OUT_LOCAL)/top_post_synthesis.blif: $(OUT_ANALYSIS)

# Performing routing generates HLC automatically, nothing to do here
#-------------------------------------------------------------------------
OUT_HLC=$(OUT_LOCAL)/top.hlc
$(OUT_HLC): $(OUT_ROUTE)
.PRECIOUS: $(OUT_HLC)

# Generate bitstream
#-------------------------------------------------------------------------
OUT_BITSTREAM=$(OUT_LOCAL)/$(SOURCE).$(BS_EXTENSION)
$(OUT_BITSTREAM): $(OUT_HLC)
	$(HLC_TO_BIT_CMD)
.PRECIOUS: $(OUT_BITSTREAM)

OUT_BIN=$(OUT_LOCAL)/$(SOURCE).bin
$(OUT_BIN): $(OUT_BITSTREAM)
	icepack $< > $@
.PRECIOUS: $(OUT_BIN)

bin: $(OUT_BIN)
	@true
.PHONY: bin

prog: $(OUT_BIN) $(PROG_TOOL)
	$(PROG_CMD) $<
.PHONY: prog

# Convert bitstream back to Verilog
#-------------------------------------------------------------------------
OUT_BIT_VERILOG=$(OUT_LOCAL)/$(SOURCE)_bit.v
$(OUT_BIT_VERILOG): $(OUT_BITSTREAM)
	$(BIT_TO_V_CMD)
.PRECIOUS: $(OUT_BIT_VERILOG)

OUT_TIME_VERILOG=$(OUT_LOCAL)/$(SOURCE)_time.v
$(OUT_TIME_VERILOG): $(OUT_BITSTREAM)
	$(BIT_TIME_CMD)
.PRECIOUS: $(OUT_TIME_VERILOG)

#-------------------------------------------------------------------------

# Simulate using the testbench with verilog from bit file
ifneq ($(TB),)
$(OUT_LOCAL)/$(TB)_bit.vpp: $(TB_F) $(OUT_BIT_VERILOG) | $(OUT_LOCAL)
	iverilog -v -DVCDFILE=\"$(OUT_LOCAL)/$(TB)_bit.vcd\" -DCLK_MHZ=0.01 -o $@ $^ $(TOP_DIR)/env/conda/share/yosys/$(CELLS_SIM)

$(OUT_LOCAL)/$(TB)_bit.vcd: $(OUT_LOCAL)/$(TB)_bit.vpp | $(OUT_LOCAL)
	vvp -v -N $<

.PRECIOUS: $(OUT_LOCAL)/$(TB)_bit.vcd

testbinch: $(OUT_LOCAL)/$(TB)_bit.vcd
	@true

testbinch.view: $(OUT_LOCAL)/$(TB)_bit.fixed.vcd
	gtkwave $^

.PHONY: testbinch

endif

# Equivalence check
#-------------------------------------------------------------------------

check: $(OUT_BIT_VERILOG)
	$(YOSYS) -p "$(EQUIV_CHECK_SCRIPT)" $(TOP_DIR)/env/conda/share/yosys/$(CELLS_SIM) $<
.PHONY: check

check-orig-blif: route.echo
	cat $(OUT_LOCAL)/atom_netlist.orig.echo.blif | sed '/.end/q' > $(OUT_LOCAL)/atom_netlist.orig.echo.yosys.blif
	$(YOSYS) -p "$(EQUIV_CHECK_SCRIPT)" $(TOP_DIR)/env/conda/share/yosys/$(CELLS_SIM) $(OUT_LOCAL)/atom_netlist.orig.echo.yosys.blif
.PHONY: check-orig-blif

check-cleaned-blif: route.echo
	cat $(OUT_LOCAL)/atom_netlist.cleaned.echo.blif | sed '/.end/q' > $(OUT_LOCAL)/atom_netlist.cleaned.echo.yosys.blif
	$(YOSYS) -p "$(EQUIV_CHECK_SCRIPT)" $(TOP_DIR)/env/conda/share/yosys/$(CELLS_SIM) $(OUT_LOCAL)/atom_netlist.cleaned.echo.yosys.blif
.PHONY: check-cleaned-blif

check-post-blif: $(OUT_LOCAL)/top_post_synthesis.blif
	$(YOSYS) -p "$(EQUIV_CHECK_SCRIPT)" $(TOP_DIR)/env/conda/share/yosys/$(CELLS_SIM) $(OUT_LOCAL)/top_post_synthesis.blif
.PHONY: check-post-blif

check-post-v: $(OUT_LOCAL)/top_post_synthesis.v
	$(YOSYS) -p "$(EQUIV_CHECK_SCRIPT)" $(TOP_DIR)/env/conda/share/yosys/$(CELLS_SIM) $(TOP_DIR)/vpr/primitives.v $(OUT_LOCAL)/top_post_synthesis.v
.PHONY: check-post-v

# Compare the bitstream Verilog to original Verilog
#-------------------------------------------------------------------------

# Fix up names inside VCD files that gtkwave doesn't like
$(OUT_LOCAL)/%.fixed.vcd: $(OUT_LOCAL)/%.vcd
	test -f $< && cat $< | sed -e's/:/_/g' > $@

# Simulate the converted bit file
$(OUT_LOCAL)/autosim.bit.vcd: $(OUT_LOCAL)/$(SOURCE)_bit.v
	$(YOSYS) -p "proc; check; sim -clock clk -n $(CYCLES) -vcd $(OUT_LOCAL)/autosim.bit.vcd -zinit top" $(TOP_DIR)/env/conda/share/yosys/$(CELLS_SIM) $(TOP_DIR)/vpr/primitives.v $(OUT_LOCAL)/$(SOURCE)_bit.v

autosim-bit: $(OUT_LOCAL)/autosim.bit.vcd
	@true
.PHONY: autosim-bit

autosim-bit.view: $(OUT_LOCAL)/autosim.bit.fixed.vcd
	gtkwave $<
.PHONY: autosim-bit.view

# Simulate the post synthesis BLIF file from VPR
$(OUT_LOCAL)/autosim.top_post_synthesis_blif.vcd: $(OUT_LOCAL)/top_post_synthesis.blif
	$(YOSYS) -p "prep -top top; sim -clock clk -n $(CYCLES) -vcd $(OUT_LOCAL)/autosim.top_post_synthesis_blif.vcd -zinit top" $(TOP_DIR)/env/conda/share/yosys/$(CELLS_SIM) $(OUT_LOCAL)/top_post_synthesis.blif

autosim-post-blif: $(OUT_LOCAL)/autosim.top_post_synthesis_blif.vcd
	@true
.PHONY: autosim-post-blif

autosim-post-blif.view: $(OUT_LOCAL)/autosim.top_post_synthesis_blif.fixed.vcd
	gtkwave $<
.PHONY: autosim-post-blif.view

# Simulate the post synthesis Verilog file from VPR
$(OUT_LOCAL)/autosim.top_post_synthesis_v.vcd: $(OUT_LOCAL)/top_post_synthesis.v
	$(YOSYS) -p "prep -top top; sim -clock clk -n $(CYCLES) -vcd $(OUT_LOCAL)/autosim.top_post_synthesis_v.vcd -zinit top" $(TOP_DIR)/env/conda/share/yosys/$(CELLS_SIM) $(TOP_DIR)/vpr/primitives.v $(OUT_LOCAL)/top_post_synthesis.v

autosim-post-v: $(OUT_LOCAL)/autosim.top_post_synthesis_v.vcd
	@true
.PHONY: autosim-post-v

autosim-post-v.view: $(OUT_LOCAL)/autosim.top_post_synthesis_v.fixed.vcd
	gtkwave $<
.PHONY: autosim-post-v.view


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

bit:
	make $(OUT_BITSTREAM)
.PHONY: bit

time:
	make $(OUT_TIME_VERILOG)
.PHONY: time

bit_v:
	make $(OUT_BIT_VERILOG)
.PHONY: bit_v

%.disp:
	make VPR_ARGS="$(VPR_ARGS) --disp on" $*

%.echo:
	make VPR_ARGS="$(VPR_ARGS) --echo_file on" $*

##########################################################################
##########################################################################

SUBDIRS := $(sort $(dir $(foreach SUBDIR,$(wildcard *),$(wildcard $(SUBDIR)/Makefile))))
$(info SUBDIRS = $(SUBDIRS))

$(SUBDIRS):
	cd $@; $(MAKE) $(MAKECMDGOALS) #> $(OUT_LOCAL)/$@.log

.PHONY: $(SUBDIRS)

##########################################################################

check-all: clean check $(SUBDIRS)
	@true

all: clean route
	@true

clean:
	rm -rf $(OUT_LOCAL)

all-clean:
	rm -rf build-*

dist-clean: all-clean clean-dev
	@true

.PHONY: check-all all clean help
