add_fpga_target(
  NAME oserdes_basys3_x1y0
  BOARD basys3-x1y0
  SOURCES oserdes_basys3_x1y0.v
  INPUT_IO_FILE basys3.pcf
  )

add_vivado_target(
  NAME oserdes_basys3_x1y0_vivado
  PARENT_NAME oserdes_basys3_x1y0
  )
