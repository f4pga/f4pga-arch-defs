add_file_target(FILE multi.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME multiplier
  BOARDS ${BOARDS}
  SOURCES multiplier.v
  )