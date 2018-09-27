mux_gen(
  NAME f6mux
  COMMENT
    "MUX which is used to create a LUT6 from two LUT5s"
  MUX_NAME F6MUX
  INPUTS I0,I1
  OUTPUT O
  SELECTS S
  SUBCKT MUXF6
  SPLIT_INPUTS
  1
  SPLIT_SELECTS
  1
  TYPE logic
  WIDTH 2
)
