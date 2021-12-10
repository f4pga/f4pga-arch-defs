`timescale 1ns/10ps
(* blackbox *)
module ASSP_RAM512X36B (
  input  wire        RAM_CLK,
  input  wire [3:0]  RAM_RM_af,
  input  wire        RAM_RME_af,
  input  wire [35:0] RAM_WR_DATA,
  input  wire [3:0]  RAM_WR_BE,
  input  wire        RAM_RD_EN,
  input  wire        RAM_WR_EN,
  input  wire        RAM_TEST1_af,
  input  wire [8:0]  RAM_ADDR,
  output wire [35:0] RAM_RD_DATA
);

endmodule
