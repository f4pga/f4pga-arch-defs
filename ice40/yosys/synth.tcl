yosys -import

synth_ice40 -nocarry -noabc
# TODO: revert when libblifparse fix propagates to vpr
abc -lut 4
ice40_opt
ice40_unlut
simplemap
opt
abc -lut 4
opt_clean
