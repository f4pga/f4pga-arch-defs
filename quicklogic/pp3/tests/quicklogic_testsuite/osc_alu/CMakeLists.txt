add_file_target(FILE oc8051_defines.v SCANNER TYPE verilog)
add_file_target(FILE oc8051_divide.v SCANNER TYPE verilog)
add_file_target(FILE oc8051_multiply.v SCANNER TYPE verilog)
add_file_target(FILE oc8051_timescale.v SCANNER TYPE verilog)
add_file_target(FILE oc8051_alu.v SCANNER TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME osc_alu-ql-chandalar
  BOARD chandalar
  SOURCES oc8051_alu.v oc8051_defines.v oc8051_divide.v oc8051_multiply.v oc8051_timescale.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT osc_alu-ql-chandalar
)

add_dependencies(all_ql_tests osc_alu-ql-chandalar_bit)
add_dependencies(all_ql_tests osc_alu-ql-chandalar_jlink)
add_dependencies(all_quick_tests osc_alu-ql-chandalar_analysis)
add_dependencies(osc_alu-ql-chandalar_analysis osc_alu-ql-chandalar_bit_v)

