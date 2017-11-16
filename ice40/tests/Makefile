

ARCH ?= ../arch/ice4
ARCH_FILE = $(ARCH)/merged.xml
VPR ?= vpr
YOSYS ?= yosys

%.blif: %.v
	#yosys -p "synth_ice40; write_blif $@" $<
	$(YOSYS) -p "synth_ice40; ice40_opt -unlut; abc -lut 4; opt_clean; write_blif $@" $<

disp: rot.blif $(ARCH_FILE)
	cd $(ARCH); make merged.xml
	#Find the minimum routable channel width of my_circuit on my_arch
	$(VPR) $(ARCH_FILE) ff.blif --disp on

#	
#	#Show interactive graphics
#	vpr my_arch.xml my_circuit.blif --disp on
#	
#	#Implement at a fixed channel width of 100
#	vpr my_arch.xml my_circuit.blif --route_chan_width 100
#	
#	#Perform packing and placement only
#	vpr my_arch.xml my_circuit.blif --pack --place
#	
#	#Generate post-implementation netlist
#	vpr my_arch.xml my_circuit.blif --gen_post_synthesis_netlist on
#	
#	#Write routing-resource graph to a file
#	vpr my_arch.xml my_circuit.blif --write_rr_graph my_rr_graph.xml

clean:
	rm *.blif
