# Lattice iCEstick
# http://www.latticesemi.com/icestick
# ---------------------------------------------
define_board(BOARD icestick DEVICE hx1k PACKAGE tq144 PROG_TOOL ${ICEPROG_TOOL})

# Lattice iCEblink40-LP1K Evaluation Kit
# **HX** version is different!
# ---------------------------------------------
define_board(
  BOARD iceblink40-lp1k
  DEVICE lp1k
  PACKAGE qn84
  PROG_TOOL ${ICEPROG_TOOL}
  PROG_CMD "${ICEPROG_TOOL} -ew"
)

# iCE40-HX8K Breakout Board Evaluation Kit
# iCE40-HX8K-CT256
# ---------------------------------------------
define_board(
  BOARD hx8k-b-evn
  DEVICE hx8k
  PACKAGE ct256
  PROG_TOOL ${ICEPROG_TOOL}
  PROG_CMD "${ICEPROG_TOOL} -S"
)

# DPControl icevision board
# iCE40UP5K-SG48
# ---------------------------------------------
define_board(
  BOARD icevision
  DEVICE up5k
  PACKAGE sg48
  PROG_TOOL ${ICEPROG_TOOL}
)
