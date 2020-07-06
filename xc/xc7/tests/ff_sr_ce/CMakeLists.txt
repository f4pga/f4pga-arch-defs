add_file_target(FILE ff_type.v SCANNER_TYPE verilog)
add_file_target(FILE ff_ce_sr.v SCANNER_TYPE verilog)
add_file_target(FILE ff_ce_sr_testbench.v SCANNER_TYPE verilog)

add_custom_target(all_ff_ce_sr_test)
add_dependencies(all_xc7_tests all_ff_ce_sr_test)

function(ff_ce_sr_test num_ff)
    get_target_property_required(PYTHON3 env PYTHON3)
    get_target_property_required(YOSYS env YOSYS)

    set(SBY
        ${symbiflow-arch-defs_SOURCE_DIR}/third_party/symbiyosys/sbysrc/sby.py)

    foreach(ff_type FDRE FDSE FDCE FDPE)
        string(TOLOWER ${ff_type} ff_type_lower)

        add_custom_command(
            OUTPUT ff_ce_sr_${num_ff}_${ff_type_lower}.v
            COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/generate.py
                --template ${CMAKE_CURRENT_SOURCE_DIR}/ff_ce_sr.v
                --params "'NUM_FF=${num_ff},FF_TYPE=\"${ff_type}\"'"
                --output
                  ${CMAKE_CURRENT_BINARY_DIR}/ff_ce_sr_${num_ff}_${ff_type_lower}.v
            DEPENDS ${PYTHON3} ff_ce_sr.v generate.py
            )
        add_file_target(FILE ff_ce_sr_${num_ff}_${ff_type_lower}.v GENERATED)

        set(TESTBENCH "")
        if("${ff_type}" STREQUAL "FDRE")
            # The testbench is written for FDRE only.
            add_custom_command(
                OUTPUT ff_ce_sr_${num_ff}_tb.v
                COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/generate.py
                    --template ${CMAKE_CURRENT_SOURCE_DIR}/ff_ce_sr_testbench.v
                    --params "NUM_FF=${num_ff}"
                    --output ${CMAKE_CURRENT_BINARY_DIR}/ff_ce_sr_${num_ff}_tb.v
                DEPENDS ${PYTHON3} ff_ce_sr_testbench.v generate.py
                )
            add_file_target(FILE ff_ce_sr_${num_ff}_tb.v GENERATED)
            get_file_target(TB_SOURCE_TARGET ff_ce_sr_testbench.v)
            get_file_target(TB_TARGET ff_ce_sr_${num_ff}_tb.v)
            get_target_property(INCLUDE_FILES ${TB_SOURCE_TARGET} INCLUDE_FILES)
            set_target_properties(${TB_TARGET} PROPERTIES INCLUDE_FILES
                ${INCLUDE_FILES})

            set(TESTBENCH TESTBENCH_SOURCES ff_ce_sr_${num_ff}_tb.v)
        endif()

        add_fpga_target(
            NAME ff_ce_sr_${num_ff}_${ff_type_lower}
            BOARD basys3
            INPUT_IO_FILE ${COMMON}/basys3.pcf
            SOURCES
                ${symbiflow-arch-defs_SOURCE_DIR}/library/lfsr.v
                ff_type.v
                ff_ce_sr_${num_ff}_${ff_type_lower}.v
            ${TESTBENCH}
            EXPLICIT_ADD_FILE_TARGET
        )

        if(${ff_type} EQUAL FDRE)
            add_dependencies(all_ff_ce_sr_test
                testbench_ff_ce_sr_${num_ff}_tb
                testbinch_ff_ce_sr_${num_ff}_tb
                )
        endif()

        # Note that the name of sby will become a directory, so do NOT name it
        # the same as the add_fpga_target name, otherwise sby will remove that
        # directory.
        add_custom_command(
            OUTPUT ff_ce_sr_${num_ff}_${ff_type_lower}_proof.sby
            COMMAND ${PYTHON3}
                ${CMAKE_CURRENT_SOURCE_DIR}/create_sby.py
                    --num_ff ${num_ff}
                    --ff_type ${ff_type_lower} >
                    ff_ce_sr_${num_ff}_${ff_type_lower}_proof.sby
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
            DEPENDS
                ${PYTHON3}
                ${CMAKE_CURRENT_SOURCE_DIR}/create_sby.py
            )

        add_custom_target(
            ff_ce_sr_${num_ff}_${ff_type_lower}_prove
            COMMAND ${PYTHON3} ${SBY}
                --yosys ${YOSYS}
                --abc ${YOSYS}-abc
                --smtbmc ${YOSYS}-smtbmc
                -f ff_ce_sr_${num_ff}_${ff_type_lower}_proof.sby
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
            DEPENDS
                ff_ce_sr_${num_ff}_${ff_type_lower}_proof.sby
                ${PYTHON3}
                ${YOSYS}
                ff_ce_sr_${num_ff}_${ff_type_lower}_bit_v
            )

        add_dependencies(all_ff_ce_sr_test
            ff_ce_sr_${num_ff}_${ff_type_lower}_prove
            )
    endforeach()
endfunction()

ff_ce_sr_test(3)
ff_ce_sr_test(4)
ff_ce_sr_test(7)
ff_ce_sr_test(8)
ff_ce_sr_test(9)
ff_ce_sr_test(15)
ff_ce_sr_test(16)
ff_ce_sr_test(17)
