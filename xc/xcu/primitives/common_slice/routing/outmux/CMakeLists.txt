function(outmux outmux_inst)
  string(TOLOWER ${outmux_inst} outmux_inst_lower)

  mux_gen(
    NAME outmux${outmux_inst_lower}
    INPUTS F78,D6,D5
    MUX_NAME OUTMUX${outmux_inst}
    OUTPUT OUT
    SPLIT_INPUTS 1
    TYPE routing
    WIDTH 3
  )

endfunction()

outmux(A)
outmux(B)
outmux(C)
outmux(D)
outmux(E)
outmux(F)
outmux(G)
outmux(H)
