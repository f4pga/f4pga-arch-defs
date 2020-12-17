add_file_target(FILE switch_processing_arty_monolithic.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME switch_processing_arty_monolithic
  BOARD arty-full
  SOURCES switch_processing_arty_monolithic.v
  INPUT_IO_FILE ${COMMON}/arty_switch_processing_monolithic.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_file_target(FILE switch_processing_add_1.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME switch_processing_arty_add_1_pr1
  BOARD arty-switch-processing-pr1
  SOURCES switch_processing_add_1.v
  INPUT_IO_FILE ${COMMON}/arty_switch_processing_pr1.pcf
  GEN_PARTIAL_BIT
  EXPLICIT_ADD_FILE_TARGET
  )

add_file_target(FILE switch_processing_blink.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME switch_processing_arty_blink_pr2
  BOARD arty-switch-processing-pr2
  SOURCES switch_processing_blink.v
  INPUT_IO_FILE ${COMMON}/arty_switch_processing_pr2.pcf
  GEN_PARTIAL_BIT
  EXPLICIT_ADD_FILE_TARGET
  )

add_file_target(FILE switch_processing_identity.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME switch_processing_arty_identity_pr1
  BOARD arty-switch-processing-pr1
  SOURCES switch_processing_identity.v
  INPUT_IO_FILE ${COMMON}/arty_switch_processing_pr1.pcf
  GEN_PARTIAL_BIT
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME switch_processing_arty_identity_pr2
  BOARD arty-switch-processing-pr2
  SOURCES switch_processing_identity.v
  INPUT_IO_FILE ${COMMON}/arty_switch_processing_pr2.pcf
  GEN_PARTIAL_BIT
  EXPLICIT_ADD_FILE_TARGET
  )

add_file_target(FILE switch_processing_arty_overlay.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME switch_processing_arty_overlay
  BOARD arty-switch-processing-overlay
  SOURCES switch_processing_arty_overlay.v
  INPUT_IO_FILE ${COMMON}/arty_switch_processing_overlay.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_bitstream_target(
  NAME switch_processing_arty_both_merged
  USE_FASM
  INCLUDED_TARGETS switch_processing_arty_add_1_pr1 switch_processing_arty_blink_pr2 switch_processing_arty_overlay
  )

add_bitstream_target(
  NAME switch_processing_arty_add_1_merged
  USE_FASM
  INCLUDED_TARGETS switch_processing_arty_add_1_pr1 switch_processing_arty_identity_pr2 switch_processing_arty_overlay
  )

add_bitstream_target(
  NAME switch_processing_arty_blink_merged
  USE_FASM
  INCLUDED_TARGETS switch_processing_arty_identity_pr1 switch_processing_arty_blink_pr2 switch_processing_arty_overlay
  )

add_bitstream_target(
  NAME switch_processing_arty_identity_merged
  USE_FASM
  INCLUDED_TARGETS switch_processing_arty_identity_pr1 switch_processing_arty_identity_pr2 switch_processing_arty_overlay
  )
