yosys -import

synth -top top -flatten
abc -lut 4
opt_clean

write_json $::env(OUT_JSON)
write_verilog $::env(OUT_SYNTH_V)
