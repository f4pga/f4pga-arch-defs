SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

W = $(shell realpath $(SELF_DIR)/../../utils/w.py)

pb_type.%.xml: pb_type.xml $(W)
	$(W) $@

sim.%.v: sim.v $(W)
	$(W) $@

clean:
	rm -f pb_type.*.xml
	rm -f sim.*.v

all: $(PB_TYPE_XML) $(SIM_V)
