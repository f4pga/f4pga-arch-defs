`timescale 1ns/10ps
(* blackbox *)
module ASSP_RAM512X32B (
  input  wire        RAM_P0_CLK,
  input  wire [3:0]  RAM_RM_af,
  input  wire        RAM_RME_af,
  input  wire [31:0] RAM_P0_WR_DATA,
  //input  wire [3:0]  RAM_P0_WR_BE,
  input  wire        RAM_P0_WR_EN,
  input  wire        RAM_TEST1_af,
  input  wire [8:0]  RAM_P0_ADDR,
  input  wire [8:0]  RAM_P1_ADDR,
  input  wire        RAM_P1_CLK,
  input  wire        RAM_P1_RD_EN,
  output wire [31:0] RAM_P1_RD_DATA
);

endmodule
