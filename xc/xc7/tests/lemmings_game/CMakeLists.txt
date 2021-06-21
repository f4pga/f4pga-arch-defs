add_file_target(FILE lemmings.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME lemmings_game
  BOARDS ${BOARDS}
  SOURCES lemmings.v
  )