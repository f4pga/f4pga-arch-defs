add_file_target(FILE simpleuart.v SCANNER_TYPE verilog)
add_file_target(FILE scalable_proc.v SCANNER_TYPE verilog)
add_file_target(FILE processing_unit.v SCANNER_TYPE verilog)
add_file_target(FILE basys3.pcf)
add_file_target(FILE basys3.xdc)

get_target_property_required(PYTHON3 env PYTHON3)

# Generate ROM veilog modules with different styles of implementation
set(ROM_FILE_BRAM rom_bram.v)
set(ROM_FILE_BRAM36 rom_bram36.v)
set(ROM_FILE_DRAM rom_dram.v)

add_file_target(FILE ${ROM_FILE_BRAM} GENERATED)
add_file_target(FILE ${ROM_FILE_BRAM36} GENERATED)
add_file_target(FILE ${ROM_FILE_DRAM} GENERATED)

add_custom_command(
    OUTPUT ${ROM_FILE_BRAM}
    COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/utils/rom_generator.py --rom-style bram >${ROM_FILE_BRAM}
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/utils/rom_generator.py ${PYTHON3}
)

add_custom_command(
    OUTPUT ${ROM_FILE_BRAM36}
    COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/utils/rom_generator.py --rom-style bram36 >${ROM_FILE_BRAM36}
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/utils/rom_generator.py ${PYTHON3}
)

add_custom_command(
    OUTPUT ${ROM_FILE_DRAM}
    COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/utils/rom_generator.py --rom-style dram64 >${ROM_FILE_DRAM}
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/utils/rom_generator.py ${PYTHON3}
)

if (NOT DEFINED ENV{CI} OR NOT $ENV{CI})

function(SCALABLE_PROC)
  set(options)
  set(
  oneValueArgs
    TOP_FILE
    BOARD
    INPUT_IO_FILE
    INPUT_XDC_FILE
    ROM_STYLE
    MAX_PROC

  )
  set(multiValueArgs)
  cmake_parse_arguments(
      SCALABLE_PROC
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(ROM_STYLE ${SCALABLE_PROC_ROM_STYLE})
  set(ROM_FILE rom_${ROM_STYLE}.v)

  foreach(NUM_PROCESSING_UNITS RANGE 1 ${SCALABLE_PROC_MAX_PROC})
    set(VERILOG_TOP basys3_top_${ROM_STYLE}_n${NUM_PROCESSING_UNITS}.v)
    set(TOP_NAME top_${ROM_STYLE}_n${NUM_PROCESSING_UNITS})

    add_custom_command(
      OUTPUT ${VERILOG_TOP}
      COMMAND ${PYTHON3}
        ${CMAKE_CURRENT_SOURCE_DIR}/parametrize.py
          --num-processing-units ${NUM_PROCESSING_UNITS}
          --template ${CMAKE_CURRENT_SOURCE_DIR}/${SCALABLE_PROC_TOP_FILE} > ${VERILOG_TOP}
      DEPENDS
        ${CMAKE_CURRENT_SOURCE_DIR}/parametrize.py
        ${CMAKE_CURRENT_SOURCE_DIR}/${SCALABLE_PROC_TOP_FILE}
        ${PYTHON3}
      )

   add_file_target(
    FILE ${VERILOG_TOP}
    GENERATED
    )

   add_fpga_target(
     NAME ${TOP_NAME}
     BOARD ${SCALABLE_PROC_BOARD}
     INPUT_IO_FILE ${SCALABLE_PROC_INPUT_IO_FILE}
     INPUT_XDC_FILE ${SCALABLE_PROC_INPUT_XDC_FILE}
     SOURCES
       ${ROM_FILE} processing_unit.v simpleuart.v scalable_proc.v
       ${VERILOG_TOP}
     EXPLICIT_ADD_FILE_TARGET
     )
  endforeach()
endfunction()

# Generate targets for the design
scalable_proc(
  TOP_FILE basys3_top.v
  BOARD basys3
  INPUT_IO_FILE basys3.pcf
  INPUT_XDC_FILE basys3.xdc
  ROM_STYLE bram
  MAX_PROC 8
)

scalable_proc(
  TOP_FILE basys3_top.v
  BOARD basys3
  INPUT_IO_FILE basys3.pcf
  INPUT_XDC_FILE basys3.xdc
  ROM_STYLE bram36
  MAX_PROC 8
)

scalable_proc(
  TOP_FILE basys3_top.v
  BOARD basys3
  INPUT_IO_FILE basys3.pcf
  INPUT_XDC_FILE basys3.xdc
  ROM_STYLE dram
  MAX_PROC 3
)

add_vivado_target(
    NAME top_bram_n3_vivado
    PARENT_NAME top_bram_n3
    CLOCK_PINS clk
    CLOCK_PERIODS 10.0
    )

add_vivado_target(
    NAME top_bram36_n3_vivado
    PARENT_NAME top_bram36_n3
    CLOCK_PINS clk
    CLOCK_PERIODS 10.0
    )

add_vivado_target(
    NAME top_dram_n3_vivado
    PARENT_NAME top_dram_n3
    CLOCK_PINS clk
    CLOCK_PERIODS 10.0
    )

endif (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
