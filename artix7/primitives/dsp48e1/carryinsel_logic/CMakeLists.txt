add_subdirectory(carryin_mux)
MAKE_FILE_TARGET(
  FILE carryinsel_logic.sim.v
  SCANNER_TYPE verilog
  )
V2X(
  NAME carryinsel_logic
  SRCS carryinsel_logic.sim.v
  )

