add_file_target(FILE arty_clocks.xdc)

set(SOURCES
  top.v
  top.xdc
  mem.init
  mem_1.init
  mem_2.init
)

add_litex_test(
  NAME linux_arty
  LITEX_DIR arty_linux_soc
  LITEX_BOARD a7-35
  LITEX_SOURCES ${SOURCES}
  EXTERNAL_SOURCES ${VEXRISCV_LINUX}
  BOARD arty-full
  GENERATE_SCRIPT ${GENERATE_LINUX_LITEX}
  FIXUP_SCRIPT ${FIXUP_XDC}
  USE_XDC
  VIVADO_XDC arty_clocks.xdc
)

add_litex_test(
  NAME linux_arty_100t
  LITEX_DIR arty_a7_soc
  LITEX_BOARD a7-100
  LITEX_SOURCES ${SOURCES}
  EXTERNAL_SOURCES ${VEXRISCV_LINUX}
  BOARD arty100t-full
  GENERATE_SCRIPT ${GENERATE_LINUX_LITEX}
  FIXUP_SCRIPT ${FIXUP_XDC}
  USE_XDC
  VIVADO_XDC arty_clocks.xdc
  # FIXME: Certain BRAMs do have issues with the bittools regarding the
  # INIT configuration bits: https://github.com/SymbiFlow/prjxray/pull/1335
  DISABLE_DIFF_TEST
)
