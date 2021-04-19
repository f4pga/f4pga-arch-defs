function(DEFINE_QL_TOOLCHAIN_TARGET)
  set(options)
  set(oneValueArgs FAMILY ARCH CONV_SCRIPT SYNTH_SCRIPT ROUTE_CHAN_WIDTH CELLS_SIM)
  set(multiValueArgs VPR_ARCH_ARGS)

  cmake_parse_arguments(
    DEFINE_QL_TOOLCHAIN_TARGET
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    "${ARGN}"
  )

  set(FAMILY ${DEFINE_QL_TOOLCHAIN_TARGET_FAMILY})
  set(ARCH ${DEFINE_QL_TOOLCHAIN_TARGET_ARCH})
  set(VPR_ARCH_ARGS ${DEFINE_QL_TOOLCHAIN_TARGET_VPR_ARCH_ARGS})
  set(ROUTE_CHAN_WIDTH ${DEFINE_QL_TOOLCHAIN_TARGET_ROUTE_CHAN_WIDTH})

  # Check if the architecture and family should be installed
  check_arch_install(${ARCH} DO_INSTALL)
  if (NOT DO_INSTALL)
    message(STATUS "Skipping installation of toolchain for arch '${ARCH}' family '${FAMILY}'")
    return()
  endif ()

  set(WRAPPERS env symbiflow_generate_constraints symbiflow_pack symbiflow_place symbiflow_route symbiflow_synth ql_symbiflow symbiflow_analysis symbiflow_repack)

  # Export VPR arguments
  list(JOIN VPR_BASE_ARGS " " VPR_BASE_ARGS)
  string(JOIN " " VPR_ARGS ${VPR_BASE_ARGS} "--route_chan_width ${ROUTE_CHAN_WIDTH}" ${VPR_ARCH_ARGS})

  set(VPR_CONFIG_TEMPLATE "${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/common/toolchain_wrappers/vpr_config.sh")
  set(VPR_CONFIG "${CMAKE_CURRENT_BINARY_DIR}/vpr_config.sh")
  configure_file(${VPR_CONFIG_TEMPLATE} "${VPR_CONFIG}" @ONLY)

  set(VPR_COMMON "${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/common/toolchain_wrappers/vpr_common")

  # Add cells.sim to all deps, so it is installed with make install
  get_file_target(CELLS_SIM_TARGET ${DEFINE_QL_TOOLCHAIN_TARGET_CELLS_SIM})
  add_custom_target(
    "DEVICE_INSTALL_${CELLS_SIM_TARGET}"
    ALL
    DEPENDS ${DEFINE_QL_TOOLCHAIN_TARGET_CELLS_SIM}
    )

  set(TOOLCHAIN_WRAPPERS)
  foreach(WRAPPER ${WRAPPERS})
    set(WRAPPER_PATH "${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/common/toolchain_wrappers/${WRAPPER}")
    list(APPEND TOOLCHAIN_WRAPPERS ${WRAPPER_PATH})
  endforeach()

  install(FILES ${TOOLCHAIN_WRAPPERS} ${VPR_COMMON}
          DESTINATION bin
          PERMISSIONS WORLD_EXECUTE WORLD_READ OWNER_WRITE OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE)

  install(FILES ${VPR_CONFIG}
          DESTINATION share/symbiflow/scripts/${FAMILY})

  # Example design to run through the flow
  install(FILES ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/${FAMILY}/tests/counter_16bit/*.v
	  DESTINATION share/symbiflow/tests/counter_16bit
	   PERMISSIONS WORLD_READ OWNER_WRITE OWNER_READ GROUP_READ)
  
  # install python scripts
  install(FILES ${symbiflow-arch-defs_SOURCE_DIR}/utils/split_inouts.py
          DESTINATION bin/python
          PERMISSIONS WORLD_EXECUTE WORLD_READ OWNER_WRITE OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE)

  install(FILES ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/common/utils/pinmap_parse.py
          DESTINATION bin/python
          PERMISSIONS WORLD_READ OWNER_WRITE OWNER_READ GROUP_READ)

  install(FILES ${symbiflow-arch-defs_SOURCE_DIR}/utils/vpr_io_place.py
      DESTINATION bin/python
          PERMISSIONS WORLD_READ OWNER_WRITE OWNER_READ GROUP_READ)

  install(FILES ${symbiflow-arch-defs_SOURCE_DIR}/utils/vpr_place_constraints.py
          DESTINATION bin/python
          PERMISSIONS WORLD_READ OWNER_WRITE OWNER_READ GROUP_READ)

  install(FILES ${symbiflow-arch-defs_SOURCE_DIR}/utils/eblif.py
          DESTINATION bin/python
          PERMISSIONS WORLD_READ OWNER_WRITE OWNER_READ GROUP_READ)

  install(FILES ${symbiflow-arch-defs_SOURCE_DIR}/utils/lib/parse_pcf.py
          DESTINATION bin/python/lib
          PERMISSIONS WORLD_READ OWNER_WRITE OWNER_READ GROUP_READ)

  # install the repacker
  set(REPACKER_FILES
    arch_xml_utils.py
    block_path.py
    eblif_netlist.py
    netlist_cleaning.py
    packed_netlist.py
    pb_rr_graph_netlist.py
    pb_rr_graph.py
    pb_rr_graph_router.py
    pb_type.py
    repack.py
  )
  foreach(NAME ${REPACKER_FILES})
    install(FILES ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/${FAMILY}/utils/repacker/${NAME}
            DESTINATION bin/python/repacker
            PERMISSIONS WORLD_READ OWNER_WRITE OWNER_READ GROUP_READ)
  endforeach()

  # install techmap
  install(DIRECTORY ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/${FAMILY}/techmap/.
          DESTINATION share/symbiflow/techmaps/${FAMILY}
          FILES_MATCHING PATTERN *.v)

  install(FILES ${DEFINE_QL_TOOLCHAIN_TARGET_CELLS_SIM}
          DESTINATION share/symbiflow/techmaps/${FAMILY})

  # install Yosys scripts
  install(FILES ${DEFINE_QL_TOOLCHAIN_TARGET_CONV_SCRIPT} ${DEFINE_QL_TOOLCHAIN_TARGET_SYNTH_SCRIPT}
          DESTINATION share/symbiflow/scripts/${FAMILY})

  install(FILES ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/${FAMILY}/utils/create_ioplace.py
          DESTINATION bin/python
          PERMISSIONS WORLD_EXECUTE WORLD_READ OWNER_WRITE OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE)

endfunction()

function(DEFINE_QL_DEVICE_CELLS_INSTALL_TARGET)
  set(options)
  set(oneValueArgs DEVICE_TYPE DEVICE PACKAGE)
  set(multiValueArgs)

  cmake_parse_arguments(
    DEFINE_QL_DEVICE_CELLS_INSTALL_TARGET
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    "${ARGN}"
  )

  set(DEVICE_TYPE ${DEFINE_QL_DEVICE_CELLS_INSTALL_TARGET_DEVICE_TYPE})
  set(DEVICE ${DEFINE_QL_DEVICE_CELLS_INSTALL_TARGET_DEVICE})
  set(PACKAGE ${DEFINE_QL_DEVICE_CELLS_INSTALL_TARGET_PACKAGE})

  # Check if the device should be installed
  check_device_install(${DEVICE} DO_INSTALL)
  if (NOT DO_INSTALL)
    message(STATUS "Skipping installation of device ${DEVICE}-${PACKAGE} (type ${DEVICE_TYPE})")
    return()
  endif ()

  # Install the final architecture file. This is actually already done in
  # DEFINE_DEVICE but in case when the file name differs across devices we
  # want it to be unified for the installed toolchain.
  get_target_property_required(DEVICE_MERGED_FILE ${DEVICE_TYPE} DEVICE_MERGED_FILE)
  get_file_location(DEVICE_MERGED_FILE_LOCATION ${DEVICE_MERGED_FILE})

  install(FILES ${DEVICE_MERGED_FILE_LOCATION}
          DESTINATION "share/symbiflow/arch/${DEVICE}_${PACKAGE}"
          RENAME "arch_${DEVICE}_${PACKAGE}.xml")

  # Install device-specific cells sim and cells map files
  get_target_property(CELLS_SIM ${DEVICE_TYPE} CELLS_SIM)
  get_target_property(CELLS_MAP ${DEVICE_TYPE} CELLS_MAP)
  if (NOT "${CELLS_SIM}" MATCHES ".*NOTFOUND")
    get_file_target(CELLS_SIM_TARGET ${CELLS_SIM})
    get_file_location(CELLS_SIM ${CELLS_SIM})
    add_custom_target(
      "CELLS_INSTALL_${DEVICE}_CELLS_SIM"
      ALL
      DEPENDS ${CELLS_SIM_TARGET} ${CELLS_SIM}
      )
    install(FILES ${CELLS_SIM}
      DESTINATION "share/symbiflow/arch/${DEVICE}_${PACKAGE}/cells")
  endif()

  if (NOT "${CELLS_MAP}" MATCHES ".*NOTFOUND")
    get_file_target(CELLS_MAP_TARGET ${CELLS_MAP})
    get_file_location(CELLS_MAP ${CELLS_MAP})
    add_custom_target(
      "CELLS_INSTALL_${DEVICE}_CELLS_MAP"
      ALL
      DEPENDS ${CELLS_MAP_TARGET} ${CELLS_MAP}
      )
    install(FILES ${CELLS_MAP}
      DESTINATION "share/symbiflow/arch/${DEVICE}_${PACKAGE}/cells")
  endif()
endfunction()

function(DEFINE_QL_PINMAP_CSV_INSTALL_TARGET)
  set(options)
  set(oneValueArgs PART DEVICE_TYPE BOARD DEVICE PACKAGE FABRIC_PACKAGE)
  set(multiValueArgs)

  cmake_parse_arguments(
    DEFINE_QL_PINMAP_CSV_INSTALL_TARGET
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    "${ARGN}"
  )

  set(PART ${DEFINE_QL_PINMAP_CSV_INSTALL_TARGET_PART})
  set(BOARD ${DEFINE_QL_PINMAP_CSV_INSTALL_TARGET_BOARD})
  set(DEVICE ${DEFINE_QL_PINMAP_CSV_INSTALL_TARGET_DEVICE})
  set(DEVICE_TYPE ${DEFINE_QL_PINMAP_CSV_INSTALL_TARGET_DEVICE_TYPE})
  set(PACKAGE ${DEFINE_QL_PINMAP_CSV_INSTALL_TARGET_PACKAGE})

  get_target_property_required(NO_INSTALL ${ARCH} NO_INSTALL)
  if(${NO_INSTALL})
    message(STATUS "Architecture ${ARCH} not set for install")
    return()
  endif()

  get_target_property_required(PINMAP ${BOARD} PINMAP)
  get_file_location(PINMAP_FILE ${PINMAP})
  get_filename_component(PINMAP_FILE_REAL ${PINMAP_FILE} REALPATH)
  get_filename_component(PINMAP_FILE_NAME ${PINMAP_FILE} NAME)
  append_file_dependency(DEPS ${PINMAP})
  add_custom_target(
    "PINMAP_INSTALL_${BOARD}_${DEVICE}_${PACKAGE}_${PINMAP_FILE_NAME}"
    ALL
    DEPENDS ${DEPS}
    )
  install(FILES ${PINMAP_FILE_REAL}
    DESTINATION "share/symbiflow/arch/${DEVICE}_${PACKAGE}/${PART}"
    RENAME "pinmap_${ADD_QUICKLOGIC_BOARD_FABRIC_PACKAGE}.csv")

  get_target_property_required(PINMAP ${BOARD} PINMAP_XML)
  get_file_location(PINMAP_XML_FILE ${PINMAP_XML})
  get_filename_component(PINMAP_XML_FILE_REAL ${PINMAP_XML_FILE} REALPATH)
  get_filename_component(PINMAP_XML_FILE_NAME ${PINMAP_XML_FILE} NAME)
  append_file_dependency(DEPS ${PINMAP_XML})
  add_custom_target(
    "PINMAP_XML_INSTALL_${BOARD}_${DEVICE}_${PACKAGE}_${PINMAP_XML_FILE_NAME}"
    ALL
    DEPENDS ${DEPS}
    )
  install(FILES ${PINMAP_XML_FILE_REAL}
    DESTINATION "share/symbiflow/arch/${DEVICE}_${PACKAGE}/${PART}"
    RENAME "pinmap_${ADD_QUICKLOGIC_BOARD_FABRIC_PACKAGE}.xml")

  get_target_property(CLKMAP ${BOARD} CLKMAP)
  if(NOT "${CLKMAP}" MATCHES ".*-NOTFOUND")
    get_file_location(CLKMAP_FILE ${CLKMAP})
    get_filename_component(CLKMAP_FILE_REAL ${CLKMAP_FILE} REALPATH)
    get_filename_component(CLKMAP_FILE_NAME ${CLKMAP_FILE} NAME)
    append_file_dependency(DEPS ${CLKMAP})
    add_custom_target(
      "CLKMAP_INSTALL_${BOARD}_${DEVICE}_${PACKAGE}_${CLKMAP_FILE_NAME}"
      ALL
      DEPENDS ${DEPS}
      )
    install(FILES ${CLKMAP_FILE_REAL}
      DESTINATION "share/symbiflow/arch/${DEVICE}_${PACKAGE}/${PART}"
      RENAME "clkmap_${ADD_QUICKLOGIC_BOARD_FABRIC_PACKAGE}.csv")
  endif()

endfunction()
