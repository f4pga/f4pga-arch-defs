# Defaults for the fake testarch architecture.

DEVICE_DIR     = $(TOP_DIR)/testarch/devices
DEVICE_TYPE   ?= clutff-unidir-s4
DEVICE        ?= 2x4
DEVICE_FULL   = $(DEVICE)
YOSYS_SCRIPT  ?= synth -top top -flatten; abc -lut 4; opt_clean; write_blif -attr -cname -conn -param $@
RR_PATCH_TOOL ?= $(TOP_DIR)/utils/testarch_graph.py
RR_PATCH_CMD  ?= $(RR_PATCH_TOOL) \
	--read_rr_graph $(OUT_RRXML_VIRT) \
	--write_rr_graph $(OUT_RRXML_REAL)
#RR_PATCH_TOOL ?= /bin/cp
#RR_PATCH_CMD  ?= $(RR_PATCH_TOOL) $(OUT_RRXML_VIRT) $(OUT_RRXML_REAL)
