add_custom_target(all_xc7_iosettings)
add_dependencies(all_xc7_tests all_xc7_iosettings)

function(xc7_iosettings_design IOSTANDARD DRIVES SLEWS)

    set(DESIGN output_${IOSTANDARD})

    set(VERILOG_FILE ${DESIGN}.v)
    set(PCF_FILE ${DESIGN}.pcf)

    add_file_target(FILE ${VERILOG_FILE} GENERATED)
    add_file_target(FILE ${PCF_FILE} GENERATED)

    add_custom_command(
        OUTPUT ${VERILOG_FILE} ${PCF_FILE}
        COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/generate.py
            --mode output
            -o ${DESIGN}
            --iostandard ${IOSTANDARD}
            --drive ${DRIVES}
            --slew ${SLEWS}
        DEPENDS ${PYTHON3} ${PYTHON3_TARGET} generate.py
        )

    add_fpga_target(
        NAME ${DESIGN}_basys3
        BOARD basys3-full
        INPUT_IO_FILE ${PCF_FILE}
        SOURCES ${VERILOG_FILE}
        EXPLICIT_ADD_FILE_TARGET
        )

    add_vivado_target(
        NAME ${DESIGN}_basys3_vivado
        PARENT_NAME ${DESIGN}_basys3
        CLOCK_PINS clk
        CLOCK_PERIODS 10.0
        )

endfunction()

foreach(IOSTANDARD LVCMOS15 LVCMOS25 LVCMOS33)
    xc7_iosettings_design(${IOSTANDARD} "4 8 12 16" "SLOW FAST")
endforeach()

foreach(IOSTANDARD LVCMOS18 LVTTL)
    xc7_iosettings_design(${IOSTANDARD} "4 8 12 16 24" "SLOW FAST")
endforeach()

xc7_iosettings_design(LVCMOS12 "4 8 12" "SLOW FAST")
xc7_iosettings_design(SSTL135 "0" "SLOW FAST")
