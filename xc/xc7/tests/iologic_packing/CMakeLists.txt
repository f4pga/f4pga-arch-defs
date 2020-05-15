add_custom_target(all_xc7_iologic_vivado_diff_fasm)

# =============================================================================

function(xc7_iologic_design BOARD IOB_TYPE USE_IDELAY USE_ISERDES USE_OSERDES )

    set(DESIGN iologic_${IOB_TYPE})
    if (${USE_IDELAY})
        set(DESIGN ${DESIGN}_IDELAY)
    endif()
    if (${USE_ISERDES})
        set(DESIGN ${DESIGN}_ISERDES)
    endif()
    if (${USE_OSERDES})
        set(DESIGN ${DESIGN}_OSERDES)
    endif()

    set(VERILOG_FILE ${DESIGN}.v)
    set(PCF_FILE ${DESIGN}.pcf)
    set(XDC_FILE ${DESIGN}.xdc)

    add_file_target(FILE ${VERILOG_FILE} GENERATED)
    add_file_target(FILE ${PCF_FILE} GENERATED)
    add_file_target(FILE ${XDC_FILE} GENERATED)

    set(IOLOGIC_OPTS "")
    if (${USE_IDELAY})
        set(IOLOGIC_OPTS ${IOLOGIC_OPTS} "--idelay")
    endif()
    if (${USE_ISERDES})
        set(IOLOGIC_OPTS ${IOLOGIC_OPTS} "--iserdes")
    endif()
    if (${USE_OSERDES})
        set(IOLOGIC_OPTS ${IOLOGIC_OPTS} "--oserdes")
    endif()

    add_custom_command(
        OUTPUT ${VERILOG_FILE} ${PCF_FILE} ${XDC_FILE}
        COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/generate.py
            --board ${BOARD}
            --iob ${IOB_TYPE}
            -o ${DESIGN}
            ${IOLOGIC_OPTS}
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
        XDC ${XDC_FILE}
        ${VIVADO_ARGS}
        )

    add_dependencies(all_xc7_iologic_vivado_diff_fasm ${DESIGN}_vivado_diff_fasm)

endfunction()

# =============================================================================

# Has to run on a chip with all IOBs bonded (eg. the "arty" board). Can be
# run on "basys3-bottom" once https://github.com/SymbiFlow/prjxray/issues/1329
# is fixed.
set(BOARD "arty-full")

# Generate all combinations
#
# Disabled for now. There are 32 combinations, 11 succeeds.

#foreach(IOB_TYPE IBUF IBUFDS)
#    foreach(USE_IDELAY 0 1)
#        foreach(USE_ISERDES 0 1)
#            xc7_iologic_design(${BOARD} ${IOB_TYPE} ${USE_IDELAY} ${USE_ISERDES} 0)
#        endforeach()
#    endforeach()
#endforeach()
#
#foreach(IOB_TYPE OBUF OBUFT OBUFDS OBUFTDS)
#    foreach(USE_OSERDES 0 1)
#        xc7_iologic_design(${BOARD} ${IOB_TYPE} 0 0 ${USE_OSERDES})
#    endforeach()
#endforeach()
#
#foreach(IOB_TYPE IOBUF IOBUFDS)
#    foreach(USE_IDELAY 0 1)
#        foreach(USE_ISERDES 0 1)
#            foreach(USE_OSERDES 0 1)
#                xc7_iologic_design(${BOARD} ${IOB_TYPE} ${USE_IDELAY} ${USE_ISERDES} ${USE_OSERDES})
#            endforeach()
#        endforeach()
#    endforeach()
#endforeach()

# These tests succeed
xc7_iologic_design(${BOARD} IBUF    0 0 0)

xc7_iologic_design(${BOARD} IOBUF   0 0 0)
xc7_iologic_design(${BOARD} IOBUF   0 1 1)
xc7_iologic_design(${BOARD} IOBUF   1 1 1)
xc7_iologic_design(${BOARD} IOBUF   0 0 1)

xc7_iologic_design(${BOARD} IOBUFDS 0 0 0)
#xc7_iologic_design(${BOARD} IOBUFDS 0 0 1) # This one makes OUT_DIFF not be emitted. Unclear why.
xc7_iologic_design(${BOARD} IOBUFDS 0 1 0)
xc7_iologic_design(${BOARD} IOBUFDS 0 1 1)
xc7_iologic_design(${BOARD} IOBUFDS 1 1 0)
xc7_iologic_design(${BOARD} IOBUFDS 1 1 1)

xc7_iologic_design(${BOARD} OBUF    0 0 0)
xc7_iologic_design(${BOARD} OBUF    0 0 1)
xc7_iologic_design(${BOARD} OBUFDS  0 0 0)
#xc7_iologic_design(${BOARD} OBUFDS  0 0 1)  # https://github.com/SymbiFlow/symbiflow-arch-defs/issues/1469
xc7_iologic_design(${BOARD} OBUFTDS 0 0 0)
xc7_iologic_design(${BOARD} OBUFTDS 0 0 1)


