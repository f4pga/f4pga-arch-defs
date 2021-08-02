`timescale 1ns/10ps
(* blackbox *)
module ASSP_RAM4096X17 (
  input  wire        RAM_P0_CLK,
  input  wire [16:0] RAM_P0_WR_DATA,
  input  wire [1:0]  RAM_P0_WR_BE,
  input  wire        RAM_P0_WR_EN,
  input  wire        RAM_TEST1_af,
  input  wire [11:0] RAM_P0_ADDR,
  input  wire        RAM_P1_CLK,
  input  wire [11:0] RAM_P1_ADDR,
  input  wire        RAM_P1_RD_EN,
  input  wire        RAM_fifo_en,
  output wire [16:0] RAM_P1_RD_DATA,
  output wire        RAM_fifo_almost_full,
  output wire [3:0]  RAM_fifo_full_flag,
  output wire        RAM_fifo_almost_empty,
  output wire [3:0]  RAM_fifo_empty_flag
);

endmodule
