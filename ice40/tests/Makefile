

ARCH ?= ../arch/ice4
VPR ?= vpr
YOSYS ?= yosys


%.blif: %.v
	#yosys -p "synth_ice40; write_blif $@" $<
	$(YOSYS) -p "synth_ice40; ice40_opt -unlut; abc -lut 4; opt_clean; write_blif $@" $<

ARCH_FILE = $(ARCH)/merged.xml
$(ARCH_FILE):
	cd $(ARCH); make merged.xml

%.rr_graph.xml: %.blif $(ARCH_FILE)
	$(VPR) $(ARCH_FILE) $< --write_rr_graph $@

%.disp: %.blif
	$(VPR) $(ARCH_FILE) $< --disp on

%.echo: %.blif
	$(VPR) $(ARCH_FILE) $< --echo on

%.gdb: %.blif
	gdb --args $(VPR) $(ARCH_FILE) $< --echo on --disp on

clean:
	rm -f *.echo chan_details.txt seg_details.txt *.place *.route *.net *.rpt *.echo.blif *.rr_graph.xml
