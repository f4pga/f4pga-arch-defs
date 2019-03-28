add_file_target(FILE simpleuart.v SCANNER_TYPE verilog)
add_file_target(FILE scalable_proc.v SCANNER_TYPE verilog)
add_file_target(FILE processing_unit.v SCANNER_TYPE verilog)
add_file_target(FILE basys3.pcf)

get_target_property_required(PYTHON3 env PYTHON3)
get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

# Generate ROM veilog modules with different styles of implementation
set(ROM_FILE_BRAM rom_bram.v)
set(ROM_FILE_DRAM rom_dram.v)

add_file_target(FILE ${ROM_FILE_BRAM} GENERATED)
add_file_target(FILE ${ROM_FILE_DRAM} GENERATED)

add_custom_command(
    OUTPUT ${ROM_FILE_BRAM}
    COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/utils/rom_generator.py --rom-style bram >${ROM_FILE_BRAM}
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/utils/rom_generator.py ${PYTHON3} ${PYTHON3_TARGET}
)

add_custom_command(
    OUTPUT ${ROM_FILE_DRAM}
    COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/utils/rom_generator.py --rom-style dram64 >${ROM_FILE_DRAM}
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/utils/rom_generator.py ${PYTHON3} ${PYTHON3_TARGET}
)

if (NOT DEFINED ENV{CI} OR NOT $ENV{CI})

# Generate targets for the design
foreach(ROM_STYLE "bram" "dram")
    set(ROM_FILE rom_${ROM_STYLE}.v)

    foreach(NUM_PROCESSING_UNITS RANGE 1 8)
        set(VERILOG_TOP basys3_top_${ROM_STYLE}_n${NUM_PROCESSING_UNITS}.v)
        set(TOP_NAME top_${ROM_STYLE}_n${NUM_PROCESSING_UNITS})

        add_custom_command(
            OUTPUT ${VERILOG_TOP}
            COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/parametrize.py --num-processing-units ${NUM_PROCESSING_UNITS} --template ${CMAKE_CURRENT_SOURCE_DIR}/basys3_top.v > ${VERILOG_TOP}
            DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/parametrize.py ${CMAKE_CURRENT_SOURCE_DIR}/basys3_top.v ${PYTHON3} ${PYTHON3_TARGET}
            )

        add_file_target(
            FILE ${VERILOG_TOP}
            GENERATED
            )

        add_fpga_target(
            NAME ${TOP_NAME}
            BOARD basys3
            INPUT_IO_FILE basys3.pcf
            SOURCES ${ROM_FILE} processing_unit.v simpleuart.v scalable_proc.v ${VERILOG_TOP}
            EXPLICIT_ADD_FILE_TARGET
            )

    endforeach()
endforeach()

endif (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
