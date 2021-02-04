add_file_target(FILE blob_merge.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME blob_merge-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES blob_merge.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME blob_merge-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES blob_merge.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder blob_merge-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    blob_merge-ql-openfpga-k4_N8-adder_route)
