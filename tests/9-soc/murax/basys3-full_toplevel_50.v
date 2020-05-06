`timescale 1ns / 1ps

module toplevel(
    input   clk,
    output  tx,
    input   rx,
    input [15:0] sw,
    output [15:0] io_led
  );

  wire clk100;
  BUFG bufg(.I(clk), .O(clk100));

  reg clk50;
  always @(posedge clk100)
    clk50 <= !clk50;

  wire [31:0] io_gpioA_read;
  wire [31:0] io_gpioA_write;
  wire [31:0] io_gpioA_writeEnable;
  wire io_mainClk;
  wire io_jtag_tck;
  wire io_jtag_tdi;
  wire io_jtag_tdo;
  wire io_jtag_tms;
  wire io_uart_txd;
  wire io_uart_rxd;

  assign io_led = io_gpioA_write[15: 0];
  assign io_gpioA_read[15:0] = sw;

  Murax murax (
    .io_asyncReset(0),
    .io_mainClk (clk50),
    .io_jtag_tck(1'b0),
    .io_jtag_tdi(1'b0),
    .io_jtag_tms(1'b0),
    .io_gpioA_read       (io_gpioA_read),
    .io_gpioA_write      (io_gpioA_write),
    .io_gpioA_writeEnable(io_gpioA_writeEnable),
    .io_uart_txd(tx),
    .io_uart_rxd(rx)
  );
endmodule
