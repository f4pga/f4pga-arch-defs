add_file_target(FILE wire.v SCANNER_TYPE verilog)
add_file_target(FILE wire.pcf)

add_fpga_target(
  NAME wire-ql-testboard
  BOARD ql-testboard
  SOURCES wire.v
#  INPUT_IO_FILE wire.pcf
  EXPLICIT_ADD_FILE_TARGET
  )
