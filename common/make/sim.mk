
YOSYS    ?= yosys
NODE     ?= node
INKSCAPE ?= inkscape

SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

NETLISTSVG = $(shell realpath $(SELF_DIR)/../../third_party/netlistsvg)
NETLISTSVG_SKIN ?= $(NETLISTSVG)/skin.svg
NETLISTSVG_DPI  ?= 300

sim.json: sim.v
	$(YOSYS) -p "write_json $@" $<

sim.svg: sim.json $(NETLISTSVG_SKIN)
	$(NODE) $(NETLISTSVG)/bin/netlistsvg $< -o $@ --skin $(NETLISTSVG_SKIN)

sim.png: sim.svg
	$(INKSCAPE) --export-png $@ --export-dpi $(NETLISTSVG_DPI) $<

view: sim.png
	eog $<

.PHONY: view
