set(BOARDS basys3 zybo)

add_fpga_target_boards(
  NAME counter
  BOARDS ${BOARDS}
  SOURCES counter.v
  IMPLICIT_INPUT_IO_FILES
  )
