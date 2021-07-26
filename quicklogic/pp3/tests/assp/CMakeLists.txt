add_file_target(FILE assp.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME assp-ql-jimbob4
  BOARD jimbob4
  SOURCES assp.v
#  INPUT_IO_FILE jimbob4.pcf
  EXPLICIT_ADD_FILE_TARGET
)

add_dependencies(all_quick_tests assp-ql-jimbob4_route)
