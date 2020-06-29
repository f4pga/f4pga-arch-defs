add_file_target(FILE Murax.v_toplevel_system_ram_ram_symbol0.bin)
add_file_target(FILE Murax.v_toplevel_system_ram_ram_symbol1.bin)
add_file_target(FILE Murax.v_toplevel_system_ram_ram_symbol2.bin)
add_file_target(FILE Murax.v_toplevel_system_ram_ram_symbol3.bin)

add_file_target(FILE hx8k_b_evn_toplevel.v SCANNER_TYPE verilog)
add_file_target(FILE Murax.v SCANNER_TYPE verilog)
add_file_target(FILE basys3_toplevel.v SCANNER_TYPE verilog)
add_file_target(FILE hx8k-b-evn.pcf)
add_file_target(FILE basys3.pcf)
add_file_target(FILE basys3.sdc)

if (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
add_fpga_target(
  NAME murax
  BOARD hx8k-b-evn
  TOP toplevel
  SOURCES
    hx8k_b_evn_toplevel.v
    Murax.v
  INPUT_IO_FILE hx8k-b-evn.pcf
  EXPLICIT_ADD_FILE_TARGET
)

add_fpga_target(
  NAME murax_basys3
  BOARD basys3
  TOP toplevel
  SOURCES
    basys3_toplevel.v
    Murax.v
  INPUT_IO_FILE basys3.pcf
  SDC_FILE basys3.sdc
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
    NAME murax_basys_vivado
    PARENT_NAME murax_basys3
    CLOCK_PINS io_mainClk
    CLOCK_PERIODS 10.0
    )

add_vivado_pnr_target(
    NAME murax_basys_vivado_pnr
    PARENT_NAME murax_basys3
    CLOCK_PINS io_mainClk
    CLOCK_PERIODS 10.0
    IOSTANDARD LVCMOS33
    )

# ============================================================================
# Basys3 (full, no ROI)

add_file_target(FILE basys3-full.pcf)

set(BASYS_FREQS 50 100)

foreach(FREQ ${BASYS_FREQS})

    add_file_target(FILE basys3-full_toplevel_${FREQ}.v SCANNER_TYPE verilog)
    add_file_target(FILE basys3-full_${FREQ}.sdc)

    add_fpga_target(
      NAME murax_basys3_full_${FREQ}
      BOARD basys3-full
      TOP toplevel
      SOURCES
        basys3-full_toplevel_${FREQ}.v
        Murax.v
      INPUT_IO_FILE basys3-full.pcf
      SDC_FILE basys3-full_${FREQ}.sdc
      EXPLICIT_ADD_FILE_TARGET
    )

    math(EXPR PERIOD "1000 / ${FREQ}" OUTPUT_FORMAT DECIMAL)

    add_vivado_target(
        NAME murax_basys3_full_${FREQ}_vivado
        PARENT_NAME murax_basys3_full_${FREQ}
        CLOCK_PINS clk
        CLOCK_PERIODS ${PERIOD}
        )

endforeach()

# ============================================================================
# Nexys Video

set(NEXYS_VIDEO_PCF ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/tests/common/nexys_video.pcf)
set(NEXYS_VIDEO_XDC ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/tests/common/nexys_video.xdc)

get_file_target(TARGET_NEXYS_VIDEO_PCF ${NEXYS_VIDEO_PCF})
get_file_target(TARGET_NEXYS_VIDEO_XDC ${NEXYS_VIDEO_XDC})

set(NEXYS_VIDEO_FREQS 50 100)

foreach(FREQ ${NEXYS_VIDEO_FREQS})

    add_file_target(FILE nexys_video_toplevel_${FREQ}.v SCANNER_TYPE verilog)
    add_file_target(FILE nexys_video_${FREQ}.sdc)

    get_file_target(TARGET_NEXYS_VIDEO_DEMO_V nexys_video_toplevel_${FREQ}.v)
    add_dependencies(${TARGET_NEXYS_VIDEO_DEMO_V} ${TARGET_NEXYS_VIDEO_XDC} ${TARGET_NEXYS_VIDEO_PCF})

    add_fpga_target(
      NAME murax_nexys_video_${FREQ}
      BOARD nexys_video
      TOP top
      SOURCES
        nexys_video_toplevel_${FREQ}.v
        Murax.v
      SDC_FILE nexys_video_${FREQ}.sdc
      INPUT_IO_FILE  ${NEXYS_VIDEO_PCF}
      INPUT_XDC_FILE ${NEXYS_VIDEO_XDC}
      EXPLICIT_ADD_FILE_TARGET
    )

    math(EXPR PERIOD "1000 / ${FREQ}" OUTPUT_FORMAT DECIMAL)

    add_vivado_target(
      NAME murax_nexys_video_${FREQ}_vivado
      PARENT_NAME murax_nexys_video_${FREQ}
      CLOCK_PINS clk
      CLOCK_PERIODS ${PERIOD}
    )

endforeach()

# ============================================================================

endif (NOT DEFINED ENV{CI} OR NOT $ENV{CI})

