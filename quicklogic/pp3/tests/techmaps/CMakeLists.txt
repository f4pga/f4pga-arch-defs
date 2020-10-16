
add_custom_target(all_quicklogic_lut_techmap_tests)

# ~~~
# LUT_TECHMAP_TEST(
#    N <lut width>
#    LUT_COUNT <LUT count>
# )
#
# This function adds a single test for LUT -> INV+MUX techmap. The test verifies
# that the techmap correctly transforms LUTn to a MUX tree with inverters.
# The check is performed by behavioral simulation using the Icarus Verilog.
function(lut_techmap_test N LUT_COUNT)

    get_target_property_required(QUIET_CMD env QUIET_CMD)
    get_target_property(QUIET_CMD_TARGET env QUIET_CMD_TARGET)

    get_target_property_required(PYTHON3 env PYTHON3)
    get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

    get_target_property_required(YOSYS env YOSYS)
    get_target_property(YOSYS_TARGET env YOSYS_TARGET)

    get_target_property_required(IVERILOG env IVERILOG)
    get_target_property(IVERILOG_TARGET env IVERILOG_TARGET)
    get_target_property_required(VVP env VVP)
    get_target_property(VVP_TARGET env VVP_TARGET)

    set(VPR_CELLS_MAP_FILE ${CMAKE_CURRENT_SOURCE_DIR}/../../techmap/cells_map.v)
    get_filename_component(BASE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../.. ABSOLUTE)
    get_filename_component(FAMILY_NAME ${BASE_PATH} NAME)
    set(VPR_CELLS_SIM_FILE ${symbiflow-arch-defs_BINARY_DIR}/quicklogic/${FAMILY_NAME}/techmap/cells_sim.v)
    get_file_target(VPR_CELLS_SIM_FILE_DEP ${VPR_CELLS_SIM_FILE})
    get_file_location(VPR_CELLS_SIM_FILE ${VPR_CELLS_SIM_FILE})

    get_filename_component(YOSYS_PATH ${YOSYS} DIRECTORY)
    set(YOSYS_CELLS_SIM_FILE ${YOSYS_PATH}/share/quicklogic/cells_sim.v)

    set(BASENAME "test_techmap_lut${N}_x${LUT_COUNT}")
    set(LUT_DUT_FILE "${BASENAME}_dut_lut.v")
    set(MUX_DUT_FILE "${BASENAME}_dut_mux.v")
    set(DUT_MITER_FILE "${BASENAME}_miter.v")
    set(TESTBENCH_FILE "tb.v")
    set(VPP_FILE "${BASENAME}.vpp")
    append_file_dependency(TESTBENCH_FILE_DEP ${TESTBENCH_FILE})

    # Generate the design that uses LUTs
    add_custom_command(
        OUTPUT ${LUT_DUT_FILE}
        COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/lut_testgen.py
            -n ${N} --lut-count ${LUT_COUNT} >${CMAKE_CURRENT_BINARY_DIR}/${LUT_DUT_FILE}
        DEPENDS ${PYTHON3} ${PYTHON3_TARGET} lut_testgen.py
        )
    add_file_target(FILE ${LUT_DUT_FILE} GENERATED)

    # Use Yosys to apply LUT -> INV+MUX techmap
    set(YOSYS_LUT2MUX_CMDS
        " read_verilog -lib +/quicklogic/cells_sim.v"
        " read_verilog ${CMAKE_CURRENT_BINARY_DIR}/${LUT_DUT_FILE}"
        " techmap -map ${VPR_CELLS_MAP_FILE} dut_lut"
        " rename -top dut_mux"
        " write_verilog ${CMAKE_CURRENT_BINARY_DIR}/${MUX_DUT_FILE}"
    )

    add_custom_command(
        OUTPUT ${MUX_DUT_FILE}
        COMMAND ${QUIET_CMD} ${YOSYS} -p "${YOSYS_LUT2MUX_CMDS}"
        DEPENDS ${YOSYS} ${YOSYS_TARGET} ${LUT_DUT_FILE} ${VPR_CELLS_MAP_FILE}
        VERBATIM
        )
    add_file_target(FILE ${MUX_DUT_FILE} GENERATED)

    # Use Yosys to generate a miter circuit for both designs
    set(YOSYS_MITER_CMDS
        " read_verilog -lib +/quicklogic/cells_sim.v"
        " read_verilog -lib ${VPR_CELLS_SIM_FILE}"
        " read_verilog ${CMAKE_CURRENT_BINARY_DIR}/${LUT_DUT_FILE}"
        " read_verilog ${CMAKE_CURRENT_BINARY_DIR}/${MUX_DUT_FILE}"
        " miter -equiv dut_lut dut_mux dut_miter"
        " select -module dut_miter"
        " write_verilog -selected ${CMAKE_CURRENT_BINARY_DIR}/${DUT_MITER_FILE}"
    )

    add_custom_command(
        OUTPUT ${DUT_MITER_FILE}
        COMMAND ${QUIET_CMD} ${YOSYS} -p "${YOSYS_MITER_CMDS}"
        DEPENDS ${YOSYS} ${YOSYS_TARGET} ${LUT_DUT_FILE} ${MUX_DUT_FILE} ${VPR_CELLS_SIM_FILE_DEP}
        VERBATIM
        )
    add_file_target(FILE ${DUT_MITER_FILE} GENERATED)

    # Generate VPP using Icarus Verilog
    add_custom_command(
        OUTPUT ${VPP_FILE}
        COMMAND ${QUIET_CMD} ${IVERILOG} -v -DVCDFILE=\"${BASENAME}.vcd\"
            -s tb
            -o ${CMAKE_CURRENT_BINARY_DIR}/${VPP_FILE}
            ${YOSYS_CELLS_SIM_FILE}
            ${VPR_CELLS_SIM_FILE}
            ${CMAKE_CURRENT_BINARY_DIR}/${LUT_DUT_FILE}
            ${CMAKE_CURRENT_BINARY_DIR}/${MUX_DUT_FILE}
            ${CMAKE_CURRENT_BINARY_DIR}/${DUT_MITER_FILE}
            ${CMAKE_CURRENT_SOURCE_DIR}/${TESTBENCH_FILE}
        DEPENDS ${IVERILOG} ${IVERILOG_TARGET} ${DUT_MITER_FILE} ${TESTBENCH_FILE_DEP} ${VPR_CELLS_SIM_FILE_DEP} ${VPR_CELLS_SIM_FILE}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        VERBATIM
        )

    # The final simulation-running target
    add_custom_target(
        ${BASENAME}
        COMMAND ${QUIET_CMD} ${VVP} -v -N ${VPP_FILE}
        DEPENDS ${VVP} ${VVP_TARGET} ${VPP_FILE}
        )

    # Add dependency to the "all" test target.
    add_dependencies(all_quicklogic_lut_techmap_tests ${BASENAME})

endfunction()

# The common testbench file
add_file_target(FILE tb.v SCANNER_TYPE verilog)

# Add test cases
lut_techmap_test(1 10)
lut_techmap_test(2 25)
lut_techmap_test(3 50)
lut_techmap_test(4 100)

add_dependencies(all_ql_tests all_quicklogic_lut_techmap_tests)
