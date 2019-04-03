foreach(file reset_controller.v saturating_counter.v output_comparator.v
        output_generator.v frame_generator.v soft_test_fixture.v)
    add_file_target(FILE ${file} SCANNER_TYPE verilog)
    list(APPEND SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/${file})
endforeach()

get_target_property_required(UART_SOURCES uart_library SOURCES)
add_custom_target(test_fixture_library)
set_target_properties(test_fixture_library PROPERTIES SOURCES "${UART_SOURCES};${SOURCES}")
