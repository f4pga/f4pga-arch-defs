add_file_target(FILE uart_loopback.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME uart_loopback_arty
  BOARD arty-uart
  SOURCES uart_loopback.v
  INPUT_IO_FILE ${COMMON}/arty.pcf
  EXPLICIT_ADD_FILE_TARGET
  )
