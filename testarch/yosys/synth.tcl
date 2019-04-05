yosys -import

synth -top top -flatten
abc -lut 4
opt_clean

write_blif -attr -cname -param $::env(OUT_EBLIF)
write_verilog $::env(OUT_SYNTH_V)
write_blif -attr -cname -param \
 -true VCC VCC \
 -false GND GND \
 -undef VCC VCC \
 $::env(OUT_EBLIF)
