# This CMake include defines the following functions:
#
# * ADD_SV2V_TARGET - Converts SystemVerilog sources to Verilog using sv2v

function(ADD_SV2V_TARGET)
  # ~~~
  # ADD_SV2V_TARGET(
  #    NAME <name>
  #    SOURCES <source list>
  #    FLAGS <flags>
  #
  # ADD_SV2V_TARGET is used for converting SystemVerilog SOURCES to Verilog.
  # FLAGS is a string with the flags that are passed to the sv2v during the conversion.
  #
  # Targets  generated:
  # * <name>_sv2v - Output sv2v file in a Verilog format.
  #
  # Output files:
  #
  # * <name>_sv2v.v - Output Verilog file
  # * <name>_sv2v.v.log - Log file with errors and warnings during the sv2v conversion
  #
  # Outputs for this target will be located in the ${CMAKE_CURRENT_BINARY_DIR}
  # ~~~

  set(oneValueArgs NAME)
  set(multiValueArgs SOURCES FLAGS)
  cmake_parse_arguments(
    ADD_SV2V_TARGET
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    "${ARGN}"
  )

  # Create a dependency list

  set(SOURCES_DEPS "")
  foreach(SRC ${ADD_SV2V_TARGET_SOURCES})
    append_file_dependency(SOURCES_DEPS ${SRC})
  endforeach()

  # sv2v conversion

  set(NAME ${ADD_SV2V_TARGET_NAME})
  set(SOURCES ${ADD_SV2V_TARGET_SOURCES})
  set(FLAGS ${ADD_SV2V_TARGET_FLAGS})
  set(OUT_FILE ${CMAKE_CURRENT_BINARY_DIR}/${NAME}_sv2v.v)

  add_custom_command(
    OUTPUT ${OUT_FILE}
    DEPENDS ${SOURCES_DEPS}
    COMMAND
      ${CMAKE_COMMAND} -E env
      zachjs-sv2v ${FLAGS} ${SOURCES} > ${OUT_FILE} 2> ${OUT_FILE}.log
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    VERBATIM
  )
  add_custom_target(${NAME}_sv2v DEPENDS ${OUT_FILE})

  add_file_target(FILE ${NAME}_sv2v.v GENERATED)
endfunction()
