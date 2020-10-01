function(ffmux ffmux_inst ffmux_num)
  string(TOLOWER ${ffmux_inst} ffmux_inst_lower)

  mux_gen(
    NAME ffmux${ffmux_inst_lower}${ffmux_num}
    INPUTS F78,D6,D5,BYP
    MUX_NAME FFMUX${ffmux_inst}${ffmux_num}
    OUTPUT OUT
    SPLIT_INPUTS 1
    TYPE routing
    WIDTH 4
  )

endfunction()

ffmux(A 1)
ffmux(A 2)

ffmux(B 1)
ffmux(B 2)

ffmux(C 1)
ffmux(C 2)

ffmux(D 1)
ffmux(D 2)

ffmux(E 1)
ffmux(E 2)

ffmux(F 1)
ffmux(F 2)

ffmux(G 1)
ffmux(G 2)

ffmux(H 1)
ffmux(H 2)
