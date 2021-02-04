function(QUICKLOGIC_DEFINE_DEVICE_TYPE)
  # ~~~
  # QUICKLOGIC_DEFINE_DEVICE_TYPE(
  #   FAMILY <family>
  #   ARCH <arch>
  #   DEVICE <device>
  #   PACKAGES <package> <package> ...
  #   [GRID_LIMIT <xmin>,<ymin>,<xmax>,<ymax>]
  #   PB_TYPES <pb_type> <pb_type> ...
  #   TECHFILE_NAME <techfile name>
  #   ROUTING_TIMING_FILE_NAME <routing timing CSV file>
  #   LIB_TIMING_FILES <list timing lib files [can be wildcard]>
  #   RAM_TIMING_SDF <name of the RAM timing data>
  #   RAM_PBTYPE_COPY <name of the RAM pb_type to use>
  #   ARCH_XML_INCLUDES <file_name> <file_name> ...
  #   )
  # ~~~
  set(options)
  set(oneValueArgs FAMILY DEVICE ARCH GRID_LIMIT TECHFILE_NAME ROUTING_TIMING_FILE_NAME RAM_TIMING_SDF RAM_PBTYPE_COPY)
  set(multiValueArgs PACKAGES PB_TYPES LIB_TIMING_FILES DONT_NORMALIZE_FILES ARCH_XML_INCLUDES)
  cmake_parse_arguments(
    QUICKLOGIC_DEFINE_DEVICE_TYPE
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(TECHFILE_NAME ${QUICKLOGIC_DEFINE_DEVICE_TYPE_TECHFILE_NAME})
  set(FAMILY ${QUICKLOGIC_DEFINE_DEVICE_TYPE_FAMILY})
  set(DEVICE ${QUICKLOGIC_DEFINE_DEVICE_TYPE_DEVICE})
  set(ARCH ${QUICKLOGIC_DEFINE_DEVICE_TYPE_ARCH})
  set(GRID_LIMIT ${QUICKLOGIC_DEFINE_DEVICE_TYPE_GRID_LIMIT})
  set(PB_TYPES ${QUICKLOGIC_DEFINE_DEVICE_TYPE_PB_TYPES})
  set(ROUTING_TIMING_FILE_NAME ${QUICKLOGIC_DEFINE_DEVICE_TYPE_ROUTING_TIMING_FILE_NAME})
  set(LIB_TIMING_FILES ${QUICKLOGIC_DEFINE_DEVICE_TYPE_LIB_TIMING_FILES})
  set(DONT_NORMALIZE_FILES ${QUICKLOGIC_DEFINE_DEVICE_TYPE_DONT_NORMALIZE_FILES})
  set(RAM_TIMING_SDF ${QUICKLOGIC_DEFINE_DEVICE_TYPE_RAM_TIMING_SDF})
  set(RAM_PBTYPE_COPY ${QUICKLOGIC_DEFINE_DEVICE_TYPE_RAM_PBTYPE_COPY})
  set(ARCH_XML_INCLUDES ${QUICKLOGIC_DEFINE_DEVICE_TYPE_ARCH_XML_INCLUDES})

  set(DEVICE_TYPE ${DEVICE}-virt)

  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property_required(PYTHON3_TARGET env PYTHON3_TARGET)

  set(PHY_DB_FILE "db_phy.pickle")
  set(VPR_DB_FILE "db_vpr.pickle")
  set(ARCH_XML "arch.xml")

  # The techfile and routing timing file
  set(TECHFILE "${symbiflow-arch-defs_SOURCE_DIR}/third_party/${DEVICE}/Device Architecture Files/${TECHFILE_NAME}")
  set(ROUTING_TIMING "${symbiflow-arch-defs_SOURCE_DIR}/third_party/${DEVICE}/Timing Data Files/${ROUTING_TIMING_FILE_NAME}")

  # Import data from the techfile
  set(DATA_IMPORT ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/common/utils/data_import.py)
  add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${PHY_DB_FILE}
    COMMAND ${PYTHON3} ${DATA_IMPORT}
      --techfile ${TECHFILE}
      --routing-timing ${ROUTING_TIMING}
      --db ${PHY_DB_FILE}
    DEPENDS ${TECHFILE} ${ROUTING_TIMING} ${DATA_IMPORT} ${PYTHON3_TARGET}
  )
  add_file_target(FILE ${PHY_DB_FILE} GENERATED)

  # Generate SDF files with timing data
  set(LIB_TIMING_DIR "${symbiflow-arch-defs_SOURCE_DIR}/third_party/${DEVICE}/Timing Data Files/")
  set(SDF_TIMING_DIR "sdf")

  get_target_property_required(QUICKLOGIC_TIMINGS_IMPORTER env QUICKLOGIC_TIMINGS_IMPORTER)
  get_target_property_required(QUICKLOGIC_TIMINGS_IMPORTER_TARGET env QUICKLOGIC_TIMINGS_IMPORTER_TARGET)

  # TODO: How to handle different timing cases that depend on a cell config?
  # For example BIDIR cells have different timings for different voltages.
  #
  # One idea is to have a different model for each in VPR.
  #
  # For now only files with the worst case scenario timings are taken.
  set(TIMING_FILES "")
  foreach(LIB ${LIB_TIMING_FILES})

    file(GLOB TIMING_FILE
      "${LIB_TIMING_DIR}/${LIB}"
    )
    list(APPEND TIMING_FILES ${TIMING_FILE})
  endforeach()

  set(SDF_FILE_TARGETS "")
  foreach(LIB_TIMING_FILE ${TIMING_FILES})

    get_filename_component(FILE_NAME ${LIB_TIMING_FILE} NAME)
    get_filename_component(FILE_TITLE ${FILE_NAME} NAME_WE)

    set(IMPORTER_OPTS "")
    if(NOT ${FILE_NAME} IN_LIST DONT_NORMALIZE_FILES)
      list(APPEND IMPORTER_OPTS "--normalize-cell-names")
      list(APPEND IMPORTER_OPTS "--normalize-port-names")
    endif()

    set(SDF_TIMING_FILE ${SDF_TIMING_DIR}/${FILE_TITLE}.sdf)

    add_custom_command(
      OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${SDF_TIMING_FILE}
      COMMAND ${CMAKE_COMMAND} -E make_directory ${SDF_TIMING_DIR}
      COMMAND ${PYTHON3} -m quicklogic_timings_importer
        ${LIB_TIMING_FILE}
        ${SDF_TIMING_FILE}
        ${IMPORTER_OPTS}
      DEPENDS ${PYTHON3} ${PYTHON3_TARGET} ${QUICKLOGIC_TIMINGS_IMPORTER_TARGET} ${LIB_TIMING_FILE}
    )

    add_file_target(FILE ${SDF_TIMING_FILE} GENERATED)
    append_file_dependency(SDF_FILE_TARGETS ${SDF_TIMING_FILE})

  endforeach()


  # Process the database, create the VPR database
  set(PREPARE_VPR_DATABASE ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/common/utils/prepare_vpr_database.py)
  get_file_target(PHY_DB_TARGET ${PHY_DB_FILE})

  if(NOT "${GRID_LIMIT}" STREQUAL "")
    separate_arguments(GRID_LIMIT_ARGS UNIX_COMMAND "--grid-limit ${GRID_LIMIT}")
  else()
    set(GRID_LIMIT_ARGS "")
  endif()

  add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${VPR_DB_FILE}
    COMMAND ${PYTHON3} ${PREPARE_VPR_DATABASE}
      --phy-db ${PHY_DB_FILE}
      --vpr-db ${VPR_DB_FILE}
      --sdf-dir ${SDF_TIMING_DIR}
      ${GRID_LIMIT_ARGS}
    DEPENDS ${PHY_DB_TARGET} sdf_timing ${SDF_FILE_TARGETS} ${PREPARE_VPR_DATABASE} ${PYTHON3_TARGET}
  )
  add_file_target(FILE ${VPR_DB_FILE} GENERATED)

  # Generate the arch.xml
  set(ARCH_IMPORT ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/common/utils/arch_import.py)

  if("${FAMILY}" STREQUAL "pp3")

      # Get dependencies for arch.xml
      set(XML_DEPS "")
      foreach(PB_TYPE ${PB_TYPES})
        string(TOLOWER ${PB_TYPE} PB_TYPE_LOWER)
        set(PB_TYPE_XML ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/${FAMILY}/primitives/${PB_TYPE_LOWER}/${PB_TYPE_LOWER}.pb_type.xml)
        set(MODEL_XML   ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/${FAMILY}/primitives/${PB_TYPE_LOWER}/${PB_TYPE_LOWER}.model.xml)
        append_file_dependency(XML_DEPS ${PB_TYPE_XML})
        append_file_dependency(XML_DEPS ${MODEL_XML})
      endforeach()
    
      # Add additional files included by arch.xml to its deps
      foreach(INC_XML ${ARCH_XML_INCLUDES})
    
        # Add the file target if does not exist
        get_file_target(INC_XML_TARGET ${INC_XML})
        if (NOT TARGET ${INC_XML_TARGET})
          add_file_target(FILE ${INC_XML})
        endif()
    
        # Append to the list
        append_file_dependency(XML_DEPS ${INC_XML})
      endforeach()

      # Generate model and pb_type XML for RAM
      # This will generate model XML and pb_type XMLs. Since there are 4 RAMs
      # there will be one pb_type for each of them with appropriate timings. Since
      # we cannot model that in the VPR for now we simply use one for all 4 RAMs.
      set(RAM_GENERATOR ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/${FAMILY}/primitives/ram/make_rams.py)
      set(RAM_MODE_DEFS ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/${FAMILY}/primitives/ram/ram_modes.json)
      set(RAM_SDF_FILE  ${SDF_TIMING_DIR}/${RAM_TIMING_SDF}.sdf)

      set(RAM_MODEL_XML  "ram.model.xml")
      set(RAM_PBTYPE_XML "ram.pb_type.xml")

      set(RAM_CELLS_SIM  "ram_sim.v")
      set(RAM_CELLS_MAP  "ram_map.v")

      get_file_target(RAM_SDF_FILE_TARGET ${RAM_SDF_FILE})

      add_custom_command(
          OUTPUT ${RAM_MODEL_XML} ${RAM_PBTYPE_XML} ${RAM_CELLS_SIM} ${RAM_CELLS_MAP}
          COMMAND ${PYTHON3} ${RAM_GENERATOR}
              --sdf ${RAM_SDF_FILE}
              --mode-defs ${RAM_MODE_DEFS}
              --xml-path ${CMAKE_CURRENT_BINARY_DIR}
              --vlog-path ${CMAKE_CURRENT_BINARY_DIR}
          COMMAND ${CMAKE_COMMAND} -E copy ${RAM_PBTYPE_COPY} ${RAM_PBTYPE_XML}
          DEPENDS ${PYTHON3} ${PYTHON3_TARGET} ${RAM_GENERATOR} ${RAM_MODE_DEFS} ${RAM_SDF_FILE_TARGET}
      )

      add_file_target(FILE ${RAM_MODEL_XML} GENERATED)
      add_file_target(FILE ${RAM_PBTYPE_XML} GENERATED)

      add_file_target(FILE ${RAM_CELLS_SIM} GENERATED)
      add_file_target(FILE ${RAM_CELLS_MAP} GENERATED)

      get_file_target(RAM_MODEL_XML_TARGET ${RAM_MODEL_XML})
      get_file_target(RAM_PBTYPE_XML_TARGET ${RAM_PBTYPE_XML})

      add_custom_command(
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${ARCH_XML}
        COMMAND ${PYTHON3} ${ARCH_IMPORT}
          --vpr-db ${VPR_DB_FILE}
          --arch-out ${ARCH_XML}
          --device ${DEVICE}
        DEPENDS ${VPR_DB_FILE} ${ARCH_XML_DEPS} ${ARCH_IMPORT} ${PYTHON3_TARGET} ${RAM_MODEL_XML_TARGET} ${RAM_PBTYPE_XML_TARGET}
      )
      add_file_target(FILE ${ARCH_XML} GENERATED)

      # Timing import stuff
      set(UPDATE_ARCH_TIMINGS ${symbiflow-arch-defs_SOURCE_DIR}/utils/update_arch_timings.py)
      set(PYTHON_SDF_TIMING_DIR ${symbiflow-arch-defs_SOURCE_DIR}/third_party/python-sdf-timing)
      get_target_property(SDF_TIMING_TARGET env SDF_TIMING_TARGET)

      set(BELS_MAP ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/${FAMILY}/${DEVICE}-bels.json)

      set(TIMING_IMPORT
        "${CMAKE_COMMAND} -E env PYTHONPATH=${PYTHON_SDF_TIMING_DIR}:$PYTHONPATH \
        ${PYTHON3} ${UPDATE_ARCH_TIMINGS} \
            --sdf_dir ${SDF_TIMING_DIR} \
            --bels_map ${BELS_MAP} \
            --out_arch /dev/stdout \
            --input_arch /dev/stdin \
        ")

      set(TIMING_DEPS ${SDF_TIMING_TARGET} sdf_timing ${SDF_FILE_TARGETS} ${BELS_MAP})
  
      # Define the device type
      define_device_type(
        DEVICE_TYPE ${DEVICE_TYPE}
        ARCH ${ARCH}
        ARCH_XML ${ARCH_XML}
        SCRIPT_OUTPUT_NAME timing
        SCRIPTS TIMING_IMPORT
        SCRIPT_DEPS TIMING_DEPS
      )

  elseif("${FAMILY}" STREQUAL "ap3")

      # Add the arch.xml target
      add_file_target(FILE ${ARCH_XML})

      # Get arch XML includes
      get_xml_includes(ARCH_XML_INCLUDES ${ARCH_XML})

      # Append them and/or add targets for them
      set(ARCH_XML_DEPS "")
      foreach(XML_INCLUDE ${ARCH_XML_INCLUDES})

        # Add the file target if does not exist
        get_file_target(XML_INCLUDE_TARGET ${XML_INCLUDE})
        if (NOT TARGET ${XML_INCLUDE_TARGET})
          file(RELATIVE_PATH XML_INCLUDE_REL ${CMAKE_CURRENT_SOURCE_DIR} ${XML_INCLUDE})      

          get_file_target(XML_INCLUDE_REL_TARGET ${XML_INCLUDE_REL})
          if (NOT TARGET ${XML_INCLUDE_REL_TARGET})
            add_file_target(FILE ${XML_INCLUDE_REL})
          endif()
      
          append_file_dependency(ARCH_XML_DEPS ${XML_INCLUDE_REL})

        # Append to the list
        else()
          append_file_dependency(ARCH_XML_DEPS ${XML_INCLUDE})

        endif()
      endforeach()

      # Append arch.xml dependencies
      get_file_target(ARCH_XML_TARGET ${ARCH_XML})
      foreach(DEP ${ARCH_XML_DEPS})
        if(TARGET ${DEP})
          add_dependencies(${ARCH_XML_TARGET} ${DEP})
        endif()
      endforeach()

      # FASM pefix injection.
      #
      # The layout is provided as XML described using VPR grid loc constructs.
      # These do not allow to specify fasm prefixed directly. So instead the
      # arch.xml is processed by a script that updated the layout so that it
      # consists only of <single> tiles that have unique FASM prefixes.

      set(FASM_PREFIX_TEMPLATE "X[{x}-1]Y[{y}-1]")
      set(SUB_TILE_FASM_PREFIX_TEMPLATE "INPUT_IO=PREIOIN_{i} OUTPUT_IO=PERIOOUT_{i} CONST_IO=DEF_{i} GMUX=GHSCK.GHSCK{i}")
      set(NOT_PREFIXED_TILES "TL-GND,TL-VCC")

      set(FLATTEN_LAYOUT_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/common/utils/flatten_layout.py)
      set(FLATTEN_LAYOUT
        "${PYTHON3} ${FLATTEN_LAYOUT_SCRIPT} \
            --arch-in /dev/stdin \
            --arch-out /dev/stdout \
            --fasm_prefix ${FASM_PREFIX_TEMPLATE} \
            --sub-tile-prefix ${SUB_TILE_FASM_PREFIX_TEMPLATE} \
            --no-prefix ${NOT_PREFIXED_TILES}
        ")

      set(FLATTEN_LAYOUT_DEPS ${PYTHON3} ${PYTHON3_TARGET} ${FLATTEN_LAYOUT_SCRIPT})

      # Timing import stuff
      #set(UPDATE_ARCH_TIMINGS ${symbiflow-arch-defs_SOURCE_DIR}/utils/update_arch_timings.py)
      #set(PYTHON_SDF_TIMING_DIR ${symbiflow-arch-defs_SOURCE_DIR}/third_party/python-sdf-timing)
      #get_target_property(SDF_TIMING_TARGET env SDF_TIMING_TARGET)

      #set(BELS_MAP ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/${FAMILY}/${DEVICE}-bels.json)

      #set(TIMING_IMPORT
      #  "${CMAKE_COMMAND} -E env PYTHONPATH=${PYTHON_SDF_TIMING_DIR}:$PYTHONPATH \
      #  ${PYTHON3} ${UPDATE_ARCH_TIMINGS} \
      #      --sdf_dir ${SDF_TIMING_DIR} \
      #      --bels_map ${BELS_MAP} \
      #      --out_arch /dev/stdout \
      #      --input_arch /dev/stdin \
      #  ")

      #set(TIMING_DEPS ${SDF_TIMING_TARGET} sdf_timing ${SDF_FILE_TARGETS} ${BELS_MAP})

      # Define the device type
      define_device_type(
        DEVICE_TYPE ${DEVICE_TYPE}
        ARCH ${ARCH}
        ARCH_XML ${ARCH_XML}
        SCRIPTS FLATTEN_LAYOUT
        SCRIPT_OUTPUT_NAME prefixed
        SCRIPT_DEPS FLATTEN_LAYOUT_DEPS
      )

  else()

    message(FATAL_ERROR "Family '${FAMILY}' not supported!")
  endif()

  # Set the device type properties
  if(NOT "${GRID_LIMIT}" STREQUAL "")
    set_target_properties(${DEVICE_TYPE} PROPERTIES USE_ROI TRUE)
  else()
    set_target_properties(${DEVICE_TYPE} PROPERTIES USE_ROI FALSE)
  endif()

  if("${FAMILY}" STREQUAL "pp3")
      set_target_properties(
        ${DEVICE_TYPE}
        PROPERTIES
        TECHFILE ${TECHFILE}
        FAMILY ${FAMILY}
        VPR_DB_FILE ${CMAKE_CURRENT_SOURCE_DIR}/${VPR_DB_FILE}
        CELLS_SIM ${CMAKE_CURRENT_SOURCE_DIR}/${RAM_CELLS_SIM}
        CELLS_MAP ${CMAKE_CURRENT_SOURCE_DIR}/${RAM_CELLS_MAP}
      )
  elseif("${FAMILY}" STREQUAL "ap3")
      set_target_properties(
        ${DEVICE_TYPE}
        PROPERTIES
        TECHFILE ${TECHFILE}
        FAMILY ${FAMILY}
      )
  else()
    message(FATAL_ERROR "Family '${FAMILY}' not supported!")
  endif()

endfunction()


function(QUICKLOGIC_DEFINE_DEVICE)
  # ~~~
  # QUICKLOGIC_DEFINE_DEVICE(
  #   FAMILY <family>
  #   ARCH <arch>
  #   DEVICES <device> <device> ...
  #   PACKAGES <package> <package> ...
  #   AUTO_SWITCHBOX_LAYOUT
  #   )
  # ~~~
  set(options AUTO_SWITCHBOX_LAYOUT)
  set(oneValueArgs FAMILY ARCH)
  set(multiValueArgs DEVICES PACKAGES)
  cmake_parse_arguments(
    QUICKLOGIC_DEFINE_DEVICE
     "${options}"
     "${oneValueArgs}"
     "${multiValueArgs}"
     ${ARGN}
   )

  set(FAMILY ${QUICKLOGIC_DEFINE_DEVICE_FAMILY})
  set(ARCH ${QUICKLOGIC_DEFINE_DEVICE_ARCH})
  set(DEVICES ${QUICKLOGIC_DEFINE_DEVICE_DEVICES})
  set(PACKAGES ${QUICKLOGIC_DEFINE_DEVICE_PACKAGES})
  set(AUTO_SWITCHBOX_LAYOUT ${QUICKLOGIC_DEFINE_DEVICE_AUTO_SWITCHBOX_LAYOUT})

  # For each device specified
  list(LENGTH DEVICES DEVICE_COUNT)
  math(EXPR DEVICE_COUNT_N_1 "${DEVICE_COUNT} - 1")
  foreach(INDEX RANGE ${DEVICE_COUNT_N_1})
    list(GET DEVICES ${INDEX} DEVICE)

    # Include the device type subdirectory
    set(DEVICE_TYPE ${DEVICE}-virt)
    add_subdirectory(${DEVICE_TYPE})

    # RR graph patch dependencies
    set(DEVICE_RR_PATCH_DEPS "")
    set(DEVICE_RR_PATCH_EXTRA_ARGS "")

    # For AP3 provide the techfile to RR patch tool
    if("${FAMILY}" STREQUAL "ap3")
        get_target_property_required(TECHFILE ${DEVICE_TYPE} TECHFILE)
        set(DEVICE_RR_PATCH_EXTRA_ARGS ${DEVICE_RR_PATCH_EXTRA_ARGS}
            "--techfile" "${TECHFILE}")
        list(APPEND DEVICE_RR_PATCH_DEPS ${TECHFILE})

        if(${AUTO_SWITCHBOX_LAYOUT})
            set(DEVICE_RR_PATCH_EXTRA_ARGS ${DEVICE_RR_PATCH_EXTRA_ARGS}
                "--auto-sbox-layout")
        endif()

        set(VPR_GRID_MAP_OUT "${CMAKE_CURRENT_BINARY_DIR}/vpr_grid_map_${DEVICE}_\${PACKAGE}.csv")
        set(DEVICE_RR_PATCH_EXTRA_ARGS ${DEVICE_RR_PATCH_EXTRA_ARGS}
            "--vpr-grid-map" ${VPR_GRID_MAP_OUT})

        set(CLKMAP_CSV_OUT "${CMAKE_CURRENT_BINARY_DIR}/clkmap_${DEVICE}_\${PACKAGE}.csv")
        set(DEVICE_RR_PATCH_EXTRA_ARGS ${DEVICE_RR_PATCH_EXTRA_ARGS}
            "--clock-map" ${CLKMAP_CSV_OUT})

    # For PP3 make it depend on the VPR database
    else()

        # Get the VPR db file to add as dependency to RR graph patch
        get_target_property_required(VPR_DB_FILE ${DEVICE_TYPE} VPR_DB_FILE)
        append_file_dependency(DEVICE_RR_PATCH_DEPS ${VPR_DB_FILE})

    endif()

    # VPR "cache" options
    if("${FAMILY}" STREQUAL "ap3")
        set(ROUTER_LOOKAHEAD "extended_map")
        set(TILES_FOR_DELAY_MODEL "SUPER_LOGIC_CELL,RAM,DSP")

    else()
        set(ROUTER_LOOKAHEAD "map")
        set(TILES_FOR_DELAY_MODEL "PB-LOGIC")

    endif()

    # FIXME: Skip installation of pp3 devices
    if ("${FAMILY}" STREQUAL "pp3")
        set(DEFINE_DEVICE_OPTS DONT_INSTALL)
    else()
        set(DEFINE_DEVICE_OPTS )
    endif()

    # Define the device
    define_device(
      DEVICE ${DEVICE}
      ARCH ${ARCH}
      DEVICE_TYPE ${DEVICE_TYPE}
      PACKAGES ${PACKAGES}
      WIRE_EBLIF ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/${FAMILY}/passthrough.eblif
      RR_PATCH_DEPS ${DEVICE_RR_PATCH_DEPS}
      RR_PATCH_EXTRA_ARGS ${DEVICE_RR_PATCH_EXTRA_ARGS}
      CACHE_PLACE_DELAY
      CACHE_LOOKAHEAD
      CACHE_ARGS
        --constant_net_method route
        --clock_modeling route
        --place_delay_model delta_override
        --place_delta_delay_matrix_calculation_method dijkstra
        --router_lookahead ${ROUTER_LOOKAHEAD}
        --disable_errors check_unbuffered_edges:check_route:check_place
        --suppress_warnings sum_pin_class:check_unbuffered_edges:load_rr_indexed_data_T_values:check_rr_node:trans_per_R:set_rr_graph_tool_comment
        --route_chan_width 100
        --allowed_tiles_for_delay_model ${TILES_FOR_DELAY_MODEL}
      ${DEFINE_DEVICE_OPTS}
    )

  endforeach()
endfunction()

function(QUICKLOGIC_DEFINE_SCALABLE_DEVICE)
  # ~~~
  # QUICKLOGIC_DEFINE_SCALABLE_DEVICE(
  #   FAMILY <family>
  #   ARCH <arch>
  #   ARCH_XML <arch.xml>
  #   TECHFILE <techfile>
  #   SIZE <width> <height>
  #   USE_FASM
  #   )
  # ~~~
  set(options USE_FASM)
  set(oneValueArgs FAMILY ARCH ARCH_XML TECHFILE)
  set(multiValueArgs SIZE)
  cmake_parse_arguments(
    QUICKLOGIC_DEFINE_SCALABLE_DEVICE
     "${options}"
     "${oneValueArgs}"
     "${multiValueArgs}"
     ${ARGN}
   )

  # Get args
  set(FAMILY   ${QUICKLOGIC_DEFINE_SCALABLE_DEVICE_FAMILY})
  set(ARCH     ${QUICKLOGIC_DEFINE_SCALABLE_DEVICE_ARCH})
  set(ARCH_XML ${QUICKLOGIC_DEFINE_SCALABLE_DEVICE_ARCH_XML})
  set(TECHFILE ${QUICKLOGIC_DEFINE_SCALABLE_DEVICE_TECHFILE})
  set(USE_FASM ${QUICKLOGIC_DEFINE_SCALABLE_DEVICE_USE_FASM})

  list(GET QUICKLOGIC_DEFINE_SCALABLE_DEVICE_SIZE 0 WIDTH)
  list(GET QUICKLOGIC_DEFINE_SCALABLE_DEVICE_SIZE 1 HEIGHT)

  if(NOT "${FAMILY}" STREQUAL "ap3_openfpga")
    message(FATAL_ERROR "Currently scalable QuickLogic device can only be of AP3 OpenFPGA family, not for ${FAMILY}")
  endif()

  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

  # Format device name and device type name
  set(DEVICE "${ARCH}-${WIDTH}x${HEIGHT}")
  set(DEVICE_TYPE ${DEVICE}-virt)

  set(PACKAGE ${DEVICE})

  # .......................................................

  # Arch XML base file
  get_file_target(ARCH_XML_TARGET ${ARCH_XML})
  if (NOT TARGET ${ARCH_XML_TARGET})
      add_file_target(FILE ${ARCH_XML} SCANNER_TYPE)
  endif()

  set(ARCH_BASE_NAME "${DEVICE}-arch")

  # Get arch XML includes
  get_xml_includes(ARCH_XML_INCLUDES ${ARCH_XML})

  # Append them and/or add targets for them
  set(ARCH_XML_DEPS "")
  foreach(XML_INCLUDE ${ARCH_XML_INCLUDES})

    # Add the file target if does not exist
    get_file_target(XML_INCLUDE_TARGET ${XML_INCLUDE})
    if (NOT TARGET ${XML_INCLUDE_TARGET})
      file(RELATIVE_PATH XML_INCLUDE_REL ${CMAKE_CURRENT_SOURCE_DIR} ${XML_INCLUDE})      

      get_file_target(XML_INCLUDE_REL_TARGET ${XML_INCLUDE_REL})
      if (NOT TARGET ${XML_INCLUDE_REL_TARGET})
        add_file_target(FILE ${XML_INCLUDE_REL})
      endif()
  
      append_file_dependency(ARCH_XML_DEPS ${XML_INCLUDE_REL})

    # Append to the list
    else()
      append_file_dependency(ARCH_XML_DEPS ${XML_INCLUDE})

    endif()
  endforeach()

  # Append dependencies
  get_file_target(ARCH_XML_TARGET ${ARCH_XML})
  foreach(DEP ${ARCH_XML_DEPS})
    if(TARGET ${DEP})
      add_dependencies(${ARCH_XML_TARGET} ${DEP})
    endif()
  endforeach()

  # .......................................................

  # Generate arch.merged.xml for the device.
  set(ARCH_MERGED_FILE "${ARCH_BASE_NAME}.merged.xml")
  xml_canonicalize_merge(
    NAME ${ARCH}_${DEVICE}_arch_merged
    FILE ${ARCH_XML}
    OUTPUT ${ARCH_MERGED_FILE}
  )

  # .......................................................

  # Inject device size to the arch.merged.xml
  set(SPECIALIZE_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/common/utils/specialize.py)

  math(EXPR TOTAL_WIDTH  "${WIDTH}  + 4") # One IO column and one margin column on each side
  math(EXPR TOTAL_HEIGHT "${HEIGHT} + 4") # One IO column and one margin column on each side

  set(TAGS
    "width=${WIDTH}"
    "height=${HEIGHT}"
    "total_width=${TOTAL_WIDTH}"
    "total_height=${TOTAL_HEIGHT}"
  )

  set(ARCH_SPECIALIZED_FILE "${ARCH_BASE_NAME}.specialized.xml")
  set(ARCH_SPECIALIZED_CMD
    ${PYTHON3} ${SPECIALIZE_SCRIPT}
      -i "${ARCH_MERGED_FILE}"
      -o "${ARCH_SPECIALIZED_FILE}"
      --tags ${TAGS}
  )

  add_custom_command(
    OUTPUT ${ARCH_SPECIALIZED_FILE}
    COMMAND ${ARCH_SPECIALIZED_CMD}
    DEPENDS ${ARCH_MERGED_FILE} ${SPECIALIZE_SCRIPT} ${PYTHON3} ${PYTHON3_TARGET}
  )
  add_file_target(FILE ${ARCH_SPECIALIZED_FILE} GENERATED)

  # .......................................................

  # Inject FASM prefixes
  if (USE_FASM)

      # FASM pefix injection.
      #
      # The layout is provided as XML described using VPR grid loc constructs.
      # These do not allow to specify fasm prefixed directly. So instead the
      # arch.xml is processed by a script that updated the layout so that it
      # consists only of <single> tiles that have unique FASM prefixes.
      set(FASM_PREFIX_TEMPLATE "X[{x}-1]Y[{y}-1]")
      set(SUB_TILE_FASM_PREFIX_TEMPLATE "INPUT_IO=PREIOIN_{i}" "OUTPUT_IO=PERIOOUT_{i}" "CONST_IO=DEF_{i}")
      set(NOT_PREFIXED_TILES "TL-GND,TL-VCC")

      set(FLATTEN_LAYOUT_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/common/utils/flatten_layout.py)

      set(ARCH_PREFIXED_FILE "${ARCH_BASE_NAME}.prefixed.xml")
      set(ARCH_PREFIXED_CMD
        ${PYTHON3} ${FLATTEN_LAYOUT_SCRIPT}
          --arch-in ${ARCH_SPECIALIZED_FILE}
          --arch-out ${ARCH_PREFIXED_FILE}
          --fasm_prefix ${FASM_PREFIX_TEMPLATE}
          --sub-tile-prefix ${SUB_TILE_FASM_PREFIX_TEMPLATE}
          --no-prefix ${NOT_PREFIXED_TILES}
      )
      
      add_custom_command(
        OUTPUT ${ARCH_PREFIXED_FILE}
        COMMAND ${ARCH_PREFIXED_CMD}
        DEPENDS ${ARCH_SPECIALIZED_FILE} ${FLATTEN_LAYOUT_SCRIPT} ${PYTHON3} ${PYTHON3_TARGET}
      )
      add_file_target(FILE ${ARCH_PREFIXED_FILE} GENERATED)

      set(ARCH_FINAL_FILE ${ARCH_PREFIXED_FILE})

  # No FASM prefix injection
  else ()
      set(ARCH_FINAL_FILE ${ARCH_SPECIALIZED_FILE})

  endif ()

  # .......................................................


  add_custom_target(
    ${DEVICE_TYPE}
  )
  append_file_dependency(ARCH_FINAL ${ARCH_FINAL_FILE})

  set_target_properties(
    ${DEVICE_TYPE}
    PROPERTIES
    TECHFILE ${TECHFILE}
    FAMILY ${FAMILY}
    DEVICE_MERGED_FILE ${CMAKE_CURRENT_SOURCE_DIR}/${ARCH_FINAL_FILE}
  )

  # .......................................................

  # RR graph patch dependencies
  set(DEVICE_RR_PATCH_DEPS "")
  set(DEVICE_RR_PATCH_EXTRA_ARGS "")

  # Techfile
  set(TECHFILE_LOCATION "${symbiflow-arch-defs_SOURCE_DIR}/third_party/ql-ap3-ql745a/Device Architecture Files/${TECHFILE}")
  set(DEVICE_RR_PATCH_EXTRA_ARGS ${DEVICE_RR_PATCH_EXTRA_ARGS} "--techfile" "${TECHFILE_LOCATION}")
  list(APPEND DEVICE_RR_PATCH_DEPS ${TECHFILE_LOCATION})

  # Extra rr import options
  set(DEVICE_RR_PATCH_EXTRA_ARGS ${DEVICE_RR_PATCH_EXTRA_ARGS} "--auto-sbox-layout" "--optimize")

  # VPR "cache" options
  set(ROUTER_LOOKAHEAD "extended_map")
  set(TILES_FOR_DELAY_MODEL "SUPER_LOGIC_CELL")

  # Define the device
  define_device(
    DEVICE ${DEVICE}
    ARCH ${ARCH}
    DEVICE_TYPE ${DEVICE_TYPE}
    PACKAGES ${PACKAGE}
    WIRE_EBLIF ${symbiflow-arch-defs_SOURCE_DIR}/common/wire.eblif
    RR_PATCH_DEPS ${DEVICE_RR_PATCH_DEPS}
    RR_PATCH_EXTRA_ARGS ${DEVICE_RR_PATCH_EXTRA_ARGS}
    CACHE_PLACE_DELAY
    CACHE_LOOKAHEAD
    CACHE_ARGS
      --constant_net_method route
      --clock_modeling ideal # Do not route clocks in OpenFPGA
      --place_delay_model delta_override
      --place_delta_delay_matrix_calculation_method dijkstra
      --router_lookahead ${ROUTER_LOOKAHEAD}
      --disable_errors check_unbuffered_edges:check_route:check_place
      --suppress_warnings sum_pin_class:check_unbuffered_edges:load_rr_indexed_data_T_values:check_rr_node:trans_per_R:set_rr_graph_tool_comment
      --route_chan_width 100
      --allowed_tiles_for_delay_model ${TILES_FOR_DELAY_MODEL}
    DONT_INSTALL
  )

endfunction()
