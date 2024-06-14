yosys -import

read_verilog -lib $::env(TECHMAP_PATH)/../primitives/ff/ff.sim.v

synth -top top -flatten
abc -lut 4
opt_clean

dfflegalize -cell \$_DFF_?_ 0
techmap -map  $::env(TECHMAP_PATH)/ff_map.v

write_json $::env(OUT_JSON)
write_verilog $::env(OUT_SYNTH_V)

design -reset
exec $::env(PYTHON3) -m f4pga.aux.utils.yosys_split_inouts -i $::env(OUT_JSON) -o $::env(SYNTH_JSON)
read_json $::env(SYNTH_JSON)
yosys -import
opt_clean
write_blif -attr -cname -param \
 -true VCC VCC \
 -false GND GND \
 -undef VCC VCC \
 $::env(OUT_EBLIF)
