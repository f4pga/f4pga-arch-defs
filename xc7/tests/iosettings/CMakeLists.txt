add_custom_target(all_xc7_iosettings_diff_fasm)

function(xc7_iosettings_design MODE BOARD IOSTANDARD DRIVES SLEWS TERMS)

    cmake_parse_arguments(
        XC7_IOSETTINGS_DESIGN
        "DISABLE_DIFF_TEST"
        ""
        ""
        ${ARGN}
    )

    if(${XC7_IOSETTINGS_DESIGN_DISABLE_DIFF_TEST})
        set(VIVADO_ARGS DISABLE_DIFF_TEST)
    else()
        set(VIVADO_ARGS "")
    endif()

    set(DESIGN ${MODE}_${BOARD}_${IOSTANDARD})

    set(VERILOG_FILE ${DESIGN}.v)
    set(PCF_FILE ${DESIGN}.pcf)

    add_file_target(FILE ${VERILOG_FILE} GENERATED)
    add_file_target(FILE ${PCF_FILE} GENERATED)

    separate_arguments(DRIVE_LIST UNIX_COMMAND ${DRIVES})
    separate_arguments(SLEW_LIST UNIX_COMMAND ${SLEWS})
    separate_arguments(TERM_LIST UNIX_COMMAND ${TERMS})

    add_custom_command(
        OUTPUT ${VERILOG_FILE} ${PCF_FILE}
        COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/generate.py
            --board ${BOARD}
            --mode ${MODE}
            -o ${DESIGN}
            --iostandard ${IOSTANDARD}
            --drive ${DRIVE_LIST}
            --slew ${SLEW_LIST}
            --in_term ${TERM_LIST}
        DEPENDS ${PYTHON3} ${PYTHON3_TARGET} generate.py
        )

    add_fpga_target(
        NAME ${DESIGN}
        BOARD ${BOARD}-full
        INPUT_IO_FILE ${PCF_FILE}
        SOURCES ${VERILOG_FILE}
        EXPLICIT_ADD_FILE_TARGET
        # Enable non-dedicated routes for clocks in fasm2bels until the problem
        # of BUFG placement is solved. Those routes are not of concern for this
        # test.
        BIT_TO_V_EXTRA_ARGS --allow-non-dedicated-clk-routes
        )

    add_vivado_target(
        NAME ${DESIGN}_vivado
        PARENT_NAME ${DESIGN}
        CLOCK_PINS clk
        CLOCK_PERIODS 10.0
        ${VIVADO_ARGS}
        )

    add_dependencies(all_xc7_iosettings_diff_fasm ${DESIGN}_vivado_diff_fasm)

endfunction()

set(BOARD "arty")
foreach(MODE input output inout)

    if(MODE STREQUAL "input")
        set(TERMS "NONE UNTUNED_SPLIT_40 UNTUNED_SPLIT_50 UNTUNED_SPLIT_60")
    else()
        set(TERMS "NONE")
    endif()

    foreach(IOSTANDARD LVCMOS15 LVCMOS25 LVCMOS33)
        xc7_iosettings_design(${MODE} ${BOARD} ${IOSTANDARD} "4 8 12 16" "SLOW FAST" "NONE")
    endforeach()

    foreach(IOSTANDARD LVCMOS18 LVTTL)
        xc7_iosettings_design(${MODE} ${BOARD} ${IOSTANDARD} "4 8 12 16" "SLOW FAST" "NONE")
    endforeach()

    xc7_iosettings_design(${MODE} ${BOARD} LVCMOS12 "4 8 12" "SLOW FAST" "NONE")

    # Disabled due to https://github.com/SymbiFlow/prjxray/issues/1182
    #xc7_iosettings_design(${MODE} ${BOARD} SSTL135 "0" "SLOW FAST" ${TERMS})

endforeach()

# Currently only one differential setting is supported
# Diff fasm disabled due to https://github.com/SymbiFlow/symbiflow-arch-defs/issues/1239
xc7_iosettings_design("diff_output" ${BOARD} DIFF_SSTL135 "0" "SLOW FAST" "NONE" DISABLE_DIFF_TEST)

