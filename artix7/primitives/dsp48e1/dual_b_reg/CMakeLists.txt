add_subdirectory(b1reg_mux)
add_subdirectory(b2reg_mux)
add_subdirectory(bc_mux)
add_subdirectory(bin_mux)
add_subdirectory(bmult_mux)
MAKE_FILE_TARGET(
  FILE dual_b_reg.sim.v
  SCANNER_TYPE verilog
  )
V2X(
  NAME dual_b_reg
  SRCS dual_b_reg.sim.v
  )

