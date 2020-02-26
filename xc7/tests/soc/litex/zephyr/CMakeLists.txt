add_file_target(FILE mem.init)
add_file_target(FILE mem_1.init)
add_file_target(FILE mem_2.init)
add_file_target(FILE mem_3.init)

get_target_property_required(PYTHON3 env PYTHON3)
get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

add_fpga_target(
  NAME litex_zephyr_arty
  BOARD arty-full
  SOURCES
    litex_zephyr_arty.v
    VexRiscv_Full.v
  INPUT_IO_FILE arty.pcf
  INPUT_XDC_FILE litex_zephyr_arty.xdc
)

add_vivado_target(
    NAME litex_zephyr_arty_vivado
    PARENT_NAME litex_zephyr_arty
)
