add_subdirectory(a_adder_mux)
add_subdirectory(acout_mux)
add_subdirectory(ain_mux)
add_subdirectory(amult_mux)
add_subdirectory(amux)
add_subdirectory(dmux)
MAKE_FILE_TARGET(
  FILE dual_ad_preadder.sim.v
  SCANNER_TYPE verilog
  )
V2X(
  NAME dual_ad_preadder
  SRCS dual_ad_preadder.sim.v
  )

