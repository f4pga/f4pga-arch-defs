function(ADD_QUICKLOGIC_BOARD)

  set(options)
  set(oneValueArgs BOARD DEVICE)
  set(multiValueArgs)
  cmake_parse_arguments(
     ADD_QUICKLOGIC_BOARD
     "${options}"
     "${oneValueArgs}"
     "${multiValueArgs}"
     ${ARGN}
    )

  define_board(
    BOARD ${ADD_QUICKLOGIC_BOARD_BOARD}
    DEVICE ${ADD_QUICKLOGIC_BOARD_DEVICE}
    PACKAGE wlcsp
    )

endfunction()
