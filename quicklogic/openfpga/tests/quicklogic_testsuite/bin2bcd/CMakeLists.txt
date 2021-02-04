add_file_target(FILE bin2bcd.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME bin2bcd-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES bin2bcd.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME bin2bcd-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES bin2bcd.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder bin2bcd-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    bin2bcd-ql-openfpga-k4_N8-adder_route)

