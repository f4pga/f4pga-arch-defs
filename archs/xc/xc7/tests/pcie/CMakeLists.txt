add_file_target(FILE pcie_basys3.v SCANNER_TYPE verilog)
add_file_target(FILE pcie_arty100t.v SCANNER_TYPE verilog)
add_file_target(FILE pcie_nexys_video.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME pcie_basys3_full
  BOARD basys3-full
  INPUT_IO_FILE ${COMMON}/basys3.pcf
  SOURCES pcie_basys3.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME pcie_arty100t_full
  BOARD arty100t-full
  INPUT_IO_FILE ${COMMON}/arty_swbut.pcf
  SOURCES pcie_arty100t.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME pcie_nexys_video_full
  BOARD nexys_video
  INPUT_IO_FILE ${COMMON}/nexys_video.pcf
  SOURCES pcie_nexys_video.v
  EXPLICIT_ADD_FILE_TARGET
  )
