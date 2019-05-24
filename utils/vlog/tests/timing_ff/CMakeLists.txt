add_file_target(FILE fdse.sim.v SCANNER_TYPE verilog)

v2x_test_both(
  NAME fdse
  TOP_MODULE fdse
  SDF_FILE prjxray-db/artix7/timings/CLBLL_L.sdf
  SDF_CELLS SLICEL/FF_INIT
)
