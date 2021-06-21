add_file_target(FILE serial_parity_check.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME serial_parity_checker
  BOARDS ${BOARDS}
  SOURCES serial_parity_check.v
  )