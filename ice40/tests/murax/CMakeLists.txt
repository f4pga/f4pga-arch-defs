add_fpga_target(
  NAME murax
  BOARD hx8k-b-evn
  TOP toplevel
  SOURCES
    toplevel.v
    Murax.v
  INPUT_IO_FILE hx8k-b-evn.pcf
)

