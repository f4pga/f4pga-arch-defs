function(ADD_QUICKLOGIC_BOARD)

  set(options)
  set(oneValueArgs BOARD DEVICE PACKAGE FABRIC_PACKAGE)
  set(multiValueArgs)
  cmake_parse_arguments(
     ADD_QUICKLOGIC_BOARD
     "${options}"
     "${oneValueArgs}"
     "${multiValueArgs}"
     ${ARGN}
    )

  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property_required(PYTHON3_TARGET env PYTHON3_TARGET)

  # Define the board
  define_board(
    BOARD ${ADD_QUICKLOGIC_BOARD_BOARD}
    DEVICE ${ADD_QUICKLOGIC_BOARD_DEVICE}
    PACKAGE ${ADD_QUICKLOGIC_BOARD_PACKAGE}
    )

  set(DEVICE ${ADD_QUICKLOGIC_BOARD_DEVICE})
  get_target_property_required(ARCH ${DEVICE} ARCH)
  get_target_property_required(DEVICE_TYPE ${DEVICE} DEVICE_TYPE)
  get_target_property_required(FAMILY ${DEVICE_TYPE} FAMILY)
  set(PACKAGE ${ADD_QUICKLOGIC_BOARD_PACKAGE})
  set(BOARD ${ADD_QUICKLOGIC_BOARD_BOARD})

  # Get the database location. If given then use the database to generate
  # pinmap and clkmap CSV files
  get_target_property(VPR_DB_FILE ${DEVICE_TYPE} VPR_DB_FILE)
  if(NOT "${VPR_DB_FILE}" STREQUAL "VPR_DB_FILE-NOTFOUND")

    # Get the database location
    get_target_property_required(VPR_DB_FILE ${DEVICE_TYPE} VPR_DB_FILE)
    get_file_location(VPR_DB_FILE_LOC ${VPR_DB_FILE})
    get_file_target(VPR_DB_TARGET ${VPR_DB_FILE})
  
    # Generate clock pad map CSV file
    set(CREATE_CLKMAP_CSV ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/common/utils/create_clkmap_csv.py)
    set(CLKMAP_CSV ${BOARD}_clkmap.csv)
    set(CLKMAP_CSV_DEPS ${PYTHON3} ${PYTHON3_TARGET} ${CREATE_CLKMAP_CSV})
    append_file_dependency(CLKMAP_CSV_DEPS ${VPR_DB_FILE})
  
    add_custom_command(
      OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${CLKMAP_CSV}
      COMMAND ${PYTHON3} ${CREATE_CLKMAP_CSV}
        -o ${CMAKE_CURRENT_BINARY_DIR}/${CLKMAP_CSV}
        --db ${VPR_DB_FILE_LOC}
      DEPENDS ${CLKMAP_CSV_DEPS}
    )
  
    add_file_target(FILE ${CLKMAP_CSV} GENERATED)
  
    # Generate pinmap CSV file
    set(CREATE_PINMAP_CSV ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/common/utils/create_pinmap_csv.py)
    set(PINMAP_CSV ${BOARD}_pinmap.csv)
    set(PINMAP_CSV_DEPS ${PYTHON3} ${PYTHON3_TARGET} ${CREATE_PINMAP_CSV})
    append_file_dependency(PINMAP_CSV_DEPS ${VPR_DB_FILE})
  
    # Make the pinmap depend on clkmap. This way it is build without the need for
    # adding the dependency elsewhere.
    append_file_dependency(PINMAP_CSV_DEPS ${CLKMAP_CSV})
  
    # TODO: Use the PACKAGE in the pinmap CSV generation.
    add_custom_command(
      OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${PINMAP_CSV}
      COMMAND ${PYTHON3} ${CREATE_PINMAP_CSV}
        -o ${CMAKE_CURRENT_BINARY_DIR}/${PINMAP_CSV}
        --package ${ADD_QUICKLOGIC_BOARD_FABRIC_PACKAGE}
        --db ${VPR_DB_FILE_LOC}
      DEPENDS ${PINMAP_CSV_DEPS}
    )
  
    add_file_target(FILE ${PINMAP_CSV} GENERATED)
  
    # Set the board properties
    set_target_properties(
      ${BOARD}
      PROPERTIES
        PINMAP
        ${CMAKE_CURRENT_SOURCE_DIR}/${PINMAP_CSV}
        CLKMAP
        ${CMAKE_CURRENT_SOURCE_DIR}/${CLKMAP_CSV}
    )
  
    set_target_properties(
      dummy_${ARCH}_${DEVICE}_${PACKAGE}
      PROPERTIES
      PINMAP ${CMAKE_CURRENT_SOURCE_DIR}/${PINMAP_CSV}
      CLKMAP ${CMAKE_CURRENT_SOURCE_DIR}/${CLKMAP_CSV}
    )

    # FIXME: Disable installation of PP3 targets
    if(NOT "${FAMILY}" STREQUAL "pp3")
        define_ql_pinmap_csv_install_target(
          PART ${PART}
          BOARD ${BOARD}
          DEVICE_TYPE ${DEVICE_TYPE}
          DEVICE ${DEVICE}
          PACKAGE ${PACKAGE}
          )
    else()
        message(WARNING "FIXME: Skipping installation of ${FAMILY} '${BOARD}' board")
    endif()

  # For AP3 architecture generate pinmap and clkmap CSV files using the techfile
  # and VPR grid map which is generated along rr graph patching
  elseif("${ARCH}" STREQUAL "ql-ap3")

    # Get techfile location
    get_target_property_required(TECHFILE ${DEVICE_TYPE} TECHFILE)

    # Get the rr graph target and location
    get_target_property_required(RR_GRAPH_FILE ${DEVICE} ${PACKAGE}_OUT_RRBIN_REAL)
    get_file_target(RR_GRAPH_TARGET ${RR_GRAPH_FILE})
    get_file_location(RR_GRAPH_LOCATION ${RR_GRAPH_FILE})

    # Format VPR grid map file name
    get_filename_component(DEVICES_DIR ${RR_GRAPH_LOCATION} DIRECTORY)
    set(VPR_GRID_MAP_LOCATION ${DEVICES_DIR}/vpr_grid_map_${DEVICE}_${PACKAGE}.csv)

    # Generate clock pad map CSV file
    set(CLKMAP_CSV_LOCATION ${DEVICES_DIR}/clkmap_${DEVICE}_${PACKAGE}.csv)
    set(CLKMAP_CSV ${BOARD}_clkmap.csv)
    add_custom_command(
      OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${CLKMAP_CSV}
      COMMAND
        ${CMAKE_COMMAND} -E create_symlink 
            ${CLKMAP_CSV_LOCATION}
            ${CMAKE_CURRENT_BINARY_DIR}/${CLKMAP_CSV}
      DEPENDS ${RR_GRAPH_TARGET}
    )

    add_file_target(FILE ${CLKMAP_CSV} GENERATED)

    # Generate pinmap CSV file
    set(CREATE_PINMAP_CSV ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/${FAMILY}/utils/ap3_create_pinmap_csv.py)
    set(PINMAP_CSV ${BOARD}_pinmap.csv)
    set(PINMAP_CSV_DEPS ${PYTHON3} ${PYTHON3_TARGET} ${CREATE_PINMAP_CSV} ${TECHFILE})
    append_file_dependency(PINMAP_CSV_DEPS ${RR_GRAPH_FILE})
  
    # Make the pinmap depend on clkmap. This way it is build without the need for
    # adding the dependency elsewhere.
    append_file_dependency(PINMAP_CSV_DEPS ${CLKMAP_CSV})
  
    # TODO: Use the PACKAGE in the pinmap CSV generation.
    add_custom_command(
      OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${PINMAP_CSV}
      COMMAND ${PYTHON3} ${CREATE_PINMAP_CSV}
        -o ${CMAKE_CURRENT_BINARY_DIR}/${PINMAP_CSV}
        --package ${ADD_QUICKLOGIC_BOARD_FABRIC_PACKAGE}
        --techfile ${TECHFILE}
        --vpr-grid-map ${VPR_GRID_MAP_LOCATION}
      DEPENDS ${PINMAP_CSV_DEPS}
    )
  
    add_file_target(FILE ${PINMAP_CSV} GENERATED)

    # Set the board properties
    set_target_properties(
      ${BOARD}
      PROPERTIES
        PINMAP
        ${CMAKE_CURRENT_SOURCE_DIR}/${PINMAP_CSV}
        CLKMAP
        ${CMAKE_CURRENT_SOURCE_DIR}/${CLKMAP_CSV}
    )
  
    set_target_properties(
      dummy_${ARCH}_${DEVICE}_${PACKAGE}
      PROPERTIES
      PINMAP ${CMAKE_CURRENT_SOURCE_DIR}/${PINMAP_CSV}
      CLKMAP ${CMAKE_CURRENT_SOURCE_DIR}/${CLKMAP_CSV}
    )

    # Install board files
    define_ql_pinmap_csv_install_target(
      PART ${PART}
      BOARD ${BOARD}
      DEVICE_TYPE ${DEVICE_TYPE}
      DEVICE ${DEVICE}
      PACKAGE ${PACKAGE}
    )

  endif()

endfunction()
