set(ROI_PART xc7a35tcpg236-1)
set(ROI_DIR ${PRJXRAY_DB_DIR}/artix7/harness/basys3/swbut)

project_xray_prepare_database(
  PART artix7
)

add_arch_define(
  ARCH artix7
  ROI_PART ${ROI_PART}
  ROI_DIR ${ROI_DIR}
  YOSYS_SCRIPT "synth_xilinx -vpr -flatten $<SEMICOLON> opt_expr -undriven $<SEMICOLON> opt_clean"
)
