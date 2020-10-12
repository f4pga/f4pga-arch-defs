add_file_target(FILE arty_clocks.xdc)

function(litex_test litex_dir board device test_name)
  set(LITEX ${CMAKE_CURRENT_BINARY_DIR}/${litex_dir}/gateware)

  get_file_location(GENERATE_LITEX_LOC ${GENERATE_LITEX})
  get_file_location(FIXUP_XDC_LOC ${FIXUP_XDC})
  add_custom_command(
    OUTPUT
      ${LITEX}/arty.v
      ${LITEX}/arty.xdc
      ${LITEX}/arty.pcf
      ${LITEX}/arty.sdc
      ${LITEX}/mem.init
      ${LITEX}/mem_1.init
      ${LITEX}/mem_2.init
    DEPENDS ${PYTHON3} ${GENERATE_LITEX_LOC} ${FIXUP_XDC_LOC}
    COMMAND
      ${CMAKE_COMMAND} -E env PYTHON=${PYTHON3}
      ${PYTHON3} ${GENERATE_LITEX} --with-ram --board ${board} --builddir ${litex_dir} --integrated-rom-size 0x10000 --uart-baudrate 1000000
    COMMAND
      ${PYTHON3} ${FIXUP_XDC} --xdc ${LITEX}/arty.xdc
  )

  add_file_target(FILE ${LITEX}/arty.v     GENERATED ABSOLUTE)
  add_file_target(FILE ${LITEX}/arty.xdc   GENERATED ABSOLUTE)
  add_file_target(FILE ${LITEX}/arty.sdc   GENERATED ABSOLUTE)
  add_file_target(FILE ${LITEX}/arty.pcf   GENERATED ABSOLUTE)
  add_file_target(FILE ${LITEX}/mem.init   GENERATED ABSOLUTE)
  add_file_target(FILE ${LITEX}/mem_1.init GENERATED ABSOLUTE)
  add_file_target(FILE ${LITEX}/mem_2.init GENERATED ABSOLUTE)

  add_fpga_target(
    NAME ${test_name}
    BOARD ${device}
    SOURCES
      ${LITEX}/arty.v
      ${VEXRISCV}
    INPUT_XDC_FILE ${LITEX}/arty.xdc
    EXPLICIT_ADD_FILE_TARGET
  )

  add_vivado_target(
      NAME ${test_name}_vivado
      PARENT_NAME ${test_name}
      XDC arty_clocks.xdc
  )

endfunction()

litex_test(arty_soc a7-35 arty-full minilitex_ddr_arty)
litex_test(arty_a7_soc a7-100 arty100t-full minilitex_ddr_arty_a7)
