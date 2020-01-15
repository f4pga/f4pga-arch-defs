add_file_target(FILE mux2to1.v SCANNER_TYPE verilog)
add_file_target(FILE mux2to1.pcf)

add_fpga_target(
  NAME mux2to1-ql-testboard
  BOARD ql-testboard
  SOURCES mux2to1.v
#  INPUT_IO_FILE mux2to1.pcf
  EXPLICIT_ADD_FILE_TARGET
  )
