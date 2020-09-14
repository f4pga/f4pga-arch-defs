add_file_target(FILE idelayctrl.v SCANNER_TYPE verilog)
add_file_target(FILE arty.pcf)

add_fpga_target(
  NAME idelayctrl_arty
  BOARD arty-full
  SOURCES
    idelayctrl.v
  INPUT_IO_FILE arty.pcf
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
    NAME idelayctrl_arty_vivado
    PARENT_NAME idelayctrl_arty
)

get_target_property(OUT_FASM idelayctrl_arty OUT_FASM)
add_custom_target(
  idelayctrl_arty_check
  COMMENT "Check placement constraints"
  COMMAND
    grep "HCLK_IOI3_X1Y130" ${OUT_FASM} | grep "IDELAYCTRL_REFCLK"
    && grep "HCLK_IOI3_X113Y26" ${OUT_FASM} | grep "IDELAYCTRL_REFCLK"
  DEPENDS ${OUT_FASM}
)

add_dependencies(all_xc7_tests idelayctrl_arty_check)
