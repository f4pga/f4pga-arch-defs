add_file_target(FILE comparator.v SCANNER_TYPE verilog)
add_file_target(FILE lfsr.v SCANNER_TYPE verilog)
add_file_target(FILE oserdes_test.v SCANNER_TYPE verilog)
add_file_target(FILE basys3.pcf)

add_custom_target(all_oserdes_test)
add_dependencies(all_xc7_tests all_oserdes_test)

function(oserdes_test data_width data_rate)
  string(TOLOWER ${data_rate} data_rate_lower)

  add_custom_command(
      OUTPUT oserdes_basys3_${data_width}_${data_rate_lower}.v
      COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/generate.py
        --input ${CMAKE_CURRENT_SOURCE_DIR}/oserdes_basys3.v
        --output ${CMAKE_CURRENT_BINARY_DIR}/oserdes_basys3_${data_width}_${data_rate_lower}.v
        --data_width ${data_width}
        --data_rate ${data_rate}
      DEPENDS ${PYTHON3} ${PYTHON3_TARGET} generate.py
    )

  add_file_target(FILE oserdes_basys3_${data_width}_${data_rate_lower}.v GENERATED)

  add_fpga_target(
    NAME oserdes_basys3_${data_width}_${data_rate_lower}
    BOARD basys3-full
    SOURCES
      oserdes_basys3_${data_width}_${data_rate_lower}.v
      oserdes_test.v
      lfsr.v
      comparator.v
    INPUT_IO_FILE basys3.pcf
    EXPLICIT_ADD_FILE_TARGET
    )

  add_vivado_target(
    NAME oserdes_basys3_${data_width}_${data_rate_lower}_vivado
    PARENT_NAME oserdes_basys3_${data_width}_${data_rate_lower}
    )

  add_dependencies(all_oserdes_test oserdes_basys3_${data_width}_${data_rate_lower}_bin)

endfunction()

#SDR
oserdes_test(2 SDR)
oserdes_test(3 SDR)
oserdes_test(4 SDR)
oserdes_test(5 SDR)
oserdes_test(6 SDR)
oserdes_test(7 SDR)
oserdes_test(8 SDR)

#DDR
oserdes_test(4 DDR)
oserdes_test(6 DDR)
oserdes_test(8 DDR)
