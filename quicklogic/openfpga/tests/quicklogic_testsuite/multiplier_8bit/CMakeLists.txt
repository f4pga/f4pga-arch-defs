add_file_target(FILE multiplier_8bit.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME multiplier_8bit-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES  multiplier_8bit.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME multiplier_8bit-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES  multiplier_8bit.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder multiplier_8bit-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    multiplier_8bit-ql-openfpga-k4_N8-adder_route)
