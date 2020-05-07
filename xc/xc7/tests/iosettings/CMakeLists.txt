# These targets make Kokoro complain that the Ninja version is too low.
#add_custom_target(all_xc7_iosettings_generate)
#add_custom_target(all_xc7_iosettings_bin)
#add_custom_target(all_xc7_iosettings_bit_v)
#add_custom_target(all_xc7_iosettings_vivado_diff_fasm)

function(xc7_iosettings_design MODE BOARD IOSTANDARD DRIVES SLEWS TERMS VREF)

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

    if(NOT ${VREF} STREQUAL "")
        set(VREF_OPTS "--vref" ${VREF})
        set(DESIGN ${MODE}_${BOARD}_${IOSTANDARD}_${VREF}V)
    else()
        set(VREF_OPTS "")
        set(DESIGN ${MODE}_${BOARD}_${IOSTANDARD})
    endif()

    set(VERILOG_FILE ${DESIGN}.v)
    set(PCF_FILE ${DESIGN}.pcf)
    set(XDC_FILE ${DESIGN}.xdc)

    add_file_target(FILE ${VERILOG_FILE} GENERATED)
    add_file_target(FILE ${PCF_FILE} GENERATED)
    add_file_target(FILE ${XDC_FILE} GENERATED)

    separate_arguments(DRIVE_LIST UNIX_COMMAND ${DRIVES})
    separate_arguments(SLEW_LIST UNIX_COMMAND ${SLEWS})
    separate_arguments(TERM_LIST UNIX_COMMAND ${TERMS})

    add_custom_command(
        OUTPUT ${VERILOG_FILE} ${PCF_FILE} ${XDC_FILE}
        COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/generate.py
            --board ${BOARD}
            --mode ${MODE}
            -o ${DESIGN}
            --iostandard ${IOSTANDARD}
            --drive ${DRIVE_LIST}
            --slew ${SLEW_LIST}
            --in_term ${TERM_LIST}
            ${VREF_OPTS}
        DEPENDS ${PYTHON3} ${PYTHON3_TARGET} generate.py
        )

    add_fpga_target(
        NAME ${DESIGN}
        BOARD ${BOARD}
        INPUT_IO_FILE ${PCF_FILE}
        INPUT_XDC_FILE ${XDC_FILE}
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
        XDC ${XDC_FILE}
        ${VIVADO_ARGS}
        )

#    get_file_target(TARGET_V   ${DESIGN}.v)
#    get_file_target(TARGET_PCF ${DESIGN}.pcf)
#    get_file_target(TARGET_XDC ${DESIGN}.xdc)
#    add_dependencies(all_xc7_iosettings_generate ${TARGET_V} ${TARGET_PCF} ${TARGET_XDC})

#    add_dependencies(all_xc7_iosettings_bin ${DESIGN}_bin)
#    add_dependencies(all_xc7_iosettings_bit_v ${DESIGN}_bit_v)
#    add_dependencies(all_xc7_iosettings_vivado_diff_fasm ${DESIGN}_vivado_diff_fasm)

endfunction()

set(BOARD "arty-full")

# Single ended
foreach(MODE input output inout)

    if(MODE STREQUAL "input")
        set(TERMS "NONE UNTUNED_SPLIT_40 UNTUNED_SPLIT_50 UNTUNED_SPLIT_60")
    else()
        set(TERMS "NONE")
    endif()

    foreach(IOSTANDARD LVCMOS15 LVCMOS25 LVCMOS33)
        xc7_iosettings_design(${MODE} ${BOARD} ${IOSTANDARD} "4 8 12 16" "SLOW FAST" "NONE" "")
    endforeach()

    foreach(IOSTANDARD LVTTL) # Disabled LVCMOS18 due to #1263 (PUDC_B pin issues)
        xc7_iosettings_design(${MODE} ${BOARD} ${IOSTANDARD} "4 8 12 16 24" "SLOW FAST" "NONE" "")
    endforeach()

    xc7_iosettings_design(${MODE} ${BOARD} LVCMOS12 "4 8 12" "SLOW FAST" "NONE" "")

    foreach(IOSTANDARD SSTL135 SSTL15)
        # VREF is only relevant for input/inout
        if(NOT MODE STREQUAL "output")
            foreach(VREF 0.600 0.675 0.750 0.900)
                xc7_iosettings_design(${MODE} ${BOARD} ${IOSTANDARD} "0" "SLOW FAST" ${TERMS} ${VREF})
            endforeach()
        else()
            xc7_iosettings_design(${MODE} ${BOARD} ${IOSTANDARD} "0" "SLOW FAST" ${TERMS} "")
        endif()
    endforeach()

endforeach()

# Differential. Currently only differential output (tristated) is supported.
foreach(IOSTANDARD DIFF_SSTL135 DIFF_SSTL15)
    xc7_iosettings_design("diff_output" ${BOARD} ${IOSTANDARD} "0" "SLOW FAST" "NONE" "")
endforeach()

