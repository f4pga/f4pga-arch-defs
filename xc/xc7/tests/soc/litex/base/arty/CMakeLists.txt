add_file_target(FILE mem.init)
add_file_target(FILE mem_1.init)
add_file_target(FILE mem_2.init)
add_file_target(FILE baselitex_arty.v)
add_file_target(FILE VexRiscv_Linux.v)

add_file_target(FILE arty.pcf)
add_file_target(FILE baselitex_arty.xdc)
add_file_target(FILE arty.sdc)

add_file_target(FILE arty_clocks.xdc)


get_file_target(TARGET_TOP_V baselitex_arty.v)
get_file_target(TARGET_MEM mem.init)
get_file_target(TARGET_MEM_1 mem_1.init)
get_file_target(TARGET_MEM_2 mem_2.init)
add_dependencies(${TARGET_TOP_V} ${TARGET_MEM} ${TARGET_MEM_1} ${TARGET_MEM_2})


add_fpga_target(
  NAME baselitex_arty
  BOARD arty-full
  SOURCES
    baselitex_arty.v
    VexRiscv_Linux.v
  INPUT_IO_FILE  arty.pcf
  INPUT_XDC_FILE baselitex_arty.xdc
  SDC_FILE       arty.sdc
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
    NAME baselitex_arty_vivado
    PARENT_NAME baselitex_arty
    XDC arty_clocks.xdc
)

