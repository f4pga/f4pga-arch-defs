add_file_target(FILE top_120_13.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME top_120_13-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES top_120_13.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME top_120_13-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES top_120_13.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder top_120_13-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    top_120_13-ql-openfpga-k4_N8-adder_route)
