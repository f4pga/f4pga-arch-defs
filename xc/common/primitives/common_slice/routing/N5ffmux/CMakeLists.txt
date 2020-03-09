mux_gen(
  NAME ntemplate.N5ffmux
  COMMENT "MUX on inputs to N5FF inputs."
  INPUTS IN_B,IN_A
  MUX_NAME {N}5FFMUX
  NTEMPLATE_PREFIXES a;b;c;d
  SPLIT_INPUTS 1
  TYPE routing
  WIDTH 2
)
