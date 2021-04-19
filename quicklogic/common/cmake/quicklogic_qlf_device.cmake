function(QUICKLOGIC_DEFINE_QLF_DEVICE)
  # ~~~
  # QUICKLOGIC_DEFINE_QLF_DEVICE(
  #   NAME <name>
  #   FAMILY <family>
  #   ARCH <arch>
  #   ARCH_XML <arch.xml>
  #   LAYOUT <layout name>
  #   RR_GRAPH <rr_graph>
  #   [ROUTE_CHAN_WIDTH <route channel width>]
  #   REPACKING_RULES <repacking_rules.json>
  #   )
  # ~~~
  set(options)
  set(oneValueArgs NAME FAMILY ARCH ARCH_XML LAYOUT RR_GRAPH ROUTE_CHAN_WIDTH REPACKING_RULES)
  set(multiValueArgs)
  cmake_parse_arguments(
    QUICKLOGIC_DEFINE_QLF_DEVICE
     "${options}"
     "${oneValueArgs}"
     "${multiValueArgs}"
     ${ARGN}
   )

  # Get args
  set(NAME     ${QUICKLOGIC_DEFINE_QLF_DEVICE_NAME})
  set(FAMILY   ${QUICKLOGIC_DEFINE_QLF_DEVICE_FAMILY})
  set(ARCH     ${QUICKLOGIC_DEFINE_QLF_DEVICE_ARCH})
  set(ARCH_XML ${QUICKLOGIC_DEFINE_QLF_DEVICE_ARCH_XML})
  set(LAYOUT   ${QUICKLOGIC_DEFINE_QLF_DEVICE_LAYOUT})
  set(RR_GRAPH ${QUICKLOGIC_DEFINE_QLF_DEVICE_RR_GRAPH})

  set(REPACKING_RULES ${QUICKLOGIC_DEFINE_QLF_DEVICE_REPACKING_RULES})

  # If ROUTE_CHAN_WIDTH is not given then use the value from the architecture
  if("${QUICKLOGIC_DEFINE_QLF_DEVICE_ROUTE_CHAN_WIDTH}" STREQUAL "")
    get_target_property_required(ROUTE_CHAN_WIDTH ${ARCH} ROUTE_CHAN_WIDTH)
  else()
    set(ROUTE_CHAN_WIDTH ${QUICKLOGIC_DEFINE_QLF_DEVICE_ROUTE_CHAN_WIDTH})
  endif()

  get_target_property_required(PYTHON3 env PYTHON3)

  # Format device name and device type name
  set(DEVICE "${ARCH}-${NAME}")
  set(DEVICE_TYPE ${DEVICE}-virt)

  set(PACKAGE ${DEVICE})

  # .......................................................

  # Copy VPR arch XML
  set(ARCH_XML_NAME ${DEVICE}.arch.xml)

  add_custom_command(
    OUTPUT
      ${CMAKE_CURRENT_BINARY_DIR}/${ARCH_XML_NAME}
    DEPENDS
      ${ARCH_XML}
    COMMAND
      ${CMAKE_COMMAND} -E copy
        ${ARCH_XML}
        ${CMAKE_CURRENT_BINARY_DIR}/${ARCH_XML_NAME}
  )

  add_file_target(FILE ${ARCH_XML_NAME} GENERATED)

  # .......................................................

  set(RR_GRAPH_FOR_DEVICE ${DEVICE}.rr_graph.bin)

  # If the routing graph is compressed uncompress it
  if ("${RR_GRAPH}" MATCHES ".*\\.gz$")

    add_custom_command(
      OUTPUT
        ${CMAKE_CURRENT_BINARY_DIR}/${RR_GRAPH_FOR_DEVICE}
      DEPENDS
        ${RR_GRAPH}
      COMMAND
        ${CMAKE_COMMAND} -E copy
          ${RR_GRAPH}
          ${CMAKE_CURRENT_BINARY_DIR}/${RR_GRAPH_FOR_DEVICE}.gz
      COMMAND
        gunzip -v -f ${CMAKE_CURRENT_BINARY_DIR}/${RR_GRAPH_FOR_DEVICE}.gz
    )

  # If not then copy it
  else ()

    add_custom_command(
      OUTPUT
        ${CMAKE_CURRENT_BINARY_DIR}/${RR_GRAPH_FOR_DEVICE}
      DEPENDS
        ${RR_GRAPH}
      COMMAND
        ${CMAKE_COMMAND} -E copy
          ${RR_GRAPH}
          ${CMAKE_CURRENT_BINARY_DIR}/${RR_GRAPH_FOR_DEVICE}
    )

  endif ()

  add_file_target(FILE ${RR_GRAPH_FOR_DEVICE} GENERATED)

  # .......................................................

  # Copy repacking rules
  set(REPACKING_RULES_NAME ${DEVICE}.repacking_rules.json)

  add_custom_command(
    OUTPUT
      ${CMAKE_CURRENT_BINARY_DIR}/${REPACKING_RULES_NAME}
    DEPENDS
      ${ARCH_XML}
    COMMAND
      ${CMAKE_COMMAND} -E copy
        ${REPACKING_RULES}
        ${CMAKE_CURRENT_BINARY_DIR}/${REPACKING_RULES_NAME}
  )

  add_file_target(FILE ${REPACKING_RULES_NAME} GENERATED)

  # .......................................................

  add_custom_target(
    ${DEVICE_TYPE}
  )

  set_target_properties(
    ${DEVICE_TYPE}
    PROPERTIES
    USE_ROI FALSE
    LIMIT_GRAPH_TO_DEVICE FALSE
    TECHFILE ""
    FAMILY ${FAMILY}
    DEVICE_MERGED_FILE ${CMAKE_CURRENT_SOURCE_DIR}/${ARCH_XML_NAME}
    USE_ROI FALSE
    LIMIT_GRAPH_TO_DEVICE FALSE
  )

  # .......................................................

  get_file_target(REPACKING_RULES_TARGET ${REPACKING_RULES_NAME})

  set(DEVICE_NET_PATCH_DEPS ${REPACKING_RULES_TARGET})
  set(DEVICE_NET_PATCH_EXTRA_ARGS "--repacking-rules ${CMAKE_CURRENT_BINARY_DIR}/${REPACKING_RULES_NAME}")

  # Add the repacking rules as an extra file to be installed
  set(EXTRA_INSTALL_FILES
    ${CMAKE_CURRENT_SOURCE_DIR}/${REPACKING_RULES_NAME}
  )

  # Define the device
  define_device(
    DEVICE ${DEVICE}
    ARCH ${ARCH}
    DEVICE_TYPE ${DEVICE_TYPE}
    PACKAGES ${PACKAGE}
    ROUTE_CHAN_WIDTH ${ROUTE_CHAN_WIDTH}

    EXT_RR_GRAPH ${CMAKE_CURRENT_BINARY_DIR}/${RR_GRAPH_FOR_DEVICE}
    NO_RR_PATCHING

    NET_PATCH_DEPS ${DEVICE_NET_PATCH_DEPS}
    NET_PATCH_EXTRA_ARGS ${DEVICE_NET_PATCH_EXTRA_ARGS}

    CACHE_PLACE_DELAY
    CACHE_LOOKAHEAD
    CACHE_ARGS
      --constant_net_method route
      --clock_modeling ideal # Do not route clocks
      --place_delay_model delta_override
      --place_delta_delay_matrix_calculation_method dijkstra
      --router_lookahead extended_map
      --route_chan_width ${ROUTE_CHAN_WIDTH}

    EXTRA_INSTALL_FILES ${EXTRA_INSTALL_FILES}
  )

  # .......................................................

  # Add install targets for additional device-specific files
  define_ql_device_cells_install_target(
    DEVICE ${DEVICE}
    DEVICE_TYPE ${DEVICE_TYPE}
    PACKAGE ${PACKAGE}
  )

endfunction()

