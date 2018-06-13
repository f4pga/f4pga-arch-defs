# Defaults for the iCE40 architecture.

DEVICE_DIR     = $(TOP_DIR)/ice40/devices
DEVICE_TYPE   ?= top-routing-virt
DEVICE        ?= HX1K
PACKAGE	      ?= vq100
BS_EXTENSION  ?= asc #.bin later
#YOSYS_SCRIPT  ?= synth_ice40 -nodffe -nocarry; ice40_opt -unlut; abc -lut 4;
YOSYS_SCRIPT  ?= synth_ice40 -nocarry; ice40_opt -unlut; abc -lut 4; opt_clean; write_blif -attr -cname -param $@
#YOSYS_SCRIPT  ?= synth_ice40 -top top -vpr -nocarry -blif $@;
#RR_PATCH_TOOL ?= $(TOP_DIR)/ice40/utils/ice40_generate_routing.py
RR_PATCH_TOOL ?= $(TOP_DIR)/ice40/utils/ice40_import_routing_from_icebox.py
RR_PATCH_CMD  ?= $(RR_PATCH_TOOL) \
	--device=$(DEVICE) \
	--read_rr_graph $(OUT_RRXML_VIRT) \
	--write_rr_graph $(OUT_RRXML_REAL)

ifneq ($(ICEBOX),)
HLC_TO_BIT ?= $(ICEBOX)/icebox_hlc2asc.py
BIT_TO_HLC ?= $(ICEBOX)/icebox_asc2hlc.py
BIT_TO_V ?= $(ICEBOX)/icebox_vlog.py
PROG_CMD ?= $(ICEBOX)/../iceprog/iceprog
else
HLC_TO_BIT ?= icebox_hlc2asc
BIT_TO_HLC ?= icebox_asc2hlc
BIT_TO_V ?= icebox_vlog
PROG_CMD ?= iceprog
endif
BIT_TIME ?= icetime

ICE_DEVICE := $(shell echo $(DEVICE) | sed -e's/^..//' -e's/K/k/')
ICE_DEVICE2 := $(shell echo $(DEVICE) | tr A-Z a-z)

HLC_TO_BIT_CMD = $(HLC_TO_BIT) $(OUT_HLC) > $(OUT_BITSTREAM) || rm $(OUT_BITSTREAM)
INPUT_PCF_FILE = $(TEST_DIR)/$(SOURCE).pcf
BIT_TO_V_CMD = $(BIT_TO_V) -D -c -n top -p $(INPUT_PCF_FILE) -d $(PACKAGE) $(OUT_BITSTREAM) > $(OUT_BIT_VERILOG) || rm $(OUT_BIT_VERILOG)

BIT_TIME_CMD = $(BIT_TIME) -v -t -p $(INPUT_PCF_FILE) -d $(ICE_DEVICE2) $(OUT_BITSTREAM) -o $(OUT_TIME_VERILOG)

CELLS_SIM = ice40/cells_sim.v
EQUIV_CHECK_SCRIPT = rename top gate; $(EQUIV_READ); rename top gold; hierarchy; proc; miter -equiv -flatten -ignore_gold_x -make_outputs -make_outcmp gold gate miter; sat -dump_vcd $(OUT_LOCAL)/out.vcd -verify-no-timeout -timeout 20 -seq 1000 -prove trigger 0 -prove-skip 1 -show-inputs -show-outputs miter

OUT_BLIF=$(OUT_LOCAL)/$(SOURCE).blif

ARACHNE_PNR ?= arachne-pnr
arachne-pnr: | $(OUT_LOCAL)
	mkdir -p $(OUT_LOCAL)
	$(YOSYS) -p "synth_ice40 -nocarry -blif $(OUT_BLIF)" $(SOURCE_F)
	$(ARACHNE_PNR) -d $(ICE_DEVICE) \
		--post-pack-blif $(OUT_LOCAL)/arachne-pack.blif \
		--post-pack-verilog $(OUT_LOCAL)/arachne-pack.v \
		--post-place-blif $(OUT_LOCAL)/arachne-place.blif \
		--pcf-file $(INPUT_PCF_FILE) \
		--package $(PACKAGE) \
		-o $(OUT_LOCAL)/arachne.asc \
		$(OUT_BLIF)
	$(BIT_TO_HLC) $(OUT_LOCAL)/arachne.asc > $(OUT_LOCAL)/arachne.hlc
	$(HLC_TO_BIT) $(OUT_LOCAL)/arachne.hlc > $(OUT_LOCAL)/arachne_from_hlc.asc
	$(BIT_TO_V) -c -n top -p $(INPUT_PCF_FILE) -d $(PACKAGE) $(OUT_LOCAL)/arachne.asc > $(OUT_LOCAL)/arachne_bitstream.v
	$(BIT_TO_V) -c -n top -p $(INPUT_PCF_FILE) -d $(PACKAGE) $(OUT_LOCAL)/arachne_from_hlc.asc > $(OUT_LOCAL)/arachne_bitstream_hlc.v
	#$(YOSYS) -p "rename top gate; $(EQUIV_READ); rename top gold; hierarchy; proc; miter -equiv -flatten -ignore_gold_x -make_outputs -make_outcmp gold gate miter; sat -dump_vcd $(OUT_LOCAL)/arachne-out.vcd -verify-no-timeout -timeout 20 -seq 1000 -prove trigger 0 -prove-skip 1 -show-inputs -show-outputs miter" $(OUT_LOCAL)/arachne_bitstream_hlc.v
	$(BIT_TIME) -v -t -p $(INPUT_PCF_FILE) -d $(ICE_DEVICE2) $(OUT_LOCAL)/arachne.asc -o $(OUT_LOCAL)/arache_time.v

arachne-prog: | $(OUT_LOCAL)
	icepack $(OUT_LOCAL)/arachne.asc > $(OUT_LOCAL)/arachne.bin
	$(PROG_CMD) $(OUT_LOCAL)/arachne.bin

sort:
	$(ICEBOX)/icebox_hlcsort.py $(OUT_LOCAL)/arachne.hlc > $(OUT_LOCAL)/arachne.sorted.hlc
	$(BIT_TO_HLC) $(OUT_LOCAL)/$(SOURCE).asc > $(OUT_LOCAL)/$(SOURCE).hlc
	$(ICEBOX)/icebox_hlcsort.py $(OUT_LOCAL)/$(SOURCE).hlc > $(OUT_LOCAL)/$(SOURCE).sorted.hlc


.PHONY: arachne-pnr
