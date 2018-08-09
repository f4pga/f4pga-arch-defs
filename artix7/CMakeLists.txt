include(make/project_xray.cmake)

add_subdirectory(primitives)
add_subdirectory(tiles)
add_subdirectory(blocks)

define_arch(
  ARCH artix7
  YOSYS_SCRIPT "synth_xilinx -vpr"
  DEVICE_FULL_TEMPLATE \${DEVICE}-\${PACKAGE}
  CELLS_SIM xilinx/cells_sim.v
  RR_PATCH_TOOL
    ${symbiflow-arch-defs_SOURCE_DIR}/artix7/utils/prjxray-routing-import.py
  RR_PATCH_CMD "${CMAKE_COMMAND} -E copy \${OUT_RRXML_VIRT} \${OUT_RRXML_REAL}"
  #RR_PATCH_CMD "\${RR_PATCH_TOOL}
  #  --database ${symbiflow-arch-defs_SOURCE_DIR}/third_party/prjxray-db/artix7/ \
  #  --start_x 35 --end_x 38 --start_y 1 --end_y 3"
  NO_PINS
  NO_BITSTREAM
)

add_subdirectory(devices)
