add_file_target(FILE mem.init)
add_file_target(FILE mem_1.init)
add_file_target(FILE mem_2.init)

add_fpga_target(
  NAME minilitex_arty
  BOARD arty-full
  SOURCES
    minilitex_arty.v
    VexRiscv_Lite.v
  INPUT_IO_FILE arty.pcf
  INPUT_XDC_FILE minilitex.xdc
)

add_vivado_target(
    NAME minilitex_arty_vivado
    PARENT_NAME minilitex_arty
)
