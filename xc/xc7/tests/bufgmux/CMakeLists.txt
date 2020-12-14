add_file_target(FILE bufgmux.v SCANNER_TYPE verilog)

# Arty

add_file_target(FILE arty.xdc)

add_fpga_target(
  NAME bufgmux_arty
  BOARD arty-full
  SOURCES bufgmux.v
  INPUT_XDC_FILE arty.xdc
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
  NAME bufgmux_arty_vivado
  PARENT_NAME bufgmux_arty
)

# Nexys Video

add_file_target(FILE nexys_video.xdc)

add_fpga_target(
  NAME bufgmux_nexys_video
  BOARD nexys_video-mid
  SOURCES bufgmux.v
  INPUT_XDC_FILE nexys_video.xdc
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
  NAME bufgmux_nexys_video_vivado
  PARENT_NAME bufgmux_nexys_video
)
