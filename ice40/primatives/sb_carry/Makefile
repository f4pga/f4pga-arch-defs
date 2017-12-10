
YOSYS ?= yosys
NODE ?= node

sim.json: sim.v
	$(YOSYS) -p "write_json $@" $<

sim.svg: sim.json
	$(NODE) ../../../third_party/netlistsvg/bin/netlistsvg $< -o $@ --skin ../../../third_party/netlistsvg/skin.svg
