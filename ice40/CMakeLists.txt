set(ICESTORM ${symbiflow-arch-defs_SOURCE_DIR}/third_party/icestorm)
set(ICEBOX ${ICESTORM}/icebox/)

define_arch(
  ARCH ice40
  YOSYS_SCRIPT
    "synth_ice40 -nocarry $<SEMICOLON>  ice40_opt -unlut $<SEMICOLON> abc -lut 4 $<SEMICOLON>  opt_clean"
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
  EQUIV_CHECK_SCRIPT
    "hierarchy; proc; clk2fflogic; miter -equiv -flatten -ignore_gold_x -make_outputs -make_outcmp gold gate miter; sat -verify-no-timeout -timeout 600 -seq 1000 -prove trigger 0 -prove-skip 1 -show-inputs -show-outputs miter"
  HLC_TO_BIT ${ICEBOX}/icebox_hlc2asc.py
  HLC_TO_BIT_CMD "\${HLC_TO_BIT} \${OUT_HLC} > \${OUT_BITSTREAM}"
  BIT_TO_V ${ICEBOX}/icebox_vlog.py
  BIT_TO_V_CMD "\${BIT_TO_V} -D -c -n \${TOP} -p \${INPUT_IO_FILE} -d \${PACKAGE} \${OUT_BITSTREAM} > \${OUT_BIT_VERILOG} || rm \${OUT_BIT_VERILOG}"
  BITSTREAM_EXTENSION asc
)

add_subdirectory(primitives)
add_subdirectory(cells)
add_subdirectory(devices)

define_board(BOARD icestick DEVICE hx1k PACKAGE tq144 PROG_TOOL ${ICEPROG_TOOL})

define_board(
  BOARD iceblink40-lp1k
  DEVICE lp1k
  PACKAGE qn84
  PROG_TOOL ${ICEPROG_TOOL}
  PROG_CMD $${PROG_TOOL}} -ew
)

define_board(
  BOARD hx8k-b-evn
  DEVICE hx8k
  PACKAGE ct256
  PROG_TOOL ${ICEPROG_TOOL}
  PROG_CMD $${PROG_TOOL}} -S
)

add_subdirectory(tests)
