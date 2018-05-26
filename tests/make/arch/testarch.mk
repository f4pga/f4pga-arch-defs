# Defaults for the fake testarch architecture.

DEVICE_DIR     = $(TOP_DIR)/testarch/devices
DEVICE_TYPE   ?= clutff-unidir-s4
DEVICE        ?= 2x4
YOSYS_SCRIPT  ?= synth; abc -lut 4;
RR_PATCH_TOOL ?= $(TOP_DIR)/utils/testarch_graph.py
RR_PATCH_CMD  ?= $(RR_PATCH_TOOL) \
	--read_rr_graph $(OUT_RRXML_VIRT) \
	--write_rr_graph $(OUT_RRXML_REAL)
