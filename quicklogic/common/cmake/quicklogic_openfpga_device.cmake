function(QUICKLOGIC_DEFINE_OPENFPGA_DEVICE)
  # ~~~
  # QUICKLOGIC_DEFINE_OPENFPGA_DEVICE(
  #   NAME <name>
  #   FAMILY <family>
  #   ARCH <arch>
  #   ARCH_XML <arch.xml>
  #   LAYOUT <layout name>
  #   [ROUTE_CHAN_WIDTH <route channel width>]
  #   )
  # ~~~
  set(options)
  set(oneValueArgs NAME FAMILY ARCH ARCH_XML LAYOUT ROUTE_CHAN_WIDTH)
  set(multiValueArgs)
  cmake_parse_arguments(
    QUICKLOGIC_DEFINE_OPENFPGA_DEVICE
     "${options}"
     "${oneValueArgs}"
     "${multiValueArgs}"
     ${ARGN}
   )

  # Get args
  set(NAME     ${QUICKLOGIC_DEFINE_OPENFPGA_DEVICE_NAME})
  set(FAMILY   ${QUICKLOGIC_DEFINE_OPENFPGA_DEVICE_FAMILY})
  set(ARCH     ${QUICKLOGIC_DEFINE_OPENFPGA_DEVICE_ARCH})
  set(ARCH_XML ${QUICKLOGIC_DEFINE_OPENFPGA_DEVICE_ARCH_XML})
  set(LAYOUT   ${QUICKLOGIC_DEFINE_OPENFPGA_DEVICE_LAYOUT})

  # If ROUTE_CHAN_WIDTH is not given then use the value from the architecture
  if("${QUICKLOGIC_DEFINE_OPENFPGA_DEVICE_ROUTE_CHAN_WIDTH}" STREQUAL "")
    get_target_property_required(ROUTE_CHAN_WIDTH ${ARCH} ROUTE_CHAN_WIDTH)
  else()
    set(ROUTE_CHAN_WIDTH ${QUICKLOGIC_DEFINE_OPENFPGA_DEVICE_ROUTE_CHAN_WIDTH})
  endif()

  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

  # Format device name and device type name
  set(DEVICE "${ARCH}-${NAME}")
  set(DEVICE_TYPE ${DEVICE}-virt)

  set(PACKAGE ${DEVICE})

  # .......................................................

  # Arch XML base file
  get_file_target(ARCH_XML_TARGET ${ARCH_XML})
  if (NOT TARGET ${ARCH_XML_TARGET})
      add_file_target(FILE ${ARCH_XML} SCANNER_TYPE)
  endif()

  get_file_location(ARCH_BASE_FILE ${ARCH_XML})
  set(ARCH_BASE_NAME "${DEVICE}-arch")

  # .......................................................

  # VPR architecture fixup.
  #
  # For now architecture from the VPR used in OpenFPGA is incompaatible with
  # the VPR used in SymbiFlow. This is due to heterogeneous tile support
  # not being integrated there yet.
  #
  # This step also removes some element attributes that are not recognized
  # by SymbiFlow VPR

  set(ARCH_FIXUP_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/openfpga/utils/fixup_arch.py)

  set(ARCH_FIXUP_FILE "${ARCH_BASE_NAME}.fixup.xml")
  set(ARCH_FIXUP_CMD
    ${PYTHON3} ${ARCH_FIXUP_SCRIPT}
      --arch-in ${ARCH_BASE_FILE}
      --arch-out ${ARCH_FIXUP_FILE}
      --pick-layout ${LAYOUT}=${DEVICE}
  )

  add_custom_command(
    OUTPUT ${ARCH_FIXUP_FILE}
    COMMAND ${ARCH_FIXUP_CMD}
    DEPENDS ${ARCH_BASE_FILE} ${ARCH_FIXUP_SCRIPT} ${PYTHON3} ${PYTHON3_TARGET}
  )
  add_file_target(FILE ${ARCH_FIXUP_FILE} GENERATED)

  # .......................................................

  # FASM pefix injection.
  #
  # The layout is provided as XML described using VPR grid loc constructs.
  # These do not allow to specify fasm prefixed directly. So instead the
  # arch.xml is processed by a script that updated the layout so that it
  # consists only of <single> tiles that have unique FASM prefixes.
  set(FASM_PREFIX_TEMPLATE "X{x}Y{y}")

  # FIXME: Move the script to quicklogic/common
  set(FLATTEN_LAYOUT_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/common/utils/flatten_layout.py)

  set(ARCH_PREFIXED_FILE "${ARCH_BASE_NAME}.prefixed.xml")
  set(ARCH_PREFIXED_CMD
    ${PYTHON3} ${FLATTEN_LAYOUT_SCRIPT}
      --arch-in ${ARCH_FIXUP_FILE}
      --arch-out ${ARCH_PREFIXED_FILE}
      --fasm_prefix ${FASM_PREFIX_TEMPLATE}
  )
  
  add_custom_command(
    OUTPUT ${ARCH_PREFIXED_FILE}
    COMMAND ${ARCH_PREFIXED_CMD}
    DEPENDS ${ARCH_FIXUP_FILE} ${FLATTEN_LAYOUT_SCRIPT} ${PYTHON3} ${PYTHON3_TARGET}
  )
  add_file_target(FILE ${ARCH_PREFIXED_FILE} GENERATED)

  set(ARCH_FINAL_FILE ${ARCH_PREFIXED_FILE})

  # .......................................................

  add_custom_target(
    ${DEVICE_TYPE}
  )
  append_file_dependency(ARCH_FINAL ${ARCH_FINAL_FILE})

  set_target_properties(
    ${DEVICE_TYPE}
    PROPERTIES
    TECHFILE ""
    FAMILY ${FAMILY}
    DEVICE_MERGED_FILE ${CMAKE_CURRENT_SOURCE_DIR}/${ARCH_FINAL_FILE}
  )

  # .......................................................

  # RR graph patch dependencies
  set(DEVICE_RR_PATCH_DEPS "")
  set(DEVICE_RR_PATCH_EXTRA_ARGS "")

  # VPR "cache" options
  set(ROUTER_LOOKAHEAD "extended_map")

  # Define the device
  define_device(
    DEVICE ${DEVICE}
    ARCH ${ARCH}
    DEVICE_TYPE ${DEVICE_TYPE}
    PACKAGES ${PACKAGE}
    ROUTE_CHAN_WIDTH ${ROUTE_CHAN_WIDTH}
    WIRE_EBLIF ${symbiflow-arch-defs_SOURCE_DIR}/common/wire.eblif
    RR_PATCH_DEPS ${DEVICE_RR_PATCH_DEPS}
    RR_PATCH_EXTRA_ARGS ${DEVICE_RR_PATCH_EXTRA_ARGS}

#    CACHE_PLACE_DELAY
#    CACHE_LOOKAHEAD
#    CACHE_ARGS
#      --constant_net_method route
#      --clock_modeling ideal # Do not route clocks in OpenFPGA
#      --place_delay_model delta_override
#      --place_delta_delay_matrix_calculation_method dijkstra
#      --router_lookahead ${ROUTER_LOOKAHEAD}
#      --disable_errors check_unbuffered_edges:check_route:check_place
#      --suppress_warnings sum_pin_class:check_unbuffered_edges:load_rr_indexed_data_T_values:check_rr_node:trans_per_R:set_rr_graph_tool_comment
#      --route_chan_width 100

    CACHE_ARGS
      --route_chan_width ${ROUTE_CHAN_WIDTH}

    # FIXME: Skip installation for now
    DONT_INSTALL
  )

endfunction()

