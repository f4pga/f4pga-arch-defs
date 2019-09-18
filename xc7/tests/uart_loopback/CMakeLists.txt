add_fpga_target_boards(
  NAME uart_loopback
  BOARDS arty-uart
  SOURCES uart_loopback.v
  IMPLICIT_INPUT_IO_FILES
  )
