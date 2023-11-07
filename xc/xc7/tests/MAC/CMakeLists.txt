add_file_target(FILE multiply_and_accumulate.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME MAC
  BOARDS ${BOARDS}
  SOURCES multiply_and_accumulate.v
  )