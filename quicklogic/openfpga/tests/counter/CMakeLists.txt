add_file_target(FILE counter.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME counter-ql-openfpga-k4_N8
  BOARD ql-openfpga-k4_N8_board
  SOURCES counter.v
  EXPLICIT_ADD_FILE_TARGET
)

