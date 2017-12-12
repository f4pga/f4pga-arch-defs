
# Generated with mux_gen.py, run the following to regenerate in this directory;
# ../../../../utils/mux_gen.py --outdir . --name-mux F7BMUX --name-output OUT --width 2 --split-inputs --split-selects
# 

all: model.xml pb_type.xml .gitignore Makefile

.PHONY: all

.mux_gen.stamp: ../../../../utils/mux_gen.py
	../../../../utils/mux_gen.py --outdir . --name-mux F7BMUX --name-output OUT --width 2 --split-inputs --split-selects
	touch --reference $< $@
model.xml: .mux_gen.stamp

pb_type.xml: .mux_gen.stamp

.gitignore: .mux_gen.stamp

Makefile: .mux_gen.stamp

