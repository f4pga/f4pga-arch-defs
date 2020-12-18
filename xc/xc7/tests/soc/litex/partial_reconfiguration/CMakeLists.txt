set(ARTY_PLATFORM ${CMAKE_CURRENT_SOURCE_DIR}/arty.py)
add_file_target(FILE arty.py)
set(ARTY_OVERLAY_GEN ${CMAKE_CURRENT_SOURCE_DIR}/arty_overlay.py)
add_file_target(FILE arty_overlay.py)

set(OVERLAY_TOP "arty")
set(SOURCES
  ${OVERLAY_TOP}.v
  ${OVERLAY_TOP}.xdc
)

add_litex_test(
  NAME partial_reconfiguration_static
  TOP ${OVERLAY_TOP}
  LITEX_DIR arty_soc
  LITEX_SOURCES ${SOURCES}
  EXTERNAL_SOURCES ${VEXRISCV}
  BOARD arty-partial-reconfiguration-overlay
  GENERATE_SCRIPT ${ARTY_OVERLAY_GEN}
  FIXUP_SCRIPT ${FIXUP_XDC}
  USE_XDC
  FLAGS
    --output_dir arty_soc
    --toolchain symbiflow
    --cpu-type vexriscv
    --sys-clk-freq 100000000
    --prm-csr-base 0x83000000
)

set(ARTY_ROI_GEN ${CMAKE_CURRENT_SOURCE_DIR}/arty_roi.py)
add_file_target(FILE arty_roi.py)

set(ROI_TOP "arty_roi")
set(SOURCES
  ${ROI_TOP}.v
  ${ROI_TOP}.xdc
)

add_litex_test(
  NAME partial_reconfiguration_roi
  TOP ${ROI_TOP}
  LITEX_DIR arty_soc
  LITEX_SOURCES ${SOURCES}
  BOARD arty-partial-reconfiguration-pr
  GENERATE_SCRIPT ${ARTY_ROI_GEN}
  GEN_PARTIAL_BIT
  FIXUP_SCRIPT ${FIXUP_XDC}
  USE_XDC
  FLAGS
    --sys-clk-freq 100000000
    --top ${ROI_TOP}
    --csr-base 0x83000000
    --output_dir arty_soc
    --prm
    --with-led-chaser
    --leds-width 4
)

add_bitstream_target(
  NAME partial_reconfiguration_merged
  USE_FASM
  INCLUDED_TARGETS partial_reconfiguration_static partial_reconfiguration_roi
)
