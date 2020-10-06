add_file_target(FILE eqspiflash.v SCANNER_TYPE verilog)
add_file_target(FILE flash_config.v SCANNER_TYPE verilog)
add_file_target(FILE lleqspi.v SCANNER_TYPE verilog)
add_file_target(FILE llqspi.v SCANNER_TYPE verilog)
add_file_target(FILE wbqspiflash.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME wbqspiflash-ql-chandalar
  BOARD chandalar
  SOURCES eqspiflash.v flash_config.v lleqspi.v llqspi.v wbqspiflash.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT wbqspiflash-ql-chandalar
)

add_openocd_output(
  PARENT wbqspiflash-ql-chandalar
)

add_dependencies(all_ql_tests wbqspiflash-ql-chandalar_bit)
add_dependencies(all_ql_tests wbqspiflash-ql-chandalar_jlink)
add_dependencies(all_ql_tests wbqspiflash-ql-chandalar_openocd)

add_file_target(FILE quickfeather.pcf)

add_fpga_target(
  NAME wbqspiflash-ql-quickfeather
  BOARD quickfeather
  SOURCES eqspiflash.v flash_config.v lleqspi.v llqspi.v wbqspiflash.v
  INPUT_IO_FILE quickfeather.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT wbqspiflash-ql-quickfeather
)

add_openocd_output(
  PARENT wbqspiflash-ql-quickfeather
)

add_dependencies(all_ql_tests wbqspiflash-ql-quickfeather_bit)
add_dependencies(all_ql_tests wbqspiflash-ql-quickfeather_jlink)
add_dependencies(all_ql_tests wbqspiflash-ql-quickfeather_openocd)

