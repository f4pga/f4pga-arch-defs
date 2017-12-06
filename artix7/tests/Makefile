ARCH ?= ../arch/xc7a50t-virt/
ARCH_FILE = $(ARCH)/merged.xml
VPR ?= vpr
YOSYS ?= yosys

ff: ff.blif $(ARCH_FILE)
	cd $(ARCH); make merged.xml
	#Find the minimum routable channel width of my_circuit on my_arch
	$(VPR) $(ARCH_FILE) ff.blif --disp on

lut: lut.blif $(ARCH_FILE)
	cd $(ARCH); make merged.xml
	#Find the minimum routable channel width of my_circuit on my_arch
	$(VPR) $(ARCH_FILE) lut.blif --disp on

clean:
	rm -f *.echo chan_details.txt seg_details.txt
