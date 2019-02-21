yosys -import

# -flatten is used to ensure that the output eblif has only one module.
# Some of symbiflow expects eblifs with only one module.
#
# Since we do not support BRAMs for now they are not inferred.
synth_xilinx -vpr -flatten

# Map Xilinx tech library to 7-series VPR tech library.
read_verilog -lib $::env(symbiflow-arch-defs_SOURCE_DIR)/xc7/techmap/cells_sim.v
techmap -map  $::env(symbiflow-arch-defs_SOURCE_DIR)/xc7/techmap/cells_map.v

# Initialize VPR specific FFs
dffinit -ff FDRE_ZINI Q INIT -ff FDCE_ZINI Q INIT -ff FDPE_ZINI Q INIT -ff FDSE_ZINI Q INIT

# opt_expr -undriven makes sure all nets are driven, if only by the $undef
# net.
opt_expr -undriven
opt_clean

setundef -zero -params
