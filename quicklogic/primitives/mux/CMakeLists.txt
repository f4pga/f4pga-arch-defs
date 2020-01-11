mux_gen(
  NAME mux
  INPUTS I0,I1
  OUTPUT O
  MUX_NAME MUX
  SPLIT_INPUTS 1
  TYPE logic
  WIDTH 2
)

add_to_cells_sim(mux.sim.v)
