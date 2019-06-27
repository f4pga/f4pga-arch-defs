VIVADO ?= /opt/Xilinx/Vivado/2017.2/bin/vivado

all: top_vivado.bit top_yosys.bit

.PHONY: all clean

basys3_top.edif:
	$(YOSYS) -s synth.ys -l yosys.log

top_yosys.bit: impl_only.tcl basys3_top.edif
	$(VIVADO) -mode batch -source impl_only.tcl -nojournal -log impl_only.log

top_vivado.bit: synth_impl.tcl ../basys3.xdc ../basys3_top.v ../srl_tester.v ../lfsr8_11d.v
	$(VIVADO) -mode batch -source synth_impl.tcl -nojournal -log synth_impl.log

clean:
	rm -f *.bit
	rm -f *.edif
	rm -rf impl_only
	rm -rf synth_impl
	rm -f *.log
	rm -rf .Xil

