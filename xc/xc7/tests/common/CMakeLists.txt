# BASYS3 constraint files
add_file_target(FILE basys3.pcf)
add_file_target(FILE basys3.sdc)
add_file_target(FILE basys3.xdc)
add_file_target(FILE basys3_pmod.pcf)
add_file_target(FILE basys3_gtp_common.pcf)
add_file_target(FILE basys3_gtp_channel.pcf)

# ARTY constraint files
add_file_target(FILE arty_uart.pcf)
add_file_target(FILE arty_swbut.pcf)
add_file_target(FILE arty_swbut_pr_overlay.pcf)
add_file_target(FILE arty_swbut_pr_2clk.pcf)
add_file_target(FILE arty_swbut_pr.pcf)
add_file_target(FILE arty_switch_processing_monolithic.pcf)
add_file_target(FILE arty_switch_processing_overlay.pcf)
add_file_target(FILE arty_switch_processing_pr1.pcf)
add_file_target(FILE arty_switch_processing_pr2.pcf)

# ZYBO constraint files
add_file_target(FILE zybo.pcf)
add_file_target(FILE zyboz7.pcf)
add_file_target(FILE zedboard.pcf)
add_file_target(FILE pynqz1.pcf)
add_file_target(FILE marszx3.pcf)
add_file_target(FILE zybo_z7.pcf)

# Nexys-video constraint files
add_file_target(FILE nexys_video.pcf)
add_file_target(FILE nexys_video.xdc)
add_file_target(FILE nexys_video_noclk.xdc)
add_file_target(FILE nexys_video_gtp_channel.pcf)

add_file_target(FILE error_output_logic.v SCANNER_TYPE verilog)
add_file_target(FILE error_output_logic_unt.v SCANNER_TYPE verilog)
add_file_target(FILE error_output_logic_tb.v SCANNER_TYPE verilog)

add_fpga_target(
    NAME error_output_logic_test
    BOARD basys3
    INPUT_IO_FILE basys3.pcf
    SOURCES
        error_output_logic_unt.v
        error_output_logic.v
    TESTBENCH_SOURCES
        error_output_logic_tb.v
    EXPLICIT_ADD_FILE_TARGET
)

add_dependencies(all_xc7_tests
    testbench_error_output_logic_tb
    testbench_synth_error_output_logic_tb
    testbinch_error_output_logic_tb
    )

add_file_target(FILE ram_shifter.v SCANNER_TYPE verilog)
add_file_target(FILE ram_test.v SCANNER_TYPE verilog)
add_file_target(FILE rom_test.v SCANNER_TYPE verilog)
