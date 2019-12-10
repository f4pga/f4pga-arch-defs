add_file_target(FILE mem.init)
add_file_target(FILE mem_1.init)
add_file_target(FILE mem_2.init)

get_target_property_required(PYTHON3 env PYTHON3)
get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

add_fpga_target(
  NAME minilitex_arty
  BOARD arty-full
  SOURCES
    minilitex_arty.v
    VexRiscv_Lite.v
  INPUT_IO_FILE arty.pcf
  INPUT_XDC_FILE minilitex.xdc
)

# TODO: Re-enable the diff_fasm test once the following issue is done
# https://github.com/SymbiFlow/symbiflow-arch-defs/issues/1183
add_vivado_target(
    NAME minilitex_arty_vivado
    PARENT_NAME minilitex_arty
    DISABLE_DIFF_TEST
)
