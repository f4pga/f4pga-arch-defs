
# Generated with mux_gen.py, run the following to regenerate in this directory;
# ../../../../utils/mux_gen.py --outdir . '--name-mux' 'CARRY4_WMUX' '--name-output' 'OUT' '--width' '2' '--split-inputs' '--split-selects' '--subckt' 'MUXCY' '--num_pb' '4' '--comment' 'CARRY4_DMUX, CARRY4_CMUX, CARRY4_BMUX, CARRY4_AMUX == CARRY4_WMUX'
# CARRY4_DMUX, CARRY4_CMUX, CARRY4_BMUX, CARRY4_AMUX == CARRY4_WMUX

all: model.xml pb_type.xml .gitignore Makefile

clean:
	rm -f .mux_gen.stamp model.xml pb_type.xml

.mux_gen.stamp: ../../../../utils/mux_gen.py
	../../../../utils/mux_gen.py --outdir . '--name-mux' 'CARRY4_WMUX' '--name-output' 'OUT' '--width' '2' '--split-inputs' '--split-selects' '--subckt' 'MUXCY' '--num_pb' '4' '--comment' 'CARRY4_DMUX, CARRY4_CMUX, CARRY4_BMUX, CARRY4_AMUX == CARRY4_WMUX'
	touch --reference $< $@

.PHONY: all clean

model.xml: .mux_gen.stamp

pb_type.xml: .mux_gen.stamp

.gitignore: .mux_gen.stamp

Makefile: .mux_gen.stamp

