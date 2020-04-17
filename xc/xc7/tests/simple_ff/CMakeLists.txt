add_file_target(FILE simple_ff.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME simple_ff
  BOARD basys3
  INPUT_IO_FILE ${COMMON}/basys3.pcf
  SOURCES simple_ff.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME simple_ff_vivado
  PARENT_NAME simple_ff
  # TODO: https://github.com/SymbiFlow/symbiflow-arch-defs/issues/1018
  DISABLE_DIFF_TEST
  )

add_file_target(FILE simple_ff_full.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME simple_ff_full
  BOARD basys3-full
  INPUT_IO_FILE ${COMMON}/basys3.pcf
  SOURCES simple_ff_full.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME simple_ff_full_vivado
  PARENT_NAME simple_ff_full
  )

add_file_target(FILE simple_ff_full_loc.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME simple_ff_full_loc
  BOARD basys3-full
  INPUT_IO_FILE ${COMMON}/basys3.pcf
  SOURCES simple_ff_full_loc.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME simple_ff_full_loc_vivado
  PARENT_NAME simple_ff_full_loc
  )

get_target_property(OUT_FASM simple_ff_full_loc OUT_FASM)
add_custom_target(
  simple_ff_full_loc_check
  COMMENT "Check placement constraints"
  COMMAND
    grep "CLBLL_R_X19Y45.SLICEL_X1" ${OUT_FASM} | grep "FF"
  DEPENDS ${OUT_FASM}
  )

# XXX: need to fix attribute trimming when running with abc9
# https://github.com/YosysHQ/yosys/issues/2176
#add_dependencies(all_xc7_tests simple_ff_full_loc_check)
