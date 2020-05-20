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
  set(PACKAGE ${ADD_QUICKLOGIC_BOARD_PACKAGE})
  set(BOARD ${ADD_QUICKLOGIC_BOARD_BOARD})

  # Get the database location
  get_target_property_required(VPR_DB_FILE ${DEVICE_TYPE} VPR_DB_FILE)
  get_file_location(VPR_DB_FILE_LOC ${VPR_DB_FILE})

  # Generate pinmap CSV file
  set(CREATE_PINMAP_CSV ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/utils/create_pinmap_csv.py)
  set(PINMAP_CSV ${BOARD}_pinmap.csv)
  set(PINMAP_CSV_DEPS ${PYTHON3} ${PYTHON3_TARGET} ${CREATE_PINMAP_CSV})
  append_file_dependency(PINMAP_CSV_DEPS ${VPR_DB_FILE})

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
  )

  set_target_properties(
    dummy_${ARCH}_${DEVICE}_${PACKAGE}
    PROPERTIES
    PINMAP ${CMAKE_CURRENT_SOURCE_DIR}/${PINMAP_CSV}
  )
  define_ql_pinmap_csv_install_target(
    PART ${PART}
    BOARD ${BOARD}
    DEVICE_TYPE ${DEVICE_TYPE}
    DEVICE ${DEVICE}
    PACKAGE ${PACKAGE}
    )

endfunction()
