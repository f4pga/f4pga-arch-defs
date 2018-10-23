define_board(
  BOARD basys3
  DEVICE xc7a50t
  PACKAGE test
  PROG_TOOL openocd
  PROG_CMD "openocd -f ${PRJXRAY_DIR}/utils/openocd/board-digilent-basys3.cfg -c \"init; pld load 0 \${OUT_BIN}; exit\""
)
