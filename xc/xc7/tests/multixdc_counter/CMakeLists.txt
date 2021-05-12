add_file_target(FILE arty_0.xdc)
add_file_target(FILE arty_1.xdc)
add_file_target(FILE arty_2.xdc)

add_fpga_target(
  NAME multixdc_counter_arty
  BOARD arty-full
  SOURCES ${COUNTER_SRC}/counter_arty.v
  INPUT_XDC_FILES arty_0.xdc arty_1.xdc arty_2.xdc
  EXPLICIT_ADD_FILE_TARGET
)
