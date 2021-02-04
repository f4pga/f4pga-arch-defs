add_file_target(FILE bistable_domain_cross.v SCANNER_TYPE verilog)
add_file_target(FILE edge_detect.v SCANNER_TYPE verilog)
add_file_target(FILE generic_dpram.v SCANNER_TYPE verilog)
add_file_target(FILE generic_fifo_dc_gray.v SCANNER_TYPE verilog)
add_file_target(FILE monostable_domain_cross.v SCANNER_TYPE verilog)
add_file_target(FILE sd_clock_divider.v SCANNER_TYPE verilog)
add_file_target(FILE sd_cmd_master.v SCANNER_TYPE verilog)
add_file_target(FILE sd_cmd_serial_host.v SCANNER_TYPE verilog)
add_file_target(FILE sd_controller_wb.v SCANNER_TYPE verilog)
add_file_target(FILE sd_crc_7.v SCANNER_TYPE verilog)
add_file_target(FILE sd_crc_16.v SCANNER_TYPE verilog)
add_file_target(FILE sd_data_master.v SCANNER_TYPE verilog)
add_file_target(FILE sd_data_serial_host.v SCANNER_TYPE verilog)
add_file_target(FILE sd_data_xfer_trig.v SCANNER_TYPE verilog)
add_file_target(FILE sd_defines.v SCANNER_TYPE verilog)
add_file_target(FILE sd_fifo_filler.v SCANNER_TYPE verilog)
add_file_target(FILE sdc_controller.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME sdc_controller-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES bistable_domain_cross.v edge_detect.v generic_dpram.v generic_fifo_dc_gray.v monostable_domain_cross.v sd_clock_divider.v sd_cmd_master.v sd_cmd_serial_host.v sd_controller_wb.v sd_crc_16.v sd_crc_7.v sd_data_master.v sd_data_serial_host.v sd_data_xfer_trig.v sd_defines.v sd_fifo_filler.v sdc_controller.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME sdc_controller-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES bistable_domain_cross.v edge_detect.v generic_dpram.v generic_fifo_dc_gray.v monostable_domain_cross.v sd_clock_divider.v sd_cmd_master.v sd_cmd_serial_host.v sd_controller_wb.v sd_crc_16.v sd_crc_7.v sd_data_master.v sd_data_serial_host.v sd_data_xfer_trig.v sd_defines.v sd_fifo_filler.v sdc_controller.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder sdc_controller-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    sdc_controller-ql-openfpga-k4_N8-adder_route)
