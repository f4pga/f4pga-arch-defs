add_fpga_target_boards(
  NAME counter
  BOARDS basys3 zybo
  SOURCES counter.v
  IMPLICIT_INPUT_IO_FILES
  )

add_fpga_target_boards(
  NAME counter
  BOARDS arty
  SOURCES counter_arty.v
  IMPLICIT_INPUT_IO_FILES
  )
