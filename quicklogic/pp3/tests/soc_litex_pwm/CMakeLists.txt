add_file_target(FILE AL4S3B_FPGA_Top.v SCANNER_TYPE verilog)
add_file_target(FILE litex_core.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME soc_litex_pwm-ql-chandalar
  BOARD chandalar
  SOURCES litex_core.v AL4S3B_FPGA_Top.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
)

add_jlink_output(
  PARENT soc_litex_pwm-ql-chandalar
)

add_openocd_output(
  PARENT soc_litex_pwm-ql-chandalar
)

add_dependencies(all_ql_tests soc_litex_pwm-ql-chandalar_bit)
add_dependencies(all_ql_tests soc_litex_pwm-ql-chandalar_jlink)
add_dependencies(all_ql_tests soc_litex_pwm-ql-chandalar_openocd)

add_file_target(FILE quickfeather.pcf)

add_fpga_target(
  NAME soc_litex_pwm-ql-quickfeather
  BOARD quickfeather
  SOURCES litex_core.v AL4S3B_FPGA_Top.v
  INPUT_IO_FILE quickfeather.pcf
  EXPLICIT_ADD_FILE_TARGET
)

add_jlink_output(
  PARENT soc_litex_pwm-ql-quickfeather
)

add_openocd_output(
  PARENT soc_litex_pwm-ql-quickfeather
)

add_dependencies(all_ql_tests soc_litex_pwm-ql-quickfeather_bit)
add_dependencies(all_ql_tests soc_litex_pwm-ql-quickfeather_jlink)
add_dependencies(all_ql_tests soc_litex_pwm-ql-quickfeather_openocd)

