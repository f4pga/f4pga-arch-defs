
.SUFFIXES:

YOSYS    ?= yosys
NODE     ?= node
INKSCAPE ?= inkscape
NPM      ?= npm

SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

NETLISTSVG = $(shell realpath $(SELF_DIR)/../../third_party/netlistsvg)
NETLISTSVG_STAMP = $(shell realpath $(SELF_DIR)/../../third_party/.netlistsvg.stamp)
NETLISTSVG_SKIN ?= $(NETLISTSVG)/lib/default.svg
NETLISTSVG_DPI  ?= 300

YOSYSSVG_DPI  ?= 300

NAME := $(shell echo $(notdir $(shell realpath .)) | tr a-z A-Z)

$(NETLISTSVG_SKIN): $(NETLISTSVG_STAMP)
	@true

$(NETLISTSVG)/.git:
	git submodule update --init $(NETLISTSVG)

$(NETLISTSVG_STAMP): $(NETLISTSVG)/.git
	cd $(NETLISTSVG) && $(NPM) install
	touch $(NETLISTSVG_STAMP)

%.json: %.v Makefile $(SELF_DIR)/sim.mk
	$(YOSYS) -p "prep -top $(NAME); $(YOSYS_EXTRA); write_json $@" $<

.PRECIOUS: %.json

%.aig.json: %.v Makefile $(SELF_DIR)/sim.mk
	$(YOSYS) -p "prep -top $(NAME) -flatten; aigmap; $(YOSYS_EXTRA); write_json $@" $<

%.flat.json: %.v Makefile $(SELF_DIR)/sim.mk
	$(YOSYS) -p "prep -top $(NAME) -flatten; $(YOSYS_EXTRA); write_json $@" $<

%.svg: %.json $(NETLISTSVG_SKIN) $(NETLISTSVG_STAMP)
	$(NODE) $(NETLISTSVG)/bin/netlistsvg $< -o $@ --skin $(NETLISTSVG_SKIN)

.PRECIOUS: %.svg

%.yosys.svg: %.v
	$(YOSYS) -p "prep -top $(NAME); $(YOSYS_EXTRA); show -format svg -prefix $(basename $@)" $<

%.flat.yosys.svg: %.v
	$(YOSYS) -p "prep -top $(NAME) -flatten; $(YOSYS_EXTRA); show -format svg -prefix $(basename $@)" $<

%.png: %.svg
	$(INKSCAPE) --export-png $@ --export-dpi $(NETLISTSVG_DPI) $<

.PRECIOUS: %.png

%.yosys.ps: %.v
	echo $(NAME)
	$(YOSYS) -p "proc; hierarchy -top $(NAME) -purge_lib; show -format ps -prefix sim" $<

show: sim.yosys.png
	eog $<

show.flat: sim.flat.yosys.png
	eog $<

view: sim.png
	eog $<

view.%: sim.%.png
	eog $<

view.flat: sim.flat.netlist.png
	eog $<

clean:
	rm -f sim.json sim.svg sim.png
	rm -f sim.netlist.json sim.netlist.svg sim.netlist.png
	rm -f sim.netlist.yosys.json sim.netlist.yosys.svg sim.netlist.yosys.png
	rm -f sim.flat.json sim.flat.svg sim.flat.png

.PHONY: view view.flat show
.DEFAULT_GOAL := view
