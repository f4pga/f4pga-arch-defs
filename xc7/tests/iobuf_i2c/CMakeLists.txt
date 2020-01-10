add_file_target(FILE i2c_master.v SCANNER_TYPE verilog)
add_file_target(FILE i2c_probe.v SCANNER_TYPE verilog)
add_file_target(FILE i2c_scan.v SCANNER_TYPE verilog)
add_file_target(FILE simpleuart.v SCANNER_TYPE verilog)
add_file_target(FILE iobuf_i2c_basys3.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME iobuf_i2c_basys3
  BOARD basys3-full
  SOURCES iobuf_i2c_basys3.v
  INPUT_IO_FILE ${COMMON}/basys3_pmod.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME iobuf_i2c_basys3_vivado
  PARENT_NAME iobuf_i2c_basys3
  )

add_dependencies(all_xc7_tests
  iobuf_i2c_basys3
)

