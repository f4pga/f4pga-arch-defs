set(ICESTORM ${symbiflow-arch-defs_SOURCE_DIR}/third_party/icestorm)
set(ICEBOX ${ICESTORM}/icebox/)
set(ICEPROG_TOOL ${ICESTORM}/iceprog/iceprog)

define_arch(
  ARCH ice40
  YOSYS_SCRIPT
    "synth_ice40 -nocarry $<SEMICOLON>  ice40_opt -unlut $<SEMICOLON> abc -lut 4 $<SEMICOLON>  opt_clean"
  DEVICE_FULL_TEMPLATE \${DEVICE}-\${PACKAGE}
  VPR_ARCH_ARGS
    --clock_modeling route
  RR_PATCH_TOOL
    ${symbiflow-arch-defs_SOURCE_DIR}/ice40/utils/ice40_import_routing_from_icebox.py
  RR_PATCH_CMD "\${RR_PATCH_TOOL} \
  --device=\${DEVICE} \
  --read_rr_graph \${OUT_RRXML_VIRT} \
  --write_rr_graph \${OUT_RRXML_REAL}"
  PLACE_TOOL
    ${symbiflow-arch-defs_SOURCE_DIR}/ice40/utils/ice40_create_ioplace.py
  PLACE_TOOL_CMD "\${PLACE_TOOL} \
  --map \${PINMAP} \
  --blif \${OUT_EBLIF} \
  --pcf \${INPUT_IO_FILE}"
  CELLS_SIM ice40/cells_sim.v
  HLC_TO_BIT ${ICEBOX}/icebox_hlc2asc.py
  HLC_TO_BIT_CMD "\${HLC_TO_BIT} \${OUT_HLC} > \${OUT_BITSTREAM}"
  BIT_TO_V ${ICEBOX}/icebox_vlog.py
  BIT_TO_V_CMD "\${BIT_TO_V} -D -c -n \${TOP} -p \${INPUT_IO_FILE} -d \${PACKAGE} \${OUT_BITSTREAM} > \${OUT_BIT_VERILOG}"
  BITSTREAM_EXTENSION asc
  BIT_TO_BIN ${ICESTORM}/icepack/icepack
  BIT_TO_BIN_CMD "\${BIT_TO_BIN} \${OUT_BITSTREAM} > \${OUT_BIN}"
  BIT_TIME ${ICESTORM}/icetime/icetime
  BIT_TIME_CMD "\${BIT_TIME} -v -t -p \${INPUT_IO_FILE} -d \${DEVICE} \${OUT_BITSTREAM} -o \${OUT_TIME_VERILOG}"
)

add_subdirectory(primitives)
add_subdirectory(cells)
add_subdirectory(devices)

include(boards.cmake)

add_subdirectory(tests)
