yosys -import

source [file join [file normalize [info script]] .. utils.tcl]
json2eblif $::env(OUT_EBLIF)
