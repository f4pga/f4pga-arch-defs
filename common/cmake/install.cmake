function(PARSE_INSTALL_LISTS)
  # ~~~
  # PARSE_INSTALL_LISTS
  #
  # Parses lists of architectures and devices to be installed as given by a
  # user. Converts them to CMake lists and sets them in the global scope.
  #
  # There are INSTALL_* and NO_INSTALL_* global variables. Each of them holds
  # a comma-separated list of entities to install and not to install.
  #
  # When none of these two is set then all entities are considered for installation
  # If INSTALL_* is set then only entities present there are to be installed.
  # The NO_INSTALL_* list contains entities that should NOT be installed.
  #
  # For example: If one wants to install only the Xilinx 7-series familly one
  # would run the CMake with -DINSTALL_FAMILIES=xc7. If one wants to install
  # all supported families BUT Xilinx 7-series one would do -DNO_INSTALL_FAMILIES=xc7
  # The same principle applies to the architecture and the device lists.

  # Device lists
  if (NOT "${INSTALL_DEVICES}" STREQUAL "")
    string(REPLACE "," ";" DEVICE_INSTALL_LIST ${INSTALL_DEVICES})
  else ()
    set(DEVICE_INSTALL_LIST "")
  endif ()
  set(SYMBIFLOW_DEVICE_INSTALL_LIST ${DEVICE_INSTALL_LIST} CACHE INTERNAL "List of devices to install" FORCE)

  if (NOT "${NO_INSTALL_DEVICES}" STREQUAL "")
    string(REPLACE "," ";" DEVICE_NO_INSTALL_LIST ${NO_INSTALL_DEVICES})
  else ()
    set(DEVICE_NO_INSTALL_LIST "")
  endif ()
  set(SYMBIFLOW_DEVICE_NO_INSTALL_LIST ${DEVICE_NO_INSTALL_LIST} CACHE INTERNAL "List of devices not to install" FORCE)

  # Architecture lists
  if (NOT "${INSTALL_ARCHS}" STREQUAL "")
    string(REPLACE "," ";" ARCH_INSTALL_LIST ${INSTALL_ARCHS})
  else ()
    set(ARCH_INSTALL_LIST "")
  endif ()
  set(SYMBIFLOW_ARCH_INSTALL_LIST ${ARCH_INSTALL_LIST} CACHE INTERNAL "List of architectures to install" FORCE)

  if (NOT "${NO_INSTALL_ARCHS}" STREQUAL "")
    string(REPLACE "," ";" ARCH_NO_INSTALL_LIST ${NO_INSTALL_ARCHS})
  else ()
    set(ARCH_NO_INSTALL_LIST "")
  endif ()
  set(SYMBIFLOW_ARCH_NO_INSTALL_LIST ${ARCH_NO_INSTALL_LIST} CACHE INTERNAL "List of acritectures not to install" FORCE)

  # Family lists
  if (NOT "${INSTALL_FAMILIES}" STREQUAL "")
    string(REPLACE "," ";" FAMILY_INSTALL_LIST ${INSTALL_FAMILIES})
  else ()
    set(FAMILY_INSTALL_LIST "")
  endif ()
  set(SYMBIFLOW_FAMILY_INSTALL_LIST ${FAMILY_INSTALL_LIST} CACHE INTERNAL "List of device families to install" FORCE)

  if (NOT "${NO_INSTALL_FAMILIES}" STREQUAL "")
    string(REPLACE "," ";" FAMILY_NO_INSTALL_LIST ${NO_INSTALL_FAMILIES})
  else ()
    set(FAMILY_NO_INSTALL_LIST "")
  endif ()
  set(SYMBIFLOW_FAMILY_NO_INSTALL_LIST ${FAMILY_NO_INSTALL_LIST} CACHE INTERNAL "List of families not to install" FORCE)

endfunction()


