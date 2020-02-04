include(cmake/quicklogic_fasm.cmake)
add_quicklogic_fasm_package()

include(cmake/cells_sim_gen.cmake)
add_cells_sim_target(techmap/cells_sim.v)

include(cmake/quicklogic_device.cmake)
include(cmake/quicklogic_board.cmake)

set(SDF_TIMING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/timings)
set(BELS_MAP ${CMAKE_CURRENT_SOURCE_DIR}/bels.json)

add_subdirectory(primitives)
add_subdirectory(tiles)

get_target_property_required(PYTHON3 env PYTHON3)
define_arch(
  ARCH ql-s3
  YOSYS_SYNTH_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/yosys/synth.tcl
  YOSYS_CONV_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/yosys/conv.tcl
  DEVICE_FULL_TEMPLATE \${DEVICE}
  VPR_ARCH_ARGS " \
    --router_init_wirelength_abort_threshold 20 \
    --place_algorithm bounding_box"

#  # FIXME: Skip patching the graph for now
#  RR_PATCH_TOOL
#    /bin/true
#  RR_PATCH_CMD "cp \${OUT_RRXML_VIRT} \${OUT_RRXML_REAL}"
  
  RR_PATCH_TOOL
    ${CMAKE_CURRENT_SOURCE_DIR}/utils/routing_import.py

  # FIXME: How to make that depend on db_vpr.pickle ??
  RR_PATCH_CMD "\${CMAKE_COMMAND} -E env PYTHONPATH=${symbiflow-arch-defs_SOURCE_DIR}/utils
    \${PYTHON3} \${RR_PATCH_TOOL} \
   --vpr-db ${CMAKE_CURRENT_BINARY_DIR}/devices/\${DEVICE_TYPE}/db_vpr.pickle \
   --rr-graph-in \${OUT_RRXML_VIRT} \
   --rr-graph-out \${OUT_RRXML_REAL}"

  NO_PINS
  NO_BITSTREAM
  NO_BIT_TO_V
  NO_BIT_TIME
  ROUTE_CHAN_WIDTH 100
  USE_FASM
)
unset(PYTHON3)

include(boards.cmake)

add_subdirectory(devices)
add_subdirectory(tests)
