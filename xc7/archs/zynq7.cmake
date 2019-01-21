set(ROI_PART xc7z010clg400-1)
set(ROI_DIR ${PRJXRAY_DB_DIR}/zynq7/harness/zybo/swbut)

#project_xray_prepare_database(
  #  PART zynq7
  #)

add_arch_define(
  ARCH zynq7
  ROI_PART ${ROI_PART}
  ROI_DIR ${ROI_DIR}
  YOSYS_SCRIPT "synth_xilinx -vpr -flatten $<SEMICOLON> opt_expr -undriven $<SEMICOLON> opt_clean"
)
