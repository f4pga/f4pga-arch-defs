add_file_target(FILE mem.init)
add_file_target(FILE mem_1.init)
add_file_target(FILE mem_2.init)
add_file_target(FILE arty.sdc)
add_file_target(FILE arty_clocks.xdc)

add_fpga_target(
  NAME baselitex_arty
  BOARD arty-full
  SOURCES
    baselitex_arty.v
    VexRiscv_Linux.v
  INPUT_IO_FILE arty.pcf
  INPUT_XDC_FILE baselitex_arty.xdc
  SDC_FILE arty.sdc
)

add_vivado_target(
    NAME baselitex_arty_vivado
    PARENT_NAME baselitex_arty
    XDC arty_clocks.xdc
)