function(CHECK_INSTALL_LIST)
  # ~~~
  # CHECK_INSTALL_LIST
  #  <entity>
  #  <variable>
  #  <install list>
  #  <no-install list>
  #
  # Checks if the given device is to be installed by examining it through
  # installation lists. Sets the given variable to TRUE or FALSE
  # ~~~

  set(options)
  set(oneValueArgs ENTITY VAR)
  set(multiValueArgs INSTALL_LIST NO_INSTALL_LIST)
  cmake_parse_arguments(
    CHECK_INSTALL_LIST
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(ENTITY          ${CHECK_INSTALL_LIST_ENTITY})
  set(INSTALL_LIST    ${CHECK_INSTALL_LIST_INSTALL_LIST})
  set(NO_INSTALL_LIST ${CHECK_INSTALL_LIST_NO_INSTALL_LIST})
  set(VAR             ${CHECK_INSTALL_LIST_VAR})

  # Initially accept
  set(RET TRUE)

  # The install list provided, check against it. No install list means accept all
  if (INSTALL_LIST)
    if (NOT "${ENTITY}" IN_LIST INSTALL_LIST)
      message(DEBUG "INSTALL: Skipping entity '${ENTITY}' as not on the install list")
      set(RET FALSE)
    endif ()
  endif ()

  # The no-install list provided, check against it
  if (NO_INSTALL_LIST)
    if ("${ENTITY}" IN_LIST NO_INSTALL_LIST)
      message(DEBUG "INSTALL: Skipping entity '${ENTITY}' as on the no-install list")
      set(RET FALSE)
    endif ()
  endif ()

  # Return
  set(${VAR} ${RET} PARENT_SCOPE)

endfunction()

# =============================================================================

function(CHECK_ARCH_INSTALL ARCH VAR)
  # ~~~
  # CHECK_ARCH_INSTALL
  #  <arch>
  #  <variable>
  #
  # Checks if the given architecture is to be installed.
  # ~~~

  get_target_property_required(FAMILY ${ARCH} FAMILY)

  # Initially accept
  set(RET TRUE)

  # Check the arch against the list
  check_install_list(
    ENTITY          ${ARCH}
    INSTALL_LIST    ${SYMBIFLOW_ARCH_INSTALL_LIST}
    NO_INSTALL_LIST ${SYMBIFLOW_ARCH_NO_INSTALL_LIST}
    VAR             RET
  )

  if(NOT ${RET})
    message(STATUS "INSTALL: Skipping architecture '${ARCH}' due to installation list")
    set(${VAR} FALSE PARENT_SCOPE)
    return()
  endif()

  # Check the individual property of the arch
  get_target_property_required(NO_INSTALL ${ARCH} NO_INSTALL)
  if(${NO_INSTALL})
    message(STATUS "INSTALL: Skipping architecture '${ARCH}' as marked as NO_INSTALL")
    set(RET FALSE)
  endif()

  # Check the family against the list
  check_install_list(
    ENTITY          ${FAMILY}
    INSTALL_LIST    ${SYMBIFLOW_FAMILY_INSTALL_LIST}
    NO_INSTALL_LIST ${SYMBIFLOW_FAMILY_NO_INSTALL_LIST}
    VAR             RET
  )

  if(NOT ${RET})
    message(STATUS "INSTALL: Skipping architecture '${ARCH}' due to its family '${FAMILY}' (not) on an installation list")
    set(${VAR} FALSE PARENT_SCOPE)
    return()
  endif()

  # Get list of devices of the given architecture
  get_target_property_required(DEVICES ${ARCH} DEVICES)

  # No devices, don't install this arch
  if (NOT DEVICES)
    message(STATUS "INSTALL: Skipping architecture '${ARCH}' as there are no devices")
    set(${VAR} FALSE PARENT_SCOPE)
    return()
  endif ()

  # Examine each device
  set(RET FALSE)
  foreach(DEVICE ${DEVICES})

    # Check the device against the list
    check_install_list(
      ENTITY          ${DEVICE}
      INSTALL_LIST    ${SYMBIFLOW_DEVICE_INSTALL_LIST}
      NO_INSTALL_LIST ${SYMBIFLOW_DEVICE_NO_INSTALL_LIST}
      VAR             RET
    )
  
    # Check the individual property of the device
    if(${RET})
      get_target_property_required(NO_INSTALL ${DEVICE} NO_INSTALL)
      if(NOT ${NO_INSTALL})
        break()
      endif()
    endif()

  endforeach()

  if(NOT RET)
    message(STATUS "INSTALL: Skipping architecture '${ARCH}' as none of its devices it to be installed")
  endif()

  # Return
  set(${VAR} ${RET} PARENT_SCOPE)

endfunction()


function(CHECK_DEVICE_INSTALL DEVICE VAR)
  # ~~~
  # CHECK_DEVICE_INSTALL
  #  <device>
  #  <variable>
  #
  # Checks if the given device is to be installed by examining it and its
  # architecture + family through the installation lists. Also checks individual
  # NO_INSTALL properties of the device and its architecture
  # ~~~

  get_target_property_required(ARCH   ${DEVICE} ARCH)
  get_target_property_required(FAMILY ${ARCH}   FAMILY)

  # Initially accept
  set(RET TRUE)

  # Check the device against the list
  check_install_list(
    ENTITY          ${DEVICE}
    INSTALL_LIST    ${SYMBIFLOW_DEVICE_INSTALL_LIST}
    NO_INSTALL_LIST ${SYMBIFLOW_DEVICE_NO_INSTALL_LIST}
    VAR             RET
  )

  if(NOT ${RET})
    message(STATUS "INSTALL: Skipping device '${DEVICE}' due to installation list")
    set(${VAR} FALSE PARENT_SCOPE)
    return()
  endif()

  # Check the individual property of the device
  get_target_property_required(NO_INSTALL ${DEVICE} NO_INSTALL)
  if(${NO_INSTALL})
    message(STATUS "INSTALL: Skipping device '${DEVICE}' as marked as NO_INSTALL")
    set(RET FALSE)
  endif()

  # Check the architecture against the list
  check_install_list(
    ENTITY          ${ARCH}
    INSTALL_LIST    ${SYMBIFLOW_ARCH_INSTALL_LIST}
    NO_INSTALL_LIST ${SYMBIFLOW_ARCH_NO_INSTALL_LIST}
    VAR             RET
  )

  if(NOT ${RET})
    message(STATUS "INSTALL: Skipping device '${DEVICE}' due to its architecture '${ARCH}' (not) on an installation list")
    set(${VAR} FALSE PARENT_SCOPE)
    return()
  endif()

  # Check the individual property of the architecture
  get_target_property_required(NO_INSTALL ${ARCH} NO_INSTALL)
  if(${NO_INSTALL})
    message(STATUS "INSTALL: Skipping device '${DEVICE}' as its architecture '${ARCH}' is marked as NO_INSTALL")
    set(RET FALSE)
  endif()

  # Check the family against the list
  check_install_list(
    ENTITY          ${FAMILY}
    INSTALL_LIST    ${SYMBIFLOW_FAMILY_INSTALL_LIST}
    NO_INSTALL_LIST ${SYMBIFLOW_FAMILY_NO_INSTALL_LIST}
    VAR             RET
  )

  if(NOT ${RET})
    message(STATUS "INSTALL: Skipping device '${DEVICE}' due to its family '${FAMILY}' (not) on an installation list")
    set(${VAR} FALSE PARENT_SCOPE)
    return()
  endif()

  # Return
  set(${VAR} ${RET} PARENT_SCOPE)

endfunction()

# =============================================================================

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

  get_target_property(LIMIT_GRAPH_TO_DEVICE ${DEVICE_TYPE} LIMIT_GRAPH_TO_DEVICE)
  if(LIMIT_GRAPH_TO_DEVICE OR LIMIT_GRAPH_TO_DEVICE STREQUAL "LIMIT_GRAPH_TO_DEVICE-NOTFOUND")
    message(STATUS "Graph limited to a sub-area of the device. Skipping files installation for ${DEVICE}-${PACKAGE} type: ${DEVICE_TYPE}")
    return()
  endif()

  # Check if the device should be installed
  check_device_install(${DEVICE} DO_INSTALL)
  if (NOT DO_INSTALL)
    return()
  endif ()

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

  get_target_property(VPR_GRID_MAP_FILE ${DEVICE_TYPE} VPR_GRID_MAP)
  if(NOT ${VPR_GRID_MAP_FILE} STREQUAL "VPR_GRID_MAP_FILE-NOTFOUND")
    list(APPEND INSTALL_FILES ${VPR_GRID_MAP_FILE})
  endif()

  # Extra files for the device (common to all packages)
  get_target_property(EXTRA_FILES ${DEVICE} EXTRA_INSTALL_FILES)
  if(NOT ${EXTRA_FILES} MATCHES ".*-NOTFOUND" AND NOT ${EXTRA_FILES} STREQUAL "")
    list(APPEND INSTALL_FILES ${EXTRA_FILES})
  endif()

  # Generate installation target for the files
  foreach(FILE ${INSTALL_FILES})
    get_file_location(SRC_FILE ${FILE})
    get_filename_component(SRC_FILE_REAL ${SRC_FILE} REALPATH)
    get_filename_component(FILE_NAME ${SRC_FILE} NAME)
    append_file_dependency(DEPS ${FILE})
    # Create a custom target and add it to ALL target.
    # We do this because install targets depend only on
    # all.
    add_custom_target(
      "INSTALL_${DEVICE}_${PACKAGE}_${FILE_NAME}"
      ALL
      DEPENDS ${DEPS})
    install(FILES ${SRC_FILE_REAL}
      DESTINATION "share/symbiflow/arch/${DEVICE}_${PACKAGE}"
      RENAME ${FILE_NAME}
    )
  endforeach()

endfunction()

