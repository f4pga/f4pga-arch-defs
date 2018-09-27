set(ICESTORM ${symbiflow-arch-defs_SOURCE_DIR}/third_party/icestorm CACHE PATH "Path to icestorm repository")
find_program(ICEPROG_TOOL iceprog PATHS ${ICESTORM}/iceprog)
find_program(ICEBOX_HLC2ASC NAMES icebox_hlc2asc icebox_hlc2asc.py PATHS ${ICESTORM}/icebox)
find_program(ICEBOX_VLOG NAMES icebox_vlog icebox_vlog.py PATHS ${ICESTORM}/icebox)
find_program(ICEPACK icepack PATHS ${ICESTORM}/icepack)
find_program(ICETIME icetime PATHS ${ICESTORM}/icetime)

define_arch(
  ARCH ice40
  YOSYS_SCRIPT
    "synth_ice40 -nocarry $<SEMICOLON>  ice40_opt -unlut $<SEMICOLON> abc -lut 4 $<SEMICOLON>  opt_clean"
  DEVICE_FULL_TEMPLATE \${DEVICE}-\${PACKAGE}
  VPR_ARCH_ARGS
    --clock_modeling route
  RR_PATCH_TOOL
    ${symbiflow-arch-defs_SOURCE_DIR}/ice40/utils/ice40_import_routing_from_icebox.py
  RR_PATCH_CMD "\${QUIET_CMD} \${PYTHON3} \${RR_PATCH_TOOL} \
  --device=\${DEVICE} \
  --read_rr_graph \${OUT_RRXML_VIRT} \
  --write_rr_graph \${OUT_RRXML_REAL}"
  PLACE_TOOL
    ${symbiflow-arch-defs_SOURCE_DIR}/ice40/utils/ice40_create_ioplace.py
  PLACE_TOOL_CMD "\${PYTHON3} \${PLACE_TOOL} \
  --map \${PINMAP} \
  --blif \${OUT_EBLIF} \
  --pcf \${INPUT_IO_FILE}"
  CELLS_SIM ice40/cells_sim.v
  HLC_TO_BIT ${ICEBOX_HLC2ASC}
  HLC_TO_BIT_CMD "\${HLC_TO_BIT} \${OUT_HLC} > \${OUT_BITSTREAM}"
  BIT_TO_V ${ICEBOX_VLOG}
  BIT_TO_V_CMD "\${BIT_TO_V} -D -c -n \${TOP} -p \${INPUT_IO_FILE} -d \${PACKAGE} \${OUT_BITSTREAM} > \${OUT_BIT_VERILOG}"
  BITSTREAM_EXTENSION asc
  BIT_TO_BIN ${ICEPACK}
  BIT_TO_BIN_CMD "\${BIT_TO_BIN} \${OUT_BITSTREAM} > \${OUT_BIN}"
  BIT_TIME ${ICETIME}
  BIT_TIME_CMD "\${BIT_TIME} -v -t -p \${INPUT_IO_FILE} -d \${DEVICE} \${OUT_BITSTREAM} -o \${OUT_TIME_VERILOG}"
  ROUTE_CHAN_WIDTH 100
)

add_subdirectory(primitives)
add_subdirectory(cells)
add_subdirectory(devices)

include(boards.cmake)

add_subdirectory(tests)
