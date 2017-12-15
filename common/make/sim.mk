
YOSYS    ?= yosys
NODE     ?= node
INKSCAPE ?= inkscape

SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

NETLISTSVG = $(shell realpath $(SELF_DIR)/../../third_party/netlistsvg)
NETLISTSVG_SKIN ?= $(NETLISTSVG)/skin.svg
NETLISTSVG_DPI  ?= 300

%.json: %.v Makefile
	$(YOSYS) -p "proc; write_json $@" $<

%.flat.json: %.v Makefile
	$(YOSYS) -p "flatten; proc; write_json $@" $<

%.svg: %.json $(NETLISTSVG_SKIN)
	$(NODE) $(NETLISTSVG)/bin/netlistsvg $< -o $@ --skin $(NETLISTSVG_SKIN)

%.png: %.svg
	$(INKSCAPE) --export-png $@ --export-dpi $(NETLISTSVG_DPI) $<

view: sim.png
	eog $<

view.flat: sim.flat.png
	eog $<

clean:
	rm -f sim.json sim.svg sim.png
	rm -f sim.flat.json sim.flat.svg sim.flat.png

.PHONY: view view.flat
