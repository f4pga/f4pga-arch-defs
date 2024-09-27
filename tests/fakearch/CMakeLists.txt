add_subdirectory(primitives)
add_subdirectory(tiles)

get_target_property_required(PYTHON3 env PYTHON3)
define_arch(
  ARCH testarch
  YOSYS_SYNTH_SCRIPT ${f4pga-arch-defs_SOURCE_DIR}/testarch/yosys.tcl
  YOSYS_TECHMAP ${f4pga-arch-defs_SOURCE_DIR}/testarch/techmap
  DEVICE_FULL_TEMPLATE \${DEVICE}
  VPR_ARCH_ARGS " \
    --router_init_wirelength_abort_threshold 20 \
    --place_algorithm bounding_box"
  RR_PATCH_CMD "\${CMAKE_COMMAND} -E env PYTHONPATH=${f4pga-arch-defs_SOURCE_DIR}/utils
   \${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/utils/testarch_graph.py \
  --read_rr_graph \${OUT_RRXML_VIRT} \
  --write_rr_graph \${OUT_RRXML_REAL}"
  NO_PINS
  NO_PLACE_CONSTR
  NO_BITSTREAM
  NO_BIT_TO_V
  NO_BIT_TIME
  ROUTE_CHAN_WIDTH 100
  USE_FASM
)
unset(PYTHON3)

add_subdirectory(devices)
