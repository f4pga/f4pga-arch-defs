add_file_target(FILE serdes_test.v SCANNER_TYPE verilog)
add_file_target(FILE serdes_test_idelay.v SCANNER_TYPE verilog)
add_file_target(FILE basys3.pcf)

add_custom_target(all_serdes_test)
add_dependencies(all_xc7_tests all_serdes_test)

function(serdes_test data_width data_rate)
  string(TOLOWER ${data_rate} data_rate_lower)

  add_custom_command(
      OUTPUT serdes_basys3_${data_width}_${data_rate_lower}.v
      COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/generate_tests.py
        --input ${CMAKE_CURRENT_SOURCE_DIR}/serdes_basys3.v
        --output ${CMAKE_CURRENT_BINARY_DIR}/serdes_basys3_${data_width}_${data_rate_lower}.v
        --data_width ${data_width}
        --data_rate ${data_rate}
      DEPENDS ${PYTHON3} ${PYTHON3_TARGET} generate_tests.py ${CMAKE_CURRENT_SOURCE_DIR}/serdes_basys3.v
    )

  add_custom_command(
      OUTPUT serdes_basys3_idelay_${data_width}_${data_rate_lower}.v
      COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/generate_tests.py
        --input ${CMAKE_CURRENT_SOURCE_DIR}/serdes_basys3_idelay.v
        --output ${CMAKE_CURRENT_BINARY_DIR}/serdes_basys3_idelay_${data_width}_${data_rate_lower}.v
        --data_width ${data_width}
        --data_rate ${data_rate}
      DEPENDS ${PYTHON3} ${PYTHON3_TARGET} generate_tests.py ${CMAKE_CURRENT_SOURCE_DIR}/serdes_basys3_idelay.v
    )

  add_file_target(FILE serdes_basys3_${data_width}_${data_rate_lower}.v GENERATED)
  add_file_target(FILE serdes_basys3_idelay_${data_width}_${data_rate_lower}.v GENERATED)

  add_fpga_target(
    NAME serdes_basys3_${data_width}_${data_rate_lower}
    BOARD basys3-full
    SOURCES
      serdes_basys3_${data_width}_${data_rate_lower}.v
      serdes_test.v
    INPUT_IO_FILE basys3.pcf
    EXPLICIT_ADD_FILE_TARGET
    )

  add_fpga_target(
    NAME serdes_basys3_idelay_${data_width}_${data_rate_lower}
    BOARD basys3-full
    SOURCES
      serdes_basys3_idelay_${data_width}_${data_rate_lower}.v
      serdes_test_idelay.v
    INPUT_IO_FILE basys3.pcf
    EXPLICIT_ADD_FILE_TARGET
    )

  add_vivado_target(
    NAME serdes_basys3_${data_width}_${data_rate_lower}_vivado
    PARENT_NAME serdes_basys3_${data_width}_${data_rate_lower}
    )

  add_vivado_target(
    NAME serdes_basys3_idelay_${data_width}_${data_rate_lower}_vivado
    PARENT_NAME serdes_basys3_idelay_${data_width}_${data_rate_lower}
    )

  add_dependencies(all_serdes_test
    serdes_basys3_${data_width}_${data_rate_lower}_bin
    serdes_basys3_idelay_${data_width}_${data_rate_lower}_bin
  )

endfunction()

#SDR
serdes_test(2 SDR)
serdes_test(3 SDR)
serdes_test(4 SDR)
serdes_test(5 SDR)
serdes_test(6 SDR)
serdes_test(7 SDR)
serdes_test(8 SDR)

#DDR
serdes_test(4 DDR)
serdes_test(6 DDR)
serdes_test(8 DDR)
