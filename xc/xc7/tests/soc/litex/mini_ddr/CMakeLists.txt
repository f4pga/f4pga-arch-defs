set(LITEX ${CMAKE_CURRENT_BINARY_DIR}/soc_minsoc_arty/gateware)

add_custom_command(
  OUTPUT top.v mem.init mem_1.init top.xdc
  DEPENDS ${PYTHON3} min_arty.py
  COMMAND
    ${CMAKE_COMMAND} -E env PYTHON=${PYTHON3}
    ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/min_arty.py --no-compile-gateware
  COMMAND
    ${CMAKE_COMMAND} -E copy ${LITEX}/top.v ${LITEX}/mem.init ${LITEX}/mem_1.init ${LITEX}/top.xdc ${CMAKE_CURRENT_BINARY_DIR}/
)

add_file_target(FILE top.v GENERATED)
add_file_target(FILE top.xdc GENERATED)
add_file_target(FILE mem.init GENERATED)
add_file_target(FILE mem_1.init GENERATED)

add_file_target(FILE arty.pcf)
add_file_target(FILE arty_clocks.xdc)
add_file_target(FILE minilitex_ddr_arty.xdc)

set(VEXRISCV ${symbiflow-arch-defs_SOURCE_DIR}/third_party/litex/litex/soc/cores/cpu/vexriscv/verilog/VexRiscv_Lite.v)

add_file_target(FILE ${VEXRISCV} ABSOLUTE)
add_file_target(FILE minilitex_ddr_arty100t.v SCANNER_TYPE verilog)

get_target_property_required(PYTHON3 env PYTHON3)

add_fpga_target(
  NAME minilitex_ddr_arty
  BOARD arty-full
  SOURCES
    top.v
    ${VEXRISCV}
  INPUT_XDC_FILE top.xdc
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
    NAME minilitex_ddr_arty_vivado
    PARENT_NAME minilitex_ddr_arty
    XDC arty_clocks.xdc
)

add_fpga_target(
  NAME minilitex_ddr_arty100t
  BOARD arty100t-full
  SOURCES
    minilitex_ddr_arty100t.v
    ${VEXRISCV}
  INPUT_IO_FILE arty.pcf
  INPUT_XDC_FILE minilitex_ddr_arty.xdc
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
    NAME minilitex_ddr_arty100t_vivado
    PARENT_NAME minilitex_ddr_arty100t
    XDC arty_clocks.xdc
)
