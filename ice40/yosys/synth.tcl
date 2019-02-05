yosys -import

synth_ice40 -nocarry
ice40_opt -unlut
abc -lut 4
opt_clean
