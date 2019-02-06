add_subdirectory(primitives)
add_subdirectory(tiles)

get_target_property_required(PYTHON3 env PYTHON3)
define_arch(
  ARCH testarch
  YOSYS_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/testarch/yosys/synth.tcl
  DEVICE_FULL_TEMPLATE \${DEVICE}
  RR_PATCH_TOOL
    ${symbiflow-arch-defs_SOURCE_DIR}/utils/testarch_graph.py
  RR_PATCH_CMD "\${PYTHON3} \${RR_PATCH_TOOL} \
  --read_rr_graph \${OUT_RRXML_VIRT} \
  --write_rr_graph \${OUT_RRXML_REAL}"
  NO_PINS
  NO_BITSTREAM
  NO_BIT_TO_V
  NO_BIT_TIME
  ROUTE_CHAN_WIDTH 100
)
unset(PYTHON3)

add_subdirectory(devices)
