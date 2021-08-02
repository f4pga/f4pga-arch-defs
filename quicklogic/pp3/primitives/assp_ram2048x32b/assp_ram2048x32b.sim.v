`timescale 1ns/10ps
(* blackbox *)
module ASSP_RAM2048X32B (
  input  wire        RAM8K_P0_CLK,
  input  wire [16:0] RAM8K_P0_WR_DATA,
  input  wire [1:0]  RAM8K_P0_WR_BE,
  input  wire        RAM8K_P0_WR_EN,
  input  wire        RAM8K_TEST1_af,
  input  wire [11:0] RAM8K_P0_ADDR,
  input  wire        RAM8K_P1_CLK,
  input  wire [11:0] RAM8K_P1_ADDR,
  input  wire        RAM8K_P1_RD_EN,
  input  wire        RAM8K_fifo_en,
  output wire [16:0] RAM8K_P1_RD_DATA,
  output wire        RAM8K_fifo_almost_full,
  output wire [3:0]  RAM8K_fifo_full_flag,
  output wire        RAM8K_fifo_almost_empty,
  output wire [3:0]  RAM8K_fifo_empty_flag
);

endmodule
