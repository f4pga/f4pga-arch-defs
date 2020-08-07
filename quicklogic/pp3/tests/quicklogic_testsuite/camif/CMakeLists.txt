add_file_target(FILE camif_new.v SCANNER_TYPE verilog)
add_file_target(FILE af512x16_512x16.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME camif-ql-chandalar
  BOARD chandalar
  SOURCES camif_new.v af512x16_512x16.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT camif-ql-chandalar
)

add_dependencies(all_ql_tests camif-ql-chandalar_bit)
add_dependencies(all_ql_tests camif-ql-chandalar_jlink)
#add_dependencies(all_quick_tests camif-ql-chandalar_analysis)
#add_dependencies(camif-ql-chandalar_analysis camif-ql-chandalar_bit_v)
