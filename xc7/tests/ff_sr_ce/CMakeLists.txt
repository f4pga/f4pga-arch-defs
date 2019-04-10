add_file_target(FILE ff_ce_sr.v SCANNER_TYPE verilog)
add_file_target(FILE ff_ce_sr_testbench.v SCANNER_TYPE verilog)

add_custom_target(all_ff_ce_sr_test)

function(ff_ce_sr_test num_ff)
    get_target_property_required(PYTHON3 env PYTHON3)
    get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

    add_custom_command(
        OUTPUT ff_ce_sr_${num_ff}.v
        COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/generate.py
            --template ${CMAKE_CURRENT_SOURCE_DIR}/ff_ce_sr.v
            --params "NUM_FF=${num_ff}"
            --output ${CMAKE_CURRENT_BINARY_DIR}/ff_ce_sr_${num_ff}.v
        DEPENDS ${PYTHON3} ${PYTHON3_TARGET} ff_ce_sr.v generate.py
        )
    add_file_target(FILE ff_ce_sr_${num_ff}.v GENERATED)

    add_custom_command(
        OUTPUT ff_ce_sr_${num_ff}_tb.v
        COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/generate.py
            --template ${CMAKE_CURRENT_SOURCE_DIR}/ff_ce_sr_testbench.v
            --params "NUM_FF=${num_ff}"
            --output ${CMAKE_CURRENT_BINARY_DIR}/ff_ce_sr_${num_ff}_tb.v
        DEPENDS ${PYTHON3} ${PYTHON3_TARGET} ff_ce_sr_testbench.v generate.py
        )
    add_file_target(FILE ff_ce_sr_${num_ff}_tb.v GENERATED)
    get_file_target(TB_SOURCE_TARGET ff_ce_sr_testbench.v)
    get_file_target(TB_TARGET ff_ce_sr_${num_ff}_tb.v)
    get_target_property(INCLUDE_FILES ${TB_SOURCE_TARGET} INCLUDE_FILES)
    set_target_properties(${TB_TARGET} PROPERTIES INCLUDE_FILES
        ${INCLUDE_FILES})

    add_fpga_target(
        NAME ff_ce_sr_${num_ff}
        BOARD basys3
        INPUT_IO_FILE ../common/basys3.pcf
        SOURCES ${symbiflow-arch-defs_SOURCE_DIR}/library/lfsr.v ff_ce_sr_${num_ff}.v
        TESTBENCH_SOURCES ff_ce_sr_${num_ff}_tb.v
        EXPLICIT_ADD_FILE_TARGET
        EMIT_CHECK_TESTS
        EQUIV_CHECK_SCRIPT
            ${symbiflow-arch-defs_SOURCE_DIR}/yosys/equiv_simple_opt_full.ys
    )

    add_dependencies(all_ff_ce_sr_test
        testbench_ff_ce_sr_${num_ff}_tb
        testbinch_ff_ce_sr_${num_ff}_tb
        )
endfunction()

ff_ce_sr_test(3)
ff_ce_sr_test(4)
ff_ce_sr_test(7)
ff_ce_sr_test(8)
ff_ce_sr_test(9)
ff_ce_sr_test(15)
ff_ce_sr_test(16)
ff_ce_sr_test(17)
