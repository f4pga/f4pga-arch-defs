add_file_target(FILE fdce.sim.v SCANNER_TYPE verilog)

v2x_test_both(
  NAME fdce
  TOP_MODULE fdce
  SDF_FILE prjxray-db/artix7/timings/CLBLL_L.sdf
  SDF_CELLS SLICEL/FF_INIT SLICEL/FF_INIT_QL
)
