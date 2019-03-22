add_file_target(FILE rom.v SCANNER_TYPE verilog)
add_file_target(FILE simpleuart.v SCANNER_TYPE verilog)
add_file_target(FILE scalable_proc.v SCANNER_TYPE verilog)
add_file_target(FILE processing_unit.v SCANNER_TYPE verilog)
add_file_target(FILE basys3.pcf)

get_target_property_required(PYTHON3 env PYTHON3)
get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

add_custom_target(scalable_proc_bin)

foreach(NUM_PROCESSING_UNITS RANGE 1 8)
    set(VERILOG_TOP basys3_top_n${NUM_PROCESSING_UNITS}.v)
    set(TOP_NAME top_n${NUM_PROCESSING_UNITS})

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
        SOURCES rom.v processing_unit.v simpleuart.v scalable_proc.v ${VERILOG_TOP}
        EXPLICIT_ADD_FILE_TARGET
        )

    add_dependencies(scalable_proc_bin ${TOP_NAME}_bin)

endforeach()

