
.SUFFIXES:

YOSYS    ?= yosys
NODE     ?= node
INKSCAPE ?= inkscape

SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

NETLISTSVG = $(shell realpath $(SELF_DIR)/../../third_party/netlistsvg)
NETLISTSVG_SKIN ?= $(NETLISTSVG)/skin.svg
NETLISTSVG_DPI  ?= 300

YOSYSSVG_DPI  ?= 300

NAME := $(shell echo $(notdir $(shell realpath .)) | tr a-z A-Z)

%.json: %.v Makefile $(SELF_DIR)/sim.mk
	$(YOSYS) -p "proc; setattr -mod -set top 1 $(NAME); write_json $@" $<

%.flat.json: %.v Makefile $(SELF_DIR)/sim.mk
	$(YOSYS) -p "flatten; proc; hierarchy -top $(NAME) -purge_lib; write_json $@" $<

%.netlist.svg: %.json $(NETLISTSVG_SKIN)
	$(NODE) $(NETLISTSVG)/bin/netlistsvg $< -o $@ --skin $(NETLISTSVG_SKIN)

%.yosys.svg: %.v
	$(YOSYS) -p "proc; cd $(NAME); show -format svg -prefix $(basename $@)" $<

%.flat.yosys.svg: %.v
	$(YOSYS) -p "proc; flatten; hierarchy -top $(NAME) -purge_lib; cd $(NAME); show -format svg -prefix $(basename $@)" $<

%.png: %.svg
	$(INKSCAPE) --export-png $@ --export-dpi $(NETLISTSVG_DPI) $<

%.yosys.ps: %.v
	echo $(NAME)
	$(YOSYS) -p "proc; hierarchy -top $(NAME) -purge_lib; show -format ps -prefix sim" $<

show: sim.yosys.png
	eog $<

show.flat: sim.flat.yosys.png
	eog $<

view: sim.netlist.png
	eog $<

view.%: %.png
	eog $<

view.flat: sim.flat.netlist.png
	eog $<

clean:
	rm -f sim.json sim.svg sim.png
	rm -f sim.flat.json sim.flat.svg sim.flat.png

.PHONY: view view.flat show
