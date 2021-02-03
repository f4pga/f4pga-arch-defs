set(SOURCES
  top.v
  top.xdc
  mem.init
  mem_1.init
  mem_2.init
)

add_litex_test(
  NAME nexys_video_sata
  LITEX_DIR nexys_video_sata
  LITEX_BOARD nexys_video
  LITEX_SOURCES ${SOURCES}
  EXTERNAL_SOURCES ${VEXRISCV}
  BOARD nexys_video
  GENERATE_SCRIPT ${GENERATE_LITEX}
  FIXUP_SCRIPT ${FIXUP_XDC}
  FLAGS
    --integrated-rom-size 0x10000
    --with-ram
    --with-sata
    --toolchain symbiflow
  USE_XDC
)
