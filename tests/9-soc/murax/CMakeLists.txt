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
  SDC_FILE basys3.sdc
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
endif (NOT DEFINED ENV{CI} OR NOT $ENV{CI})

