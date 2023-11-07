add_file_target(FILE bcd_adder.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME 2_bit_bcd_adder
  BOARDS ${BOARDS}
  SOURCES bcd_adder.v
  )