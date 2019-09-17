get_target_property_required(OPENOCD env OPENOCD)
get_target_property_required(OPENOCD_TARGET env OPENOCD_TARGET)

define_board(
  BOARD basys3
  DEVICE xc7a50t-basys3
  PACKAGE test
  PROG_TOOL ${OPENOCD_TARGET}
  PROG_CMD "${OPENOCD} -f ${PRJXRAY_DIR}/utils/openocd/board-digilent-basys3.cfg -c \\\"init $<SEMICOLON> pld load 0 \${OUT_BIN} $<SEMICOLON> exit\\\""
)

define_board(
  BOARD arty-swbut
  DEVICE xc7a50t-arty-swbut
  PACKAGE test
  PROG_TOOL ${OPENOCD_TARGET}
  PROG_CMD "${OPENOCD} -f ${PRJXRAY_DIR}/utils/openocd/board-digilent-basys3.cfg -c \\\"init $<SEMICOLON> pld load 0 \${OUT_BIN} $<SEMICOLON> exit\\\""
)

define_board(
  BOARD arty
  DEVICE xc7a50t-arty
  PACKAGE test
)

# TODO: https://github.com/SymbiFlow/symbiflow-arch-defs/issues/344
define_board(
  BOARD zybo
  DEVICE xc7z010-zybo
  PACKAGE test
)
