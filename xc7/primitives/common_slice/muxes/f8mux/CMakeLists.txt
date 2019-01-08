mux_gen(
  NAME f8mux
  COMMENT
    "F8MUX is used to create a LUT8 from two LUT7s (which are built out of two LUT6s themselves)."
  MUX_NAME F8MUX
  INPUTS I0,I1
  OUTPUT O
  SELECTS S
  SUBCKT MUXF8
  SPLIT_INPUTS
  1
  SPLIT_SELECTS
  1
  TYPE logic
  WIDTH 2
)
