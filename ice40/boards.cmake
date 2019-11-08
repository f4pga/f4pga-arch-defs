get_target_property_required(ICEPROG env ICEPROG)
get_target_property(ICEPROG_TARGET env ICEPROG_TARGET)

function(define_ice40_board)
  set(options)
  set(oneValueArgs BOARD DEVICE PACKAGE PROG_TOOL PROG_CMD)
  set(multiValueArgs)
  cmake_parse_arguments(
    DEFINE_ICE40_BOARD
     "${options}"
     "${oneValueArgs}"
     "${multiValueArgs}"
     ${ARGN}
    )

  define_board(
    BOARD ${DEFINE_ICE40_BOARD_BOARD}
    DEVICE ${DEFINE_ICE40_BOARD_DEVICE}
    PACKAGE ${DEFINE_ICE40_BOARD_PACKAGE}
    PROG_TOOL ${DEFINE_ICE40_BOARD_PROG_TOOL}
    PROG_CMD ${DEFINE_ICE40_BOARD_PROG_PROG_CMD}
    )

  get_target_property_required(PACKAGE_PINMAP ${DEFINE_ICE40_BOARD_DEVICE} ${DEFINE_ICE40_BOARD_PACKAGE}_PINMAP)

  set_target_properties(
    ${DEFINE_ICE40_BOARD_BOARD}
    PROPERTIES
      PINMAP ${PACKAGE_PINMAP}
      )
endfunction()

# Lattice iCEstick
# http://www.latticesemi.com/icestick
# ---------------------------------------------
define_ice40_board(
  BOARD icestick
  DEVICE hx1k
  PACKAGE tq144
  PROG_TOOL ${ICEPROG_TARGET}
  PROG_CMD "${ICEPROG} \${OUT_BIN}"
  )

# Lattice iCEblink40-LP1K Evaluation Kit
# **HX** version is different!
# ---------------------------------------------
define_ice40_board(
  BOARD iceblink40-lp1k
  DEVICE lp1k
  PACKAGE qn84
  PROG_TOOL ${ICEPROG_TARGET}
  PROG_CMD "${ICEPROG} -ew \${OUT_BIN}"
)

if (NOT DEFINED ENV{CI} OR NOT $ENV{CI})

# iCE40-HX8K Breakout Board Evaluation Kit
# iCE40-HX8K-CT256
# ---------------------------------------------
define_ice40_board(
  BOARD hx8k-b-evn
  DEVICE hx8k
  PACKAGE ct256
  PROG_TOOL ${ICEPROG_TARGET}
  PROG_CMD "${ICEPROG} \${OUT_BIN}"
)

# DPControl icevision board
# iCE40UP5K-SG48
# ---------------------------------------------
define_ice40_board(
  BOARD icevision
  DEVICE up5k
  PACKAGE sg48
  PROG_TOOL ${ICEPROG_TARGET}
  PROG_CMD "${ICEPROG} \${OUT_BIN}"
)
add_conda_pip(
  NAME tinyfpgab
  )

get_target_property_required(TINYFPGAB env TINYFPGAB)
get_target_property(TINYFPGAB_TARGET env TINYFPGAB_TARGET)

# TinyFPGA B2
# iCE40-LP8K-CM81
# ---------------------------------------------
define_ice40_board(
  BOARD tinyfpga-b2
  DEVICE lp8k
  PACKAGE cm81
  PROG_TOOL ${TINYFPGAB_TARGET}
  PROG_CMD "${TINYFPGAB} --program \${OUT_BIN}"
)

add_conda_pip(
  NAME tinyprog
  )

get_target_property_required(TINYPROG env TINYPROG)
get_target_property(TINYPROG_TARGET env TINYPROG_TARGET)

# TinyFPGA BX
# iCE40-LP8K-CM81
# ---------------------------------------------
define_ice40_board(
  BOARD tinyfpga-bx
  DEVICE lp8k
  PACKAGE cm81
  PROG_TOOL ${TINYPROG_TARGET}
  PROG_CMD "${TINYPROG} -p \${OUT_BIN}"
)

endif (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
