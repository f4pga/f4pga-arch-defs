if (NOT DEFINED ENV{CI} OR NOT $ENV{CI})

add_file_target(FILE spiflash.v SCANNER_TYPE verilog)

add_file_target(FILE picosoc.v SCANNER_TYPE verilog)
add_file_target(FILE picorv32.v SCANNER_TYPE verilog)
add_file_target(FILE simpleuart.v SCANNER_TYPE verilog)
add_file_target(FILE spimemio.v SCANNER_TYPE verilog)

add_file_target(FILE picosoc_noflash.v SCANNER_TYPE verilog)

get_target_property_required(PYTHON3 env PYTHON3)
get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

file(GLOB HEX_FILES *.hex)
foreach(HEX_FILE ${HEX_FILES})
    get_filename_component(HEX_TITLE ${HEX_FILE} NAME_WE)

    add_custom_command(
        OUTPUT ${HEX_TITLE}.v
        COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/hex2progmem.py ${HEX_FILE} --rom-style initial >${HEX_TITLE}.v
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/hex2progmem.py ${PYTHON3} ${PYTHON3_TARGET}
    )
    add_file_target(FILE ${HEX_TITLE}.v GENERATED)

endforeach()

# ============================================================================
# HX8K-B-EVN

add_file_target(FILE hx8kdemo.v SCANNER_TYPE verilog)
add_file_target(FILE hx8kdemo_tb.v SCANNER_TYPE verilog)
add_file_target(FILE hx8k-b-evn.pcf)

add_fpga_target(
  NAME picosoc
  BOARD hx8k-b-evn
  TOP hx8kdemo
  SOURCES
    hx8kdemo.v
    picosoc.v
    picorv32.v
    simpleuart.v
    spimemio.v
  TESTBENCH_SOURCES hx8kdemo_tb.v
  INPUT_IO_FILE hx8k-b-evn.pcf
  EXPLICIT_ADD_FILE_TARGET
)

# ============================================================================
# Basys3 (with ROI)

add_file_target(FILE basys3_demo.v SCANNER_TYPE verilog)
add_file_target(FILE basys3_demo_tb.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME picosoc_basys3
  BOARD basys3
  TOP basys3_demo
  SOURCES
    basys3_demo.v
    picosoc_noflash.v
    picorv32.v
    simpleuart.v
    firmware_noflash_100.v
  SDC_FILE ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/tests/common/basys3.sdc
  INPUT_IO_FILE ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/tests/common/basys3.pcf
  TESTBENCH_SOURCES basys3_demo_tb.v
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
    NAME picosoc_basys3_vivado
    PARENT_NAME picosoc_basys3
    CLOCK_PINS clk
    CLOCK_PERIODS 10.0
    )

add_vivado_pnr_target(
    NAME picosoc_basys3_vivado_pnr
    PARENT_NAME picosoc_basys3
    CLOCK_PINS clk
    CLOCK_PERIODS 10.0
    IOSTANDARD LVCMOS33
    )

# ============================================================================
# Basys3 (full A50T, no ROI)

set(BASYS3_PCF ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/tests/common/basys3.pcf)

get_file_target(TARGET_BASYS3_PCF ${BASYS3_PCF})

set(BASYS3_FREQS 50 100)

foreach(FREQ ${BASYS3_FREQS})

    add_file_target(FILE basys3-full_demo_${FREQ}.v SCANNER_TYPE verilog)
    add_file_target(FILE basys3-full_${FREQ}.sdc)

    get_file_target(TARGET_BASYS3_DEMO_V basys3-full_demo_${FREQ}.v)
    add_dependencies(${TARGET_BASYS3_DEMO_V} ${TARGET_BASYS3_PCF})

    add_fpga_target(
      NAME picosoc_basys3_full_${FREQ}
      BOARD basys3-full
      TOP basys3_demo
      SOURCES
        basys3-full_demo_${FREQ}.v
        picosoc_noflash.v
        picorv32.v
        simpleuart.v
        firmware_noflash_${FREQ}.v
      SDC_FILE basys3-full_${FREQ}.sdc
      INPUT_IO_FILE ${BASYS3_PCF}
      EXPLICIT_ADD_FILE_TARGET
    )

    math(EXPR PERIOD "1000 / ${FREQ}" OUTPUT_FORMAT DECIMAL)

    add_vivado_target(
        NAME picosoc_basys3_full_${FREQ}_vivado
        PARENT_NAME picosoc_basys3_full_${FREQ}
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

    add_file_target(FILE nexys_video_demo_${FREQ}.v SCANNER_TYPE verilog)
    add_file_target(FILE nexys_video_${FREQ}.sdc)

    get_file_target(TARGET_NEXYS_VIDEO_DEMO_V nexys_video_demo_${FREQ}.v)
    add_dependencies(${TARGET_NEXYS_VIDEO_DEMO_V} ${TARGET_NEXYS_VIDEO_XDC} ${TARGET_NEXYS_VIDEO_PCF})

    add_fpga_target(
      NAME picosoc_nexys_video_${FREQ}
      BOARD nexys_video
      TOP nexys_video_demo
      SOURCES
        nexys_video_demo_${FREQ}.v
        picosoc_noflash.v
        picorv32.v
        simpleuart.v
        firmware_noflash_${FREQ}.v
      SDC_FILE nexys_video_${FREQ}.sdc
      INPUT_IO_FILE  ${NEXYS_VIDEO_PCF}
      INPUT_XDC_FILE ${NEXYS_VIDEO_XDC}
      EXPLICIT_ADD_FILE_TARGET
    )

    math(EXPR PERIOD "1000 / ${FREQ}" OUTPUT_FORMAT DECIMAL)

    add_vivado_target(
        NAME picosoc_nexys_video_${FREQ}_vivado
        PARENT_NAME picosoc_nexys_video_${FREQ}
        CLOCK_PINS clk
        CLOCK_PERIODS ${PERIOD}
    )

endforeach()

# ============================================================================

endif (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
