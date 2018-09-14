add_file_target(FILE Murax.v_toplevel_system_ram_ram_symbol0.bin)
add_file_target(FILE Murax.v_toplevel_system_ram_ram_symbol1.bin)
add_file_target(FILE Murax.v_toplevel_system_ram_ram_symbol2.bin)
add_file_target(FILE Murax.v_toplevel_system_ram_ram_symbol3.bin)

if (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
add_fpga_target(
  NAME murax
  BOARD hx8k-b-evn
  TOP toplevel
  SOURCES
    toplevel.v
    Murax.v
  INPUT_IO_FILE hx8k-b-evn.pcf
)
endif (NOT DEFINED ENV{CI} OR NOT $ENV{CI})

