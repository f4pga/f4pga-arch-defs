add_file_target(FILE spiflash.v SCANNER_TYPE verilog)

add_file_target(FILE picosoc.v SCANNER_TYPE verilog)
add_file_target(FILE picorv32.v SCANNER_TYPE verilog)
add_file_target(FILE simpleuart.v SCANNER_TYPE verilog)
add_file_target(FILE spimemio.v SCANNER_TYPE verilog)

add_file_target(FILE picosoc_noflash.v SCANNER_TYPE verilog)

add_file_target(FILE hx8kdemo.v SCANNER_TYPE verilog)
add_file_target(FILE hx8kdemo_tb.v SCANNER_TYPE verilog)
add_file_target(FILE hx8k-b-evn.pcf)

add_file_target(FILE basys3_demo.v SCANNER_TYPE verilog)
add_file_target(FILE basys3_demo_no_roi.v SCANNER_TYPE verilog)
add_file_target(FILE basys3_demo_tb.v SCANNER_TYPE verilog)
add_file_target(FILE basys3.pcf)
add_file_target(FILE basys3.sdc)

if (NOT DEFINED ENV{CI} OR NOT $ENV{CI})

get_target_property_required(PYTHON3 env PYTHON3)
get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

add_custom_command(
    OUTPUT progmem.v
    COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/hex2progmem.py ${CMAKE_CURRENT_SOURCE_DIR}/firmware_noflash.hex --rom-style initial >progmem.v
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/hex2progmem.py ${PYTHON3} ${PYTHON3_TARGET}
)

add_file_target(FILE progmem.v GENERATED)

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

add_fpga_target(
  NAME picosoc_basys3
  BOARD basys3
  TOP basys3_demo
  SOURCES
    basys3_demo.v
    picosoc_noflash.v
    picorv32.v
    simpleuart.v
    progmem.v
  SDC_FILE ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/tests/common/basys3.sdc
  INPUT_IO_FILE ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/tests/common/basys3.pcf
  TESTBENCH_SOURCES basys3_demo_tb.v
  EXPLICIT_ADD_FILE_TARGET
)

add_fpga_target(
  NAME picosoc_basys3_full
  BOARD basys3-full
  TOP basys3_demo
  SOURCES
    basys3_demo_no_roi.v
    picosoc_noflash.v
    picorv32.v
    simpleuart.v
    progmem.v
  # TODO: re-enable once https://github.com/SymbiFlow/vtr-verilog-to-routing/issues/367 is fixed
  #SDC_FILE basys3.sdc
  INPUT_IO_FILE ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/tests/common/basys3.pcf
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
    NAME picosoc_basys3_vivado
    PARENT_NAME picosoc_basys3
    CLOCK_PINS clk
    CLOCK_PERIODS 20.0
    )

add_vivado_target(
    NAME picosoc_basys3_full_vivado
    PARENT_NAME picosoc_basys3_full
    CLOCK_PINS clk
    CLOCK_PERIODS 20.0
    )

add_vivado_pnr_target(
    NAME picosoc_basys3_vivado_pnr
    PARENT_NAME picosoc_basys3
    CLOCK_PINS clk
    CLOCK_PERIODS 20.0
    IOSTANDARD LVCMOS33
    )

add_file_target(FILE nexys_video_demo.v SCANNER_TYPE verilog)

get_file_target(TARGET_NEXYS_VIDEO_DEMO_V nexys_video_demo.v)
get_file_target(TARGET_NEXYS_VIDEO_PCF ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/tests/common/nexys_video.pcf)
get_file_target(TARGET_NEXYS_VIDEO_XDC ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/tests/common/nexys_video.xdc)
add_dependencies(${TARGET_NEXYS_VIDEO_DEMO_V} ${TARGET_NEXYS_VIDEO_XDC} ${TARGET_NEXYS_VIDEO_PCF})

add_fpga_target(
  NAME picosoc_nexys_video
  BOARD nexys_video
  TOP nexys_video_demo
  SOURCES
    nexys_video_demo.v
    picosoc_noflash.v
    picorv32.v
    simpleuart.v
    progmem.v
  SDC_FILE basys3.sdc
  INPUT_IO_FILE ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/tests/common/nexys_video.pcf
  INPUT_XDC_FILE ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/tests/common/nexys_video.xdc
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
    NAME picosoc_nexys_video_vivado
    PARENT_NAME picosoc_nexys_video
    CLOCK_PINS clk
    CLOCK_PERIODS 10.0
    )

endif (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
