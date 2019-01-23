function(ADD_XC7_ARCH_DEFINE)
  set(options)
  set(oneValueArgs ARCH YOSYS_SCRIPT)
  set(multiValueArgs)
  cmake_parse_arguments(
    ADD_XC7_ARCH_DEFINE
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(ARCH ${ADD_XC7_ARCH_DEFINE_ARCH})
  set(YOSYS_SCRIPT ${ADD_XC7_ARCH_DEFINE_YOSYS_SCRIPT})

  project_xray_prepare_database(
    PART ${ARCH}
  )

  define_arch(
	  ARCH ${ARCH}
    YOSYS_SCRIPT ${YOSYS_SCRIPT}
    DEVICE_FULL_TEMPLATE \${DEVICE}-\${PACKAGE}
    CELLS_SIM xilinx/cells_sim.v
    RR_PATCH_TOOL
      ${symbiflow-arch-defs_SOURCE_DIR}/xc7/utils/prjxray_routing_import.py
    RR_PATCH_CMD "${CMAKE_COMMAND} -E env \
    PYTHONPATH=${PRJXRAY_DIR}:${symbiflow-arch-defs_SOURCE_DIR}/utils:${symbiflow-arch-defs_BINARY_DIR}/utils \
    \${PYTHON3} \${RR_PATCH_TOOL} \
	  --db_root ${PRJXRAY_DB_DIR}/${ARCH} \
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
	  --db-root ${PRJXRAY_DB_DIR}/${ARCH} \
    --sparse \
    \${OUT_FASM} \${OUT_BITSTREAM}"
    BIT_TO_BIN xc7patch
    BIT_TO_BIN_CMD "xc7patch \
    --part_name ${ROI_PART} \
	  --part_file ${PRJXRAY_DB_DIR}/${ARCH}/${ROI_PART}.yaml \
    --bitstream_file ${ROI_DIR}/design.bit \
    --frm_file \${OUT_BITSTREAM} \
    --output_file \${OUT_BIN}"
    NO_BIT_TO_V
    NO_BIT_TIME
    USE_FASM
    RR_GRAPH_EXT ".xml"
    ROUTE_CHAN_WIDTH 500
  )

  set(VPR_ARCH_ARGS
   --clock_modeling route
   --place_algorithm bounding_box
   --enable_timing_computations off
   --allow_unrelated_clustering on
   )

  set_target_properties(${ARCH} PROPERTIES VPR_ARCH_ARGS "${VPR_ARCH_ARGS}")
endfunction()
