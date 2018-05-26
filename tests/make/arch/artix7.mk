# Defaults for the Artix 7 device.

DEVICE_DIR     = $(TOP_DIR)/artix7/devices
DEVICE_TYPE   ?= xc7a50t-roi-virt
DEVICE        ?= xc7a50t-test
YOSYS_SCRIPT  ?= synth_xilinx -vpr;
RR_PATCH_TOOL ?= $(TOP_DIR)/artix7/utils/prjxray-routing-import.py
RR_PATCH_CMD  ?= \
	cp $(OUT_RRXML_VIRT) $(OUT_RRXML_REAL)
#RR_PATCH_CMD  ?= \
#	$(RR_PATCH_TOOL) \
#	--database $(PWD)/../third_party/prjxray-db/artix7/ \
#	--start_x 35 --end_x 38 --start_y 1 --end_y 3
