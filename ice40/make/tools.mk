
ICESTORM ?= $(TOP_DIR)/third_party/icestorm/

ICEPROG_TOOL=$(ICESTORM)/iceprog/iceprog
$(ICEPROG_TOOL):
	cd $(ICESTORM)/iceprog && make iceprog
