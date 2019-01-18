add_subdirectory(xc7z010-roi-virt)

# SYNTH_TILES used in ROI.
set(CHANNELS ${symbiflow-arch-defs_SOURCE_DIR}/xc7/channels.json)
set(SYNTH_TILES ${CMAKE_CURRENT_SOURCE_DIR}/xc7z010-roi-virt/synth_tiles.json)
message(${SYNTH_TILES})
get_file_location(SYNTH_TILES_LOCATION ${SYNTH_TILES})
get_file_location(CHANNELS_LOCATIONS ${CHANNELS})

append_file_dependency(DEVICE_RR_PATCH_DEPS ${CHANNELS})
append_file_dependency(DEVICE_RR_PATCH_DEPS ${SYNTH_TILES})

add_conda_pip(
  NAME textx
  NO_EXE
  )

list(APPEND DEVICE_RR_PATCH_DEPS intervaltree textx)

define_device(
  DEVICE xc7z010
  ARCH zynq7
  DEVICE_TYPE xc7z010-roi-virt
  PACKAGES test
  RR_PATCH_EXTRA_ARGS --synth_tiles ${SYNTH_TILES_LOCATION} --channels ${CHANNELS_LOCATIONS}
  RR_PATCH_DEPS ${DEVICE_RR_PATCH_DEPS}
  )

get_target_property_required(PYTHON3 env PYTHON3)
get_target_property_required(PYTHON3_TARGET env PYTHON3_TARGET)

set(SYNTH_TILES_TO_PINMAP_CSV ${symbiflow-arch-defs_SOURCE_DIR}/xc7/utils/prjxray_synth_tiles_to_pinmap_csv.py)
set(PINMAP_CSV xc7z010-roi-virt/synth_tiles_pinmap.csv)

set(PINMAP_CSV_DEPS ${PYTHON3} ${PYTHON3_TARGET} ${SYNTH_TILES_TO_PINMAP_CSV})
append_file_dependency(PINMAP_CSV_DEPS ${SYNTH_TILES})
add_custom_command(
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${PINMAP_CSV}
  COMMAND ${PYTHON3} ${SYNTH_TILES_TO_PINMAP_CSV}
    --synth_tiles ${SYNTH_TILES_LOCATION}
    --output ${CMAKE_CURRENT_BINARY_DIR}/${PINMAP_CSV}
    DEPENDS ${PINMAP_CSV_DEPS}
    )

add_file_target(FILE ${PINMAP_CSV} GENERATED)

set_target_properties(
  xc7z010
  PROPERTIES
    test_PINMAP
    ${CMAKE_CURRENT_SOURCE_DIR}/${PINMAP_CSV}
)
