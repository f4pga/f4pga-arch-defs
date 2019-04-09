add_file_target(FILE ff_ce_sr.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME ff_ce_sr
  BOARD basys3
  INPUT_IO_FILE ../common/basys3.pcf
  SOURCES ff_ce_sr.v
  EXPLICIT_ADD_FILE_TARGET
  EMIT_CHECK_TESTS
  EQUIV_CHECK_SCRIPT
      ${symbiflow-arch-defs_SOURCE_DIR}/yosys/equiv_simple_opt_full.ys
  )
