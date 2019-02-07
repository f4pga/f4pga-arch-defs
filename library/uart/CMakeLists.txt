foreach(file baudgen.v uart_rx.v uart_tx.v uart.v)
    add_file_target(FILE ${file} SCANNER_TYPE verilog)
    list(APPEND SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/${file})
endforeach()

add_custom_target(uart_library)
set_target_properties(uart_library PROPERTIES SOURCES "${SOURCES}")
