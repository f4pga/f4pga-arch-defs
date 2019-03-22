add_fpga_target(
  NAME scalable_proc
  BOARD basys3
  INPUT_IO_FILE basys3.pcf
  SOURCES rom.v processing_unit.v simpleuart.v scalable_proc.v basys3_top.v
  )
