
DEVICE ?= HX8K
ARCH ?= ../arch/ice4
VPR ?= vpr
YOSYS ?= yosys


VPR_CMD = $(VPR) $(ARCH_FILE) --device $(DEVICE)

%.blif: %.v
	#yosys -p "synth_ice40; write_blif $@" $<
	$(YOSYS) -p "synth_ice40; ice40_opt -unlut; abc -lut 4; opt_clean; write_blif $@" $<

ARCH_FILE = $(ARCH)/merged.xml
$(ARCH_FILE):
	cd $(ARCH); make merged.xml

%.rr_graph.xml: %.blif $(ARCH_FILE)
	$(VPR_CMD) $< --write_rr_graph $@

%.disp: %.blif $(ARCH_FILE)
	$(VPR_CMD) $< --disp on

%.echo: %.blif $(ARCH_FILE)
	$(VPR_CMD) $< --echo_file on

%.gdb: %.blif $(ARCH_FILE)
	gdb --args $(VPR_CMD) $< --echo_file on --disp on

help:
	@echo ""
	@echo "For each blif file in this directory you can:"
	@echo " make xx.disp 		- Display the vpr process."
	@echo " make xx.echo 		- Generate useful debugging echo files."
	@echo " make xx.gdb  		- Run vpr process under gdb."
	@echo " make xx.rr_graph.xml	- Generate rr_graph.xml file."
	@echo ""
	@echo "You can set the following"
	@echo " ARCH=<directory containing merged.xml architecture definition>"
	@echo " VPR=<path to vpr>"
	@echo " YOSYS=<path to yosys>"
	@echo ""

clean:
	rm -f *.echo chan_details.txt seg_details.txt *.place *.route *.net *.rpt *.echo.blif *.rr_graph.xml

.PHONY: clean help %.gdb %.echo %.disp $(ARCH_FILE)
