add_file_target(FILE not.v SCANNER_TYPE verilog)
add_file_target(FILE not.pcf)

add_fpga_target(
  NAME not-ql-testboard
  BOARD ql-testboard
  SOURCES not.v
#  INPUT_IO_FILE not.pcf
  EXPLICIT_ADD_FILE_TARGET
  )
