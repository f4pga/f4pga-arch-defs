get_target_property_required(OPENOCD env OPENOCD)
get_target_property_required(OPENOCD_TARGET env OPENOCD_TARGET)

add_xc_board(
  BOARD basys3
  DEVICE xc7a50t-basys3
  PACKAGE test
  PROG_TOOL ${OPENOCD_TARGET}
  PROG_CMD "${OPENOCD} -f ${PRJXRAY_DIR}/utils/openocd/board-digilent-basys3.cfg -c \\\"init $<SEMICOLON> pld load 0 \${OUT_BIN} $<SEMICOLON> exit\\\""
  PART xc7a35tcpg236-1
)

add_xc_board(
  BOARD basys3-full
  DEVICE xc7a50t
  PACKAGE test
  PROG_TOOL ${OPENOCD_TARGET}
  PROG_CMD "${OPENOCD} -f ${PRJXRAY_DIR}/utils/openocd/board-digilent-basys3.cfg -c \\\"init $<SEMICOLON> pld load 0 \${OUT_BIN} $<SEMICOLON> exit\\\""
  PART xc7a35tcpg236-1
)

add_xc_board(
  BOARD basys3-bottom
  DEVICE xc7a50t-bottom
  PACKAGE test
  PROG_TOOL ${OPENOCD_TARGET}
  PROG_CMD "${OPENOCD} -f ${PRJXRAY_DIR}/utils/openocd/board-digilent-basys3.cfg -c \\\"init $<SEMICOLON> pld load 0 \${OUT_BIN} $<SEMICOLON> exit\\\""
  PART xc7a35tcpg236-1
)

add_xc_board(
  BOARD arty-swbut
  DEVICE xc7a50t-arty-swbut
  PACKAGE test
  PROG_TOOL ${OPENOCD_TARGET}
  PROG_CMD "${OPENOCD} -f ${PRJXRAY_DIR}/utils/openocd/board-digilent-basys3.cfg -c \\\"init $<SEMICOLON> pld load 0 \${OUT_BIN} $<SEMICOLON> exit\\\""
  PART xc7a35tcsg324-1
)

add_xc_board(
  BOARD arty-uart
  DEVICE xc7a50t-arty-uart
  PACKAGE test
  PROG_TOOL ${OPENOCD_TARGET}
  PROG_CMD "${OPENOCD} -f ${PRJXRAY_DIR}/utils/openocd/board-digilent-basys3.cfg -c \\\"init $<SEMICOLON> pld load 0 \${OUT_BIN} $<SEMICOLON> exit\\\""
  PART xc7a35tcsg324-1
)

add_xc_board(
  BOARD arty-full
  DEVICE xc7a50t
  PACKAGE test
  PROG_TOOL ${OPENOCD_TARGET}
  PROG_CMD "${OPENOCD} -f ${PRJXRAY_DIR}/utils/openocd/board-digilent-basys3.cfg -c \\\"init $<SEMICOLON> pld load 0 \${OUT_BIN} $<SEMICOLON> exit\\\""
  PART xc7a35tcsg324-1
)

add_xc_board(
  BOARD arty100t-full
  DEVICE xc7a100t
  PACKAGE test
  PROG_TOOL ${OPENOCD_TARGET}
  PROG_CMD "${OPENOCD} -f ${PRJXRAY_DIR}/utils/openocd/board-digilent-basys3.cfg -c \\\"init $<SEMICOLON> pld load 0 \${OUT_BIN} $<SEMICOLON> exit\\\""
  PART xc7a100tcsg324-1
)

# TODO: https://github.com/SymbiFlow/symbiflow-arch-defs/issues/344
add_xc_board(
  BOARD zybo
  DEVICE xc7z010-zybo
  PACKAGE test
  PART xc7z010clg400-1
)

add_xc_board(
  BOARD zybo-full
  DEVICE xc7z010
  PACKAGE test
  PART xc7z010clg400-1
)

#add_xc_board(
#  BOARD zyboz7-full
#  DEVICE xc7z020
#  PACKAGE test
#  PART xc7z020clg400-1
#)

add_xc_board(
  BOARD nexys_video
  DEVICE xc7a200t
  PACKAGE test
  PART xc7a200tsbg484-1
  PROG_TOOL ${OPENOCD_TARGET}
  PROG_CMD "${OPENOCD} -f board/digilent_nexys_video.cfg -c \\\"init $<SEMICOLON> pld load 0 \${OUT_BIN} $<SEMICOLON> exit\\\""
)

