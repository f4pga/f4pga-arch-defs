set(CURR_DIR ${QL_DESIGNS_DIR}/spi_master_top)
add_file_target(FILE ${CURR_DIR}/spi_master_top.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/baud_generator.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/ql_clkgate_x4.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/ql_mux2_x2.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/registers.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/serializer_deserializer.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME spi_master_top_test-umc22-no-adder
  TOP spi_master_top
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/spi_master_top.v ${CURR_DIR}/registers.v ${CURR_DIR}/serializer_deserializer.v ${CURR_DIR}/baud_generator.v ${CURR_DIR}/ql_clkgate_x4.v ${CURR_DIR}/ql_mux2_x2.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME spi_master_top_test-umc22-adder
  TOP spi_master_top
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/spi_master_top.v ${CURR_DIR}/registers.v ${CURR_DIR}/serializer_deserializer.v ${CURR_DIR}/baud_generator.v ${CURR_DIR}/ql_clkgate_x4.v ${CURR_DIR}/ql_mux2_x2.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder spi_master_top_test-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    spi_master_top_test-umc22-adder_bit)
