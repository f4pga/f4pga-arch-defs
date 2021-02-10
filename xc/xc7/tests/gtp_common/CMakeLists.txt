add_file_target(FILE gtp_common.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME gtp_common
  BOARD basys3-full
  INPUT_IO_FILE ${COMMON}/basys3_gtp_common.pcf
  SOURCES gtp_common.v
  EXPLICIT_ADD_FILE_TARGET
  )
