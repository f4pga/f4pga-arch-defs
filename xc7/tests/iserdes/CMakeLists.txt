add_file_target(FILE rom.v SCANNER_TYPE verilog)
add_file_target(FILE receiver.v SCANNER_TYPE verilog)
add_file_target(FILE serializer.v SCANNER_TYPE verilog)
add_file_target(FILE comparator.v SCANNER_TYPE verilog)
add_file_target(FILE transmitter.v SCANNER_TYPE verilog)
add_file_target(FILE iserdes_test.v SCANNER_TYPE verilog)
add_file_target(FILE basys3.pcf)

add_custom_target(all_iserdes_test)
add_dependencies(all_xc7_tests all_iserdes_test)

function(iserdes_test data_width data_rate)
  string(TOLOWER ${data_rate} data_rate_lower)

  add_custom_command(
      OUTPUT iserdes_basys3_${data_width}_${data_rate_lower}.v
      COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/generate.py
        --input ${CMAKE_CURRENT_SOURCE_DIR}/iserdes_basys3.v
        --output ${CMAKE_CURRENT_BINARY_DIR}/iserdes_basys3_${data_width}_${data_rate_lower}.v
        --data_width ${data_width}
        --data_rate ${data_rate}
      DEPENDS ${PYTHON3} ${PYTHON3_TARGET} generate.py
    )

  add_file_target(FILE iserdes_basys3_${data_width}_${data_rate_lower}.v GENERATED)

  add_fpga_target(
    NAME iserdes_basys3_${data_width}_${data_rate_lower}
    BOARD basys3-bottom
    SOURCES
      iserdes_basys3_${data_width}_${data_rate_lower}.v
      serializer.v
      iserdes_test.v
    INPUT_IO_FILE basys3.pcf
    EXPLICIT_ADD_FILE_TARGET
    )

  add_vivado_target(
    NAME iserdes_basys3_${data_width}_${data_rate_lower}_vivado
    PARENT_NAME iserdes_basys3_${data_width}_${data_rate_lower}
    )

  add_dependencies(all_iserdes_test iserdes_basys3_${data_width}_${data_rate_lower}_bin)

endfunction()

#SDR
iserdes_test(2 SDR)
iserdes_test(3 SDR)
iserdes_test(4 SDR)
iserdes_test(5 SDR)
iserdes_test(6 SDR)
iserdes_test(7 SDR)
iserdes_test(8 SDR)

#DDR
iserdes_test(4 DDR)
iserdes_test(6 DDR)
iserdes_test(8 DDR)
