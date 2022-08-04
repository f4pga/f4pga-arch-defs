set(BASE_TEST_NAME bram_test)
get_target_property_required(UART_SOURCES uart_library SOURCES)

list(APPEND SOURCES ${symbiflow-arch-defs_SOURCE_DIR}/library/lfsr.v ${COMMON}/error_output_logic.v ${COMMON}/ram_test.v)

get_target_property_required(DEVICE basys3 DEVICE)
get_target_property_required(ARCH ${DEVICE} ARCH)

# Symmetric modes only
set(BRAM18_WIDTHS 1 2 4 9 18)
set(BRAM36_WIDTHS 1 2 4 9 18 36)

add_file_target(FILE bram_test.v SCANNER_TYPE verilog)

get_target_property_required(PYTHON3 env PYTHON3)
set(GENERATE_DEPS ${CMAKE_CURRENT_SOURCE_DIR}/generate_test.py ${PYTHON3})

add_custom_target(all_xc7_bram_diff_fasm)
set(ANY_BRAM_DIFF_FASM FALSE)
foreach(type 18 36)
    foreach(width ${BRAM${type}_WIDTHS})
        set(FNAME ${BASE_TEST_NAME}_${type}_${width}.v)
        add_custom_command(
            OUTPUT ${FNAME}
            COMMAND ${PYTHON3}
              ${CMAKE_CURRENT_SOURCE_DIR}/generate_test.py
                --type ${type}
                --width ${width}
                > ${CMAKE_CURRENT_BINARY_DIR}/${FNAME}
            DEPENDS ${GENERATE_DEPS})

        add_file_target(FILE ${FNAME} GENERATED)
        get_file_target(TARGET_NAME ${FNAME})

        set_target_properties(
            ${TARGET_NAME}
            PROPERTIES
                INCLUDE_FILES bram_test.v)

        add_fpga_target(
            NAME ${BASE_TEST_NAME}_${type}_${width}
            BOARD basys3
            INPUT_IO_FILE ${COMMON}/basys3.pcf
            SOURCES ${UART_SOURCES} ${SOURCES} ${FNAME}
            EXPLICIT_ADD_FILE_TARGET
            )

        get_target_property_required(SYNTH_V ${BASE_TEST_NAME}_${type}_${width} SYNTH_V)

        add_autosim(
            NAME ${BASE_TEST_NAME}_${type}_${width}_autosim_synth
            TOP top
            ARCH ${ARCH}
            SOURCES ${SYNTH_V}
            CYCLES 3000
            )

        add_vivado_target(
            NAME bram_test_${type}_${width}_vivado
            PARENT_NAME bram_test_${type}_${width}
            CLOCK_PINS clk
            CLOCK_PERIODS 10.0
            )

        if(${ALL_XC7_DIFF_FASM_VERILOG})
            set(DIFF_FASM_TARGET bram_test_${type}_${width}_vivado_diff_fasm)
            if(TARGET ${DIFF_FASM_TARGET})
                add_dependencies(all_xc7_bram_diff_fasm ${DIFF_FASM_TARGET})
                set(ANY_BRAM_DIFF_FASM TRUE)
            endif()
        endif()
        if(${ALL_XC7_DIFF_FASM_INTERCHANGE})
            set(DIFF_FASM_TARGET bram_test_${type}_${width}_vivado_interchange_diff_fasm)
            if(TARGET ${DIFF_FASM_TARGET})
                add_dependencies(all_xc7_bram_diff_fasm ${DIFF_FASM_TARGET})
                set(ANY_BRAM_DIFF_FASM TRUE)
            endif()
        endif()
    endforeach()
endforeach()

if(NOT ${ANY_BRAM_DIFF_FASM})
    add_custom_target(
        no_bram_diff_fasm_targets
        COMMAND ${CMAKE_COMMAND} -E echo "No targets for all_xc7_bram_diff_fasm, check CMake configure messages for details.")
    add_dependencies(all_xc7_bram_diff_fasm no_bram_diff_fasm_targets)
endif()
