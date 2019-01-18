get_target_property_required(OPENOCD env OPENOCD)
get_target_property_required(OPENOCD_TARGET env OPENOCD_TARGET)

#define_board(
#  BOARD basys3
#  DEVICE xc7a50t
#  PACKAGE test
#  PROG_TOOL ${OPENOCD_TARGET}
#  PROG_CMD "${OPENOCD} -f ${PRJXRAY_DIR}/utils/openocd/board-digilent-basys3.cfg -c \\\"init $<SEMICOLON> pld load 0 \${OUT_BIN} $<SEMICOLON> exit\\\""
#)


define_board(
  BOARD zybo
  DEVICE xc7z010
  PACKAGE test
  PROG_TOOL ${OPENOCD_TARGET}
  #  PROG_CMD "${OPENOCD} -f ${PRJXRAY_DIR}/utils/openocd/board-digilent-basys3.cfg -c \\\"init $<SEMICOLON> pld load 0 \${OUT_BIN} $<SEMICOLON> exit\\\""
)
