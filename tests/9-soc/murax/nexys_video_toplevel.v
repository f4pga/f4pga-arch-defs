`timescale 1ns / 1ps

module top (
    input  clk,
    output tx,
    input  rx,
    input  [7:0] sw,
    output [7:0] led
  );

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

  assign led = io_gpioA_write[7: 0];
  assign io_gpioA_read[7:0] = sw;

  wire clk_bufg;
  BUFG bufg (.I(io_mainClk), .O(clk_bufg));

  Murax murax (
    .io_asyncReset(0),
    .io_mainClk (clk_bufg),
    .io_jtag_tck(1'b0),
    .io_jtag_tdi(1'b0),
    .io_jtag_tms(1'b0),
    .io_gpioA_read       (io_gpioA_read),
    .io_gpioA_write      (io_gpioA_write),
    .io_gpioA_writeEnable(io_gpioA_writeEnable),
    .io_uart_txd(txd),
    .io_uart_rxd(rxd)
  );
endmodule
