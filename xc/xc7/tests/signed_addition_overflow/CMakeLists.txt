add_file_target(FILE sig_overflow.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME signed_addition_overflow
  BOARDS ${BOARDS}
  SOURCES sig_overflow.v
  )