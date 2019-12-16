add_file_target(FILE counter.v SCANNER_TYPE verilog)
add_fpga_target_boards(
  NAME chain_packing
  BOARDS basys3-full
  INPUT_IO_FILE ${COMMON}/basys3.pcf
  SOURCES counter.v
  EXPLICIT_ADD_FILE_TARGET
  )
