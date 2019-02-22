yosys -import

synth_ice40 -nocarry
ice40_opt
ice40_unlut
simplemap
opt
abc -lut 4
opt_clean
