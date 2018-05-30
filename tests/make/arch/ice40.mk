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
HLC_TO_BIT_CMD ?= icebox_hlc2asc $(OUT_HLC) > $(OUT_BITSTREAM) || rm $(OUT_BITSTREAM)
INPUT_PCF_FILE ?= $(SOURCE).pcf
BIT_TO_V_CMD ?= icebox_vlog -n top -p $(INPUT_PCF_FILE) -d $(PACKAGE) $(OUT_BITSTREAM) > $(OUT_BIT_VERILOG) || rm $(OUT_BIT_VERILOG)
EQUIV_CHECK_SCRIPT = rename top gate; read_verilog $(SOURCE).v; rename top gold; hierarchy; proc; miter -equiv -flatten -ignore_gold_x -make_outputs -make_outcmp gold gate miter; sat -verify-no-timeout -timeout 20 -prove trigger 0 -show-inputs -show-outputs miter
