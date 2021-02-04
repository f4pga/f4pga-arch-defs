add_file_target(FILE adder_8.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME adder_8-ql-openfpga-k4_N4
  BOARD ql-openfpga-k4_N4_board
  SOURCES adder_8.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME adder_8-ql-openfpga-k4_N8
  BOARD ql-openfpga-k4_N8_board
  SOURCES adder_8.v
  EXPLICIT_ADD_FILE_TARGET
)

