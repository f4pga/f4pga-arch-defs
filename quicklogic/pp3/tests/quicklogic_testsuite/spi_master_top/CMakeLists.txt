add_file_target(FILE baud_generator.v SCANNER TYPE verilog)
add_file_target(FILE ql_clkgate_x4.v SCANNER TYPE verilog)
add_file_target(FILE ql_mux2_x2.v SCANNER TYPE verilog)
add_file_target(FILE registers.v SCANNER TYPE verilog)
add_file_target(FILE serializer_deserializer.v SCANNER TYPE verilog)
add_file_target(FILE spi_master_top.v SCANNER TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME spi_master_top-ql-chandalar
  BOARD chandalar
  SOURCES spi_master_top.v baud_generator.v ql_clkgate_x4.v ql_mux2_x2.v registers.v serializer_deserializer.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT spi_master_top-ql-chandalar
)

add_openocd_output(
  PARENT spi_master_top-ql-chandalar
)

add_dependencies(all_ql_tests spi_master_top-ql-chandalar_bit)
add_dependencies(all_ql_tests spi_master_top-ql-chandalar_jlink)
add_dependencies(all_ql_tests spi_master_top-ql-chandalar_openocd)
