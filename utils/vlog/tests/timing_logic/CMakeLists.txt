add_file_target(FILE carry4_vpr.sim.v SCANNER_TYPE verilog)

v2x_test_both(
  NAME carry4_vpr
  TOP_MODULE carry4_vpr
  SDF_FILE prjxray-db/artix7/timings/CLBLL_L.sdf
  SDF_CELLS SLICEL/CARRY4 SLICEL/CARRY4_O5
)
