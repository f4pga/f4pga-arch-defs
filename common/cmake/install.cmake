function(INSTALL_DEVICE_FILES)
  # ~~~
  # INSTALL_DEVICE_FILES(
  #   DEVICE <device>
  #   PACKAGE <package>
  #   )
  # ~~~
  #
  set(options)
  set(oneValueArgs DEVICE PACKAGE)
  set(multiValueArgs)
  cmake_parse_arguments(
    INSTALL_DEVICE_FILES
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(DEVICE ${INSTALL_DEVICE_FILES_DEVICE})
  set(PACKAGE ${INSTALL_DEVICE_FILES_PACKAGE})
  set(INSTALL_DEST "${CMAKE_INSTALL_PREFIX}/share/arch/${DEVICE}_${PACKAGE}")

  add_custom_target(${DEVICE}_${PACKAGE}_ARCH_INSTALL_DIR
                    COMMAND ${CMAKE_COMMAND} -E make_directory ${INSTALL_DEST})

  set(INSTALL_FILES)

  # Get files to be installed
  get_target_property_required(HAS_LOOKAHEAD ${DEVICE} "${PACKAGE}_HAS_LOOKAHEAD_CACHE")
  get_target_property_required(HAS_PLACE_DELAY ${DEVICE} "${PACKAGE}_HAS_PLACE_DELAY_CACHE")
  if(${HAS_LOOKAHEAD})
    get_target_property(LOOKAHEAD_FILE ${DEVICE} ${PACKAGE}_LOOKAHEAD_FILE)
    list(APPEND INSTALL_FILES ${LOOKAHEAD_FILE})
  endif()
  if(${HAS_PLACE_DELAY})
    get_target_property(PLACE_DELAY_FILE ${DEVICE} ${PACKAGE}_PLACE_DELAY_FILE)
    list(APPEND INSTALL_FILES ${PLACE_DELAY_FILE})
  endif()
  get_target_property_required(RR_GRAPH_FILE ${DEVICE} ${PACKAGE}_OUT_RRXML_REAL)
  list(APPEND INSTALL_FILES ${RR_GRAPH_FILE})

  # Generate installation target for the files
  foreach(FILE ${INSTALL_FILES})
    get_file_location(SRC_FILE ${FILE})
    get_filename_component(FILE_NAME ${SRC_FILE} NAME)
    set(DST_FILE "${INSTALL_DEST}/${FILE_NAME}")
    add_custom_command(
      OUTPUT ${DST_FILE}
      COMMAND ${CMAKE_COMMAND} -E copy
      ${SRC_FILE}
      ${DST_FILE}
      DEPENDS ${SRC_FILE} ${DEVICE}_${PACKAGE}_ARCH_INSTALL_DIR
    )
    add_custom_target(
      "INSTALL_${DEVICE}_${PACKAGE}_${FILE_NAME}"
      DEPENDS ${DST_FILE})

    add_dependencies(install_architectures "INSTALL_${DEVICE}_${PACKAGE}_${FILE_NAME}")
  endforeach()

endfunction()
