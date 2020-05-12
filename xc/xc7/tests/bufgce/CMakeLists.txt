# Arty

add_file_target(FILE bufgce_arty.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME bufgce_arty
  BOARD arty-full
  SOURCES bufgce_arty.v
  INPUT_IO_FILE ${COMMON}/arty_swbut.pcf
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
  NAME bufgce_arty_vivado
  PARENT_NAME bufgce_arty
)

# Nexys Video

add_file_target(FILE bufgce_nexys_video.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME bufgce_nexys_video
  BOARD nexys_video
  SOURCES bufgce_nexys_video.v
  INPUT_IO_FILE ${COMMON}/nexys_video.pcf
  INPUT_XDC_FILE ${COMMON}/nexys_video.xdc
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
  NAME bufgce_nexys_video_vivado
  PARENT_NAME bufgce_nexys_video
)
