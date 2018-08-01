mux_gen(
  NAME amult_mux
  COMMENT "DSP48E1 mux that select output to feed forward to A multipler"
  DATA_WIDTH 25
  INPUTS A,ADDER_OUT
  MUX_NAME AMULT_MUX
  SPLIT_INPUTS 1
  TYPE routing
  WIDTH 2
)
