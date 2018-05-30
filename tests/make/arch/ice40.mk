# Defaults for the iCE40 architecture.

DEVICE_DIR     = $(TOP_DIR)/ice40/devices
DEVICE_TYPE   ?= top-routing-virt
DEVICE        ?= HX1K
#YOSYS_SCRIPT  ?= synth_ice40 -nodffe -nocarry; ice40_opt -unlut; abc -lut 4;
YOSYS_SCRIPT  ?= synth_ice40 -nocarry; ice40_opt -unlut; abc -lut 4;
#RR_PATCH_TOOL ?= $(TOP_DIR)/ice40/utils/ice40_patch_routing.py
RR_PATCH_TOOL ?= $(TOP_DIR)/ice40/utils/ice40_patch_routing_from_icebox.py
RR_PATCH_CMD  ?= $(RR_PATCH_TOOL) \
	--device=$(DEVICE) \
	--read_rr_graph $(OUT_RRXML_VIRT) \
	--write_rr_graph $(OUT_RRXML_REAL)
