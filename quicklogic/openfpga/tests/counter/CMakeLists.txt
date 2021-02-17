add_file_target(FILE counter.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME counter-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES counter.v
  EXPLICIT_ADD_FILE_TARGET
)

add_fpga_target(
  NAME counter-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES counter.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )
