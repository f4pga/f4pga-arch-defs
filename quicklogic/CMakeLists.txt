include(cmake/quicklogic_fasm.cmake)
add_quicklogic_fasm_package()

include(cmake/quicklogic_timings.cmake)

add_custom_target(QL_CELLS_SIM_DEPS)

include(cmake/cells_sim_gen.cmake)
add_subdirectory(primitives)

set(CELLS_MAP_FILE ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/techmap/cells_map.v)
set(CELLS_MAP_FILE_DEST_DIR ${symbiflow-arch-defs_BINARY_DIR}/quicklogic/techmap/)

# Link cells_map. to the binary dir.
file(MAKE_DIRECTORY ${CELLS_MAP_FILE_DEST_DIR})
file(CREATE_LINK ${CELLS_MAP_FILE} ${CELLS_MAP_FILE_DEST_DIR}/cells_map.v SYMBOLIC)

set(CELLS_SIM_FILE ${symbiflow-arch-defs_BINARY_DIR}/quicklogic/techmap/cells_sim.v)
add_cells_sim_target(${CELLS_SIM_FILE})

include(cmake/install.cmake)
include(cmake/quicklogic_device.cmake)
include(cmake/quicklogic_board.cmake)

include(cmake/quicklogic_jlink.cmake)

set(SDF_TIMING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/timings)
set(BELS_MAP ${CMAKE_CURRENT_SOURCE_DIR}/bels.json)

get_target_property_required(PYTHON3 env PYTHON3)
get_target_property_required(QLFASM env QLFASM)

get_target_property_required(QLFASM_TARGET env QLFASM_TARGET)

set(VPR_ARCH_ARGS "\
    --clock_modeling route \
    --place_delay_model delta_override \
    --router_lookahead map \
    --check_route quick \
    --strict_checks off \
    --allow_dangling_combinational_nodes on \
    --disable_errors check_unbuffered_edges:check_route \
    --congested_routing_iteration_threshold 0.8 \
    --incremental_reroute_delay_ripup off \
    --base_cost_type delay_normalized_length_bounded \
    --bb_factor 10 \
    --initial_pres_fac 4.0 \
    --check_rr_graph off \
    --suppress_warnings \${OUT_NOISY_WARNINGS},sum_pin_class:check_unbuffered_edges:load_rr_indexed_data_T_values:check_rr_node:trans_per_R:check_route:set_rr_graph_tool_comment "
    )
# Add the below option in the above variable to enable detailed timing report with routing delay information
#--timing_report_detail detailed

  set(YOSYS_SYNTH_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/yosys/synth.tcl)
  set(YOSYS_CONV_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/yosys/conv.tcl)

define_arch(
  ARCH ql-s3
  YOSYS_SYNTH_SCRIPT ${YOSYS_SYNTH_SCRIPT}
  YOSYS_CONV_SCRIPT ${YOSYS_CONV_SCRIPT}
  YOSYS_TECHMAP ${symbiflow-arch-defs_BINARY_DIR}/quicklogic/techmap
  DEVICE_FULL_TEMPLATE \${DEVICE}
  VPR_ARCH_ARGS ${VPR_ARCH_ARGS}

  # FIXME: Once the timing model works check why --router_lookahead connection_box_map does not.

  RR_PATCH_TOOL
    ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/utils/routing_import.py
  RR_PATCH_CMD "\${CMAKE_COMMAND} -E env \
    PYTHONPATH=${symbiflow-arch-defs_SOURCE_DIR}/utils:$PYTHONPATH \
    \${PYTHON3} \${RR_PATCH_TOOL} \
        --vpr-db ${CMAKE_CURRENT_BINARY_DIR}/devices/\${DEVICE_TYPE}/db_vpr.pickle \
        --rr-graph-in \${OUT_RRXML_VIRT} \
        --rr-graph-out \${OUT_RRXML_REAL}"

  PLACE_TOOL
    ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/utils/create_ioplace.py
  PLACE_TOOL_CMD "${CMAKE_COMMAND} -E env \
    PYTHONPATH=${symbiflow-arch-defs_SOURCE_DIR}/utils:$PYTHONPATH \
    \${PYTHON3} \${PLACE_TOOL} \
        --map \${PINMAP} \
        --blif \${OUT_EBLIF} \
        --pcf \${INPUT_IO_FILE} \
        --net \${OUT_NET}"

  FASM_TO_BIT
    ${QLFASM}
  FASM_TO_BIT_CMD "\${PYTHON3} \
    \${QLFASM} \
        \${OUT_FASM}
        \${OUT_BITSTREAM}
        \${FASM_TO_BIT_EXTRA_ARGS}"
  FASM_TO_BIT_DEPS
    ${QLFASM_TARGET}
  BITSTREAM_EXTENSION bit

  CELLS_SIM
    ${CELLS_SIM_FILE}

  NO_BIT_TO_BIN
  BIT_TO_V
    ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/utils/fasm2bels.py
  BIT_TO_V_CMD
    "${CMAKE_COMMAND} -E env PYTHONPATH=${symbiflow-arch-defs_SOURCE_DIR}/utils:$PYTHONPATH \
    \${PYTHON3} \${BIT_TO_V} \${OUT_BITSTREAM}
      --vpr-db ${CMAKE_CURRENT_BINARY_DIR}/devices/\${DEVICE_TYPE}/db_phy.pickle
      --package-name PD64
      --input-type bitstream
      --output-verilog \${OUT_BIT_VERILOG}
      --input-pcf \${INPUT_IO_FILE}"
  BIT_TO_V_DEPS
    ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/utils/verilogmodule.py
    ${CMAKE_CURRENT_BINARY_DIR}/devices/\${DEVICE_TYPE}/db_vpr.pickle
  NO_BIT_TIME
  NO_PLACE_CONSTR
  ROUTE_CHAN_WIDTH 100
  USE_FASM
)

define_ql_toolchain_target(
  ARCH ql-s3
  ROUTE_CHAN_WIDTH 100
  CELLS_SIM ${CELLS_SIM_FILE}
  VPR_ARCH_ARGS ${VPR_ARCH_ARGS}
  CONV_SCRIPT ${YOSYS_CONV_SCRIPT}
  SYNTH_SCRIPT ${YOSYS_SYNTH_SCRIPT})

unset(PYTHON3)

add_subdirectory(devices)
include(boards.cmake)
add_subdirectory(tests)
