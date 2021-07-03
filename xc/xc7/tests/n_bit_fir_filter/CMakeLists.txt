add_file_target(FILE fir_filter.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME n_bit_fir_filter
  BOARDS ${BOARDS}
  SOURCES fir_filter.v
  )