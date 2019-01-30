set(BOARDS basys3 zybo)

add_fpga_target_boards(
  NAME buttons
  BOARDS ${BOARDS}
  SOURCES buttons.v
  IMPLICIT_INPUT_IO_FILES
  )
