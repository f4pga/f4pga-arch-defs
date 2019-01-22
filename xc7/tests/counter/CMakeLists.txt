add_fpga_target_boards(
  NAME counter
  BOARDS basys3 zybo
  INPUT_IO_FILE basys3.pcf zybo.pcf
  SOURCES counter.v
 )
