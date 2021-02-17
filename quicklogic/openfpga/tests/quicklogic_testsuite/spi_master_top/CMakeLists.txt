add_file_target(FILE baud_generator.v SCANNER_TYPE verilog)
add_file_target(FILE ql_clkgate_x4.v SCANNER_TYPE verilog)
add_file_target(FILE ql_mux2_x2.v SCANNER_TYPE verilog)
add_file_target(FILE registers.v SCANNER_TYPE verilog)
add_file_target(FILE serializer_deserializer.v SCANNER_TYPE verilog)
add_file_target(FILE spi_master_top.v SCANNER_TYPE verilog)


add_fpga_target(
  NAME spi_master_top-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES baud_generator.v  ql_mux2_x2.v  serializer_deserializer.v ql_clkgate_x4.v   registers.v   spi_master_top.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME spi_master_top-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES  baud_generator.v  ql_mux2_x2.v  serializer_deserializer.v ql_clkgate_x4.v   registers.v   spi_master_top.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder spi_master_top-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    spi_master_top-ql-openfpga-k4_N8-adder_route)
