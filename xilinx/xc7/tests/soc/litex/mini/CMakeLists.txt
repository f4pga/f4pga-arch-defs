add_file_target(FILE arty_clocks.xdc)

set(SOURCES
  top.v
  top.xdc
  top.sdc
  mem.init
  mem_1.init
  mem_2.init
)

add_litex_test(
  NAME minilitex_arty
  LITEX_DIR arty_soc
  LITEX_BOARD a7-35
  LITEX_SOURCES ${SOURCES}
  EXTERNAL_SOURCES ${VEXRISCV}
  BOARD arty-full
  GENERATE_SCRIPT ${GENERATE_LITEX}
  FIXUP_SCRIPT ${FIXUP_XDC}
  USE_XDC
  FLAGS
    --integrated-rom-size 0x10000
    --uart-baudrate 1000000
    --toolchain symbiflow
  VIVADO_XDC arty_clocks.xdc
)

add_litex_test(
  NAME minilitex_arty_a7
  LITEX_DIR arty_a7_soc
  LITEX_BOARD a7-100
  LITEX_SOURCES ${SOURCES}
  EXTERNAL_SOURCES ${VEXRISCV}
  BOARD arty100t-full
  GENERATE_SCRIPT ${GENERATE_LITEX}
  FIXUP_SCRIPT ${FIXUP_XDC}
  USE_XDC
  FLAGS
    --integrated-rom-size 0x10000
    --uart-baudrate 1000000
    --toolchain symbiflow
  VIVADO_XDC arty_clocks.xdc
)
