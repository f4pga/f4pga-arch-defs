add_fpga_target(
  NAME uart_loopback_arty
  BOARD arty-uart
  SOURCES uart_loopback.v
  INPUT_IO_FILE arty.pcf
  )
