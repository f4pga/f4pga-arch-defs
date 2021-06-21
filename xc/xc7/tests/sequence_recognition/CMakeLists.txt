add_file_target(FILE synchronous_hdlc.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME sequence_recognition
  BOARDS ${BOARDS}
  SOURCES synchronous_hdlc.v
  )