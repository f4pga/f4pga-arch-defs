define_board(BOARD icestick DEVICE hx1k PACKAGE tq144 PROG_TOOL ${ICEPROG_TOOL})

define_board(
  BOARD iceblink40-lp1k
  DEVICE lp1k
  PACKAGE qn84
  PROG_TOOL ${ICEPROG_TOOL}
  PROG_CMD ${ICEPROG_TOOL} -ew
)

define_board(
  BOARD hx8k-b-evn
  DEVICE hx8k
  PACKAGE ct256
  PROG_TOOL ${ICEPROG_TOOL}
  PROG_CMD ${ICEPROG_TOOL} -S
)

define_board(
  BOARD icevision
  DEVICE up5k
  PACKAGE sg48
  PROG_TOOL ${ICEPROG_TOOL}
)

