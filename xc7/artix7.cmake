include(make/project_xray.cmake)

add_subdirectory(primitives)

# Convert prjxray database into VPR channels, pin definitions for tile types,
# and create direct connection list for arch.xml.
project_xray_prepare_database(
  PART artix7
  )

set(ROI_PART xc7a35tcpg236-1)
set(ROI_DIR ${PRJXRAY_DB_DIR}/artix7/harness/basys3/swbut)

add_subdirectory(tiles)
add_subdirectory(blocks)


define_arch(
  ARCH artix7
  # -flatten is used to ensure that the output eblif has only one module.
  # Some of symbiflow expects eblifs with only one module.
  #
  # opt -undriven makes sure all nets are driven, if only by the $undef
  # net.
  YOSYS_SCRIPT "synth_xilinx -vpr -flatten $<SEMICOLON> opt_expr -undriven $<SEMICOLON> opt_clean"
  DEVICE_FULL_TEMPLATE \${DEVICE}-\${PACKAGE}
  CELLS_SIM xilinx/cells_sim.v
  RR_PATCH_TOOL
    ${symbiflow-arch-defs_SOURCE_DIR}/xc7/utils/prjxray_routing_import.py
  RR_PATCH_CMD "${CMAKE_COMMAND} -E env \
  PYTHONPATH=${PRJXRAY_DIR}:${symbiflow-arch-defs_SOURCE_DIR}/utils:${symbiflow-arch-defs_BINARY_DIR}/utils \
  \${PYTHON3} \${RR_PATCH_TOOL} \
  --db_root ${PRJXRAY_DB_DIR}/artix7 \
  --read_rr_graph \${OUT_RRXML_VIRT} \
  --write_rr_graph \${OUT_RRXML_REAL}"
  PLACE_TOOL
    ${symbiflow-arch-defs_SOURCE_DIR}/xc7/utils/prjxray_create_ioplace.py
  PLACE_TOOL_CMD "${CMAKE_COMMAND} -E env \
  PYTHONPATH=${symbiflow-arch-defs_SOURCE_DIR}/utils \
  \${PYTHON3} \${PLACE_TOOL} \
  --map \${PINMAP} \
  --blif \${OUT_EBLIF} \
  --pcf \${INPUT_IO_FILE}"
  BITSTREAM_EXTENSION frames
  BIN_EXTENSION bit
  FASM_TO_BIT ${PRJXRAY_DIR}/utils/fasm2frames.py
  FASM_TO_BIT_CMD "${CMAKE_COMMAND} -E env \
  PYTHONPATH=${PRJXRAY_DIR}:${PRJXRAY_DIR}/third_party/fasm \
  \${PYTHON3} \${FASM_TO_BIT} \
  --db-root ${PRJXRAY_DB_DIR}/artix7  \
  --sparse \
  \${OUT_FASM} \${OUT_BITSTREAM}"
  BIT_TO_BIN xc7patch
  BIT_TO_BIN_CMD "xc7patch \
  --part_name ${ROI_PART} \
  --part_file ${PRJXRAY_DB_DIR}/artix7/${ROI_PART}.yaml \
  --bitstream_file ${ROI_DIR}/design.bit \
  --frm_file \${OUT_BITSTREAM} \
  --output_file \${OUT_BIN}"
  NO_BIT_TO_V
  NO_BIT_TIME
  USE_FASM
  RR_GRAPH_EXT ".xml"
  ROUTE_CHAN_WIDTH 500
)

set(VPR_ARTIX7_ARCH_ARGS
 --clock_modeling route
 --place_algorithm bounding_box
 --enable_timing_computations off
 --allow_unrelated_clustering on
 )

set_target_properties(artix7 PROPERTIES VPR_ARCH_ARGS "${VPR_ARTIX7_ARCH_ARGS}")

add_subdirectory(devices)
include(boards.cmake)
add_subdirectory(tests)
