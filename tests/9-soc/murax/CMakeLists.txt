add_file_target(FILE Murax.v_toplevel_system_ram_ram_symbol0.bin)
add_file_target(FILE Murax.v_toplevel_system_ram_ram_symbol1.bin)
add_file_target(FILE Murax.v_toplevel_system_ram_ram_symbol2.bin)
add_file_target(FILE Murax.v_toplevel_system_ram_ram_symbol3.bin)

add_file_target(FILE hx8k_b_evn_toplevel.v SCANNER_TYPE verilog)
add_file_target(FILE Murax.v SCANNER_TYPE verilog)
add_file_target(FILE basys3_toplevel.v SCANNER_TYPE verilog)
add_file_target(FILE basys3_toplevel_no_roi.v SCANNER_TYPE verilog)
add_file_target(FILE hx8k-b-evn.pcf)
add_file_target(FILE basys3.pcf)
add_file_target(FILE basys3.sdc)
add_file_target(FILE basys3_full.sdc)

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
  NAME murax_basys
  BOARD basys3
  TOP toplevel
  SOURCES
    basys3_toplevel.v
    Murax.v
  INPUT_IO_FILE basys3.pcf
  SDC_FILE basys3.sdc
  EXPLICIT_ADD_FILE_TARGET
)

add_fpga_target(
  NAME murax_basys_full
  BOARD basys3-full
  TOP toplevel
  SOURCES
    basys3_toplevel_no_roi.v
    Murax.v
  INPUT_IO_FILE basys3.pcf
  # TODO: need to fix https://github.com/SymbiFlow/vtr-verilog-to-routing/issues/367
  #SDC_FILE basys3_full.sdc
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
    NAME murax_basys_vivado
    PARENT_NAME murax_basys
    CLOCK_PINS io_mainClk
    CLOCK_PERIODS 10.0
    )

add_vivado_target(
    NAME murax_basys_full_vivado
    PARENT_NAME murax_basys_full
    CLOCK_PINS io_mainClk
    CLOCK_PERIODS 10.0
    )

add_vivado_pnr_target(
    NAME murax_basys_vivado_pnr
    PARENT_NAME murax_basys
    CLOCK_PINS io_mainClk
    CLOCK_PERIODS 10.0
    IOSTANDARD LVCMOS33
    )


add_file_target(FILE nexys_video_toplevel.v SCANNER_TYPE verilog)
add_file_target(FILE nexys_video.sdc)

get_file_target(TARGET_NEXYS_VIDEO_TOPLEVEL_V nexys_video_toplevel.v)
get_file_target(TARGET_NEXYS_VIDEO_PCF ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/tests/common/nexys_video.pcf)
get_file_target(TARGET_NEXYS_VIDEO_XDC ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/tests/common/nexys_video.xdc)
add_dependencies(${TARGET_NEXYS_VIDEO_TOPLEVEL_V} ${TARGET_NEXYS_VIDEO_XDC} ${TARGET_NEXYS_VIDEO_PCF})

add_fpga_target(
  NAME murax_nexys_video
  BOARD nexys_video
  TOP top
  SOURCES
    nexys_video_toplevel.v
    Murax.v
  SDC_FILE nexys_video.sdc
  INPUT_IO_FILE ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/tests/common/nexys_video.pcf
  INPUT_XDC_FILE ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/tests/common/nexys_video.xdc
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
  NAME murax_nexys_video_vivado
  PARENT_NAME murax_nexys_video
  CLOCK_PINS clk
  CLOCK_PERIODS 10.0
)

endif (NOT DEFINED ENV{CI} OR NOT $ENV{CI})

