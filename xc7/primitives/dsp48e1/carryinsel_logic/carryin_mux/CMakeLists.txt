mux_gen(
  NAME carryin_mux
  COMMENT "mux used in CARRYIN selection"
  INPUTS BYPASS,REG
  MUX_NAME CARRYIN_MUX
  SPLIT_INPUTS 1
  TYPE routing
  WIDTH 2
)
