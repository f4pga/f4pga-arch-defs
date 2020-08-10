get_target_property_required(OPENOCD env OPENOCD)
get_target_property_required(OPENOCD_TARGET env OPENOCD_TARGET)

add_xc_board(
  BOARD ultra96v2
  DEVICE xczu3eg
  PACKAGE test
  PROG_TOOL ${OPENOCD_TARGET}
  PROG_CMD "${OPENOCD} -f ${PRJXRAY_DIR}/utils/openocd/avnet_ultra96v2.cfg & $<SEMICOLON> gdb --command=${PRJXRAY_DIR}/utils/openocd/load_script.gdb $<SEMICOLON> kill %1"
  PART xczu3eg-sbva484-1-e
)

