yosys -import

synth -top top -flatten
abc -lut 4
opt_clean
