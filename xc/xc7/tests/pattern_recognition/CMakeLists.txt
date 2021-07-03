add_file_target(FILE pattern.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME pattern_recognition
  BOARDS ${BOARDS}
  SOURCES pattern.v
  )