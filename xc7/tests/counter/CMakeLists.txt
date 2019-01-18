#add_fpga_target(
#  NAME counter
#  BOARD basys3
#  INPUT_IO_FILE basys3.pcf
#  SOURCES counter.v
#  )

add_fpga_target(
  NAME counter
  BOARD zybo
  INPUT_IO_FILE zybo.pcf
  SOURCES counter.v
  )
