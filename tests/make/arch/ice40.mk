# Defaults for the iCE40 architecture.

DEVICE_DIR     = $(TOP_DIR)/ice40/devices
DEVICE_TYPE   ?= top-routing-virt
DEVICE        ?= HX1K
PACKAGE				?= vq100
BS_EXTENSION  ?= asc #.bin later
#YOSYS_SCRIPT  ?= synth_ice40 -nodffe -nocarry; ice40_opt -unlut; abc -lut 4;
YOSYS_SCRIPT  ?= synth_ice40 -nocarry; ice40_opt -unlut; abc -lut 4;
#RR_PATCH_TOOL ?= $(TOP_DIR)/ice40/utils/ice40_patch_routing.py
RR_PATCH_TOOL ?= $(TOP_DIR)/ice40/utils/ice40_patch_routing_from_icebox.py
RR_PATCH_CMD  ?= $(RR_PATCH_TOOL) \
	--device=$(DEVICE) \
	--read_rr_graph $(OUT_RRXML_VIRT) \
	--write_rr_graph $(OUT_RRXML_REAL)

HLC_TO_BIT ?= icebox_hlc2asc
HLC_TO_BIT_CMD ?= $(HLC_TO_BIT) $(OUT_HLC) > $(OUT_BITSTREAM) || rm $(OUT_BITSTREAM)
INPUT_PCF_FILE ?= $(SOURCE).pcf
BIT_TO_V_CMD ?= icebox_vlog -n top -p $(INPUT_PCF_FILE) -d $(PACKAGE) $(OUT_BITSTREAM) > $(OUT_BIT_VERILOG) || rm $(OUT_BIT_VERILOG)
EQUIV_CHECK_SCRIPT = rename top gate; read_verilog $(SOURCE).v; rename top gold; hierarchy; proc; miter -equiv -flatten -ignore_gold_x -make_outputs -make_outcmp gold gate miter; sat -verify-no-timeout -timeout 20 -prove trigger 0 -show-inputs -show-outputs miter

ICE_DEVICE:=$(shell echo $(DEVICE) | sed -e's/^..//' -e's/K/k/')

arachne-pnr:
	$(YOSYS) -p "synth_ice40 -nocarry -blif $(OUT_LOCAL)/example.blif" $(SOURCE_V).v
	arachne-pnr -d $(ICE_DEVICE) \
		--post-pack-blif $(OUT_LOCAL)/arachne-pack.blif \
		--post-pack-verilog $(OUT_LOCAL)/arachne-pack.v \
		--post-place-blif $(OUT_LOCAL)/arachne-place.blif \
		--pcf-file $(SOURCE).pcf \
		--package $(PACKAGE) \
		-o $(OUT_LOCAL)/arachne.asc \
		$(OUT_BLIF)
	icebox_asc2hlc $(OUT_LOCAL)/arachne.asc > $(OUT_LOCAL)/arachne.hlc

.PHONY: arachne-pnr
