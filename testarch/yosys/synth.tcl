yosys -import

read_verilog -lib $::env(TECHMAP_PATH)/../primitives/ff/ff.sim.v

synth -top top -flatten
abc -lut 4
opt_clean

dfflegalize -cell \$_DFF_?_ 0
techmap -map  $::env(TECHMAP_PATH)/ff_map.v

write_json $::env(OUT_JSON)
write_verilog $::env(OUT_SYNTH_V)
