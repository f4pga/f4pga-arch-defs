add_fpga_target_boards(
  NAME uart_loopback
  BOARDS arty-uart
  SOURCES uart_loopback.v
  INPUT_IO_FILE arty.pcf
  )
