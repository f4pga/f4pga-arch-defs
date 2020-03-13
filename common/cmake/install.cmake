function(INSTALL_DEVICE_FILES)
  # ~~~
  # INSTALL_DEVICE_FILES(
  #   DEVICE <device>
  #   PACKAGE <package>
  #   DEVICE_TYPE <device_type>
  #   )
  # ~~~
  #
  set(options)
  set(oneValueArgs DEVICE PACKAGE DEVICE_TYPE)
  set(multiValueArgs)
  cmake_parse_arguments(
    INSTALL_DEVICE_FILES
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(DEVICE ${INSTALL_DEVICE_FILES_DEVICE})
  set(DEVICE_TYPE ${INSTALL_DEVICE_FILES_DEVICE_TYPE})
  set(PACKAGE ${INSTALL_DEVICE_FILES_PACKAGE})

  get_target_property(USE_ROI ${DEVICE_TYPE} USE_ROI)
  if(USE_ROI OR USE_ROI STREQUAL "USE_ROI-NOTFOUND")
    message(STATUS "Skipping device files installation for ${DEVICE}-${PACKAGE} type: ${DEVICE_TYPE}")
    return()
  endif()

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
  get_target_property_required(RR_GRAPH_FILE ${DEVICE} ${PACKAGE}_OUT_RRBIN_REAL)
  list(APPEND INSTALL_FILES ${RR_GRAPH_FILE})

  get_target_property_required(ARCH_FILE ${DEVICE_TYPE} DEVICE_MERGED_FILE)
  list(APPEND INSTALL_FILES ${ARCH_FILE})

  get_target_property(CHANNELS_DB_FILE ${DEVICE_TYPE} CHANNELS_DB)
  if(NOT ${CHANNELS_DB_FILE} STREQUAL "CHANNELS_DB_FILE-NOTFOUND")
    list(APPEND INSTALL_FILES ${CHANNELS_DB_FILE})
  endif()

  # Generate installation target for the files
  foreach(FILE ${INSTALL_FILES})
    get_file_location(SRC_FILE ${FILE})
    get_filename_component(FILE_NAME ${SRC_FILE} NAME)
    append_file_dependency(DEPS ${FILE})
    # Create a custom target and add it to ALL target.
    # We do this because install targets depend only on
    # all.
    add_custom_target(
      "INSTALL_${DEVICE}_${PACKAGE}_${FILE_NAME}"
      ALL
      DEPENDS ${DEPS})
    install(FILES ${SRC_FILE}
      DESTINATION "share/arch/${DEVICE}_${PACKAGE}")
  endforeach()

endfunction()

