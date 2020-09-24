get_filename_component(IBEX_DIR ${symbiflow-arch-defs_SOURCE_DIR}/third_party/ibex ABSOLUTE)

set(SV2V_ROM_INIT_FILE led.vmem)
set(SV2V_IBEX_FLAGS --define=RegFile=ibex_pkg::RegFileFF --define=SRAMInitFile=${SV2V_ROM_INIT_FILE})

# Get the list of source files used by the fusesoc to build the Ibex example

execute_process(
  COMMAND
    python3 ${CMAKE_CURRENT_SOURCE_DIR}/generate.py
      --only-deps
      --root_source_dir ${symbiflow-arch-defs_SOURCE_DIR}
      --current_binary_dir ${CMAKE_CURRENT_BINARY_DIR}
  OUTPUT_VARIABLE FILES_FROM_GENERATE_SCRIPT
)

# Sort the file list into sources and includes

set(SOURCE_FILE_LIST "")
set(INCLUDE_FILE_LIST "")

string(REPLACE "\n" ";" FILE_LIST "${FILES_FROM_GENERATE_SCRIPT}")
foreach(FILE_NAME ${FILE_LIST})
  get_filename_component(FILE_EXT ${FILE_NAME} EXT)
  if (${FILE_EXT} STREQUAL ".sv")
    list(APPEND SOURCE_FILE_LIST ${FILE_NAME})
  elseif (${FILE_EXT} STREQUAL ".svh")
    list(APPEND INCLUDE_FILE_LIST ${FILE_NAME})
  endif()
endforeach()

# Add a command for generating the Ibex source files in the build directory

add_custom_command(
  OUTPUT ${SOURCE_FILE_LIST} ${INCLUDE_FILE_LIST}
  COMMAND
    python3 ${CMAKE_CURRENT_SOURCE_DIR}/generate.py
        --root_source_dir ${symbiflow-arch-defs_SOURCE_DIR}
        --current_binary_dir ${CMAKE_CURRENT_BINARY_DIR}
  DEPENDS ${PYTHON3} ${IBEX_DIR}
)

# Create file targets

add_file_target(FILE ${SV2V_ROM_INIT_FILE})

foreach(INC ${INCLUDE_FILE_LIST})
  add_file_target(FILE ${INC} GENERATED)
endforeach()

foreach(SRC ${SOURCE_FILE_LIST})
  add_file_target(FILE ${SRC} GENERATED)
  get_file_target(TARGET ${SRC})
  set_target_properties(${TARGET} PROPERTIES INCLUDE_FILES "${INCLUDE_FILE_LIST};${SV2V_ROM_INIT_FILE}")
endforeach()

# sv2v conversion

add_sv2v_target(
  NAME ibex
  SOURCES ${SOURCE_FILE_LIST}
  FLAGS ${SV2V_IBEX_FLAGS}
)

# Arty Board
#
add_file_target(FILE pins_artya7.sdc)
add_file_target(FILE pins_artya7.pcf)

add_fpga_target(
  NAME ibex_arty
  BOARD arty-full
  TOP top_artya7
  SOURCES ibex_sv2v.v
  INPUT_IO_FILE pins_artya7.pcf
  SDC_FILE pins_artya7.sdc
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
  NAME ibex_arty_vivado
  PARENT_NAME ibex_arty
)

# Nexys Video Board

add_file_target(FILE pins_nexys_video.sdc)
add_file_target(FILE pins_nexys_video.pcf)

add_fpga_target(
  NAME ibex_nexys_video
  BOARD nexys_video-mid
  TOP top_artya7
  SOURCES ibex_sv2v.v
  INPUT_IO_FILE pins_nexys_video.pcf
  SDC_FILE pins_nexys_video.sdc
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
  NAME ibex_nexys_video_vivado
  PARENT_NAME ibex_nexys_video
)
