
YOSYS ?= yosys
NODE ?= node
INKSCAPE = inkscape

SKIN ?= ../../../third_party/netlistsvg/skin.svg
DPI ?= 300


sim.json: sim.v
	$(YOSYS) -p "write_json $@" $<

sim.svg: sim.json $(SKIN)
	$(NODE) ../../../third_party/netlistsvg/bin/netlistsvg $< -o $@ --skin $(SKIN)

sim.png: sim.svg
	$(INKSCAPE) --export-png $@ --export-dpi $(DPI) $<

view: sim.png
	eog $<

.PHONY: view
