add_fpga_target(
  NAME buttons_arty
  BOARD arty-swbut
  SOURCES buttons_arty.v
  INPUT_IO_FILE arty.pcf
  )

 add_fpga_target(
  NAME buttons_basys3
  BOARD basys3-x1y0
  SOURCES buttons_basys3.v
  INPUT_IO_FILE basys3.pcf
  )

add_vivado_target(
  NAME buttons_basys3_vivado
  PARENT_NAME buttons_basys3
  )

add_fpga_target(
  NAME buttons_zybo
  BOARD zybo
  SOURCES buttons_zybo.v
  INPUT_IO_FILE zybo.pcf
  )

add_fpga_target(
  NAME buttons_basys3_x1y0
  BOARD basys3-x1y0
  SOURCES buttons_basys3_x1y0.v
  INPUT_IO_FILE basys3_x1y0.pcf
  )

add_vivado_target(
  NAME buttons_basys3_x1y0_vivado
  PARENT_NAME buttons_basys3_x1y0
  )
