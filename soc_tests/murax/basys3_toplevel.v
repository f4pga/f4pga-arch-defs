`timescale 1ns / 1ps

module toplevel(
    input   io_mainClk,
    input   io_jtag_tck,
    input   io_jtag_tdi,
    output  io_jtag_tdo,
    input   io_jtag_tms,
    output  io_uart_txd,
    input   io_uart_rxd,
    output [7:0] io_led
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

  assign io_led = io_gpioA_write[7 : 0];

  Murax murax (
    .io_asyncReset(0),
    .io_mainClk (io_mainClk ),
    .io_jtag_tck(io_jtag_tck),
    .io_jtag_tdi(io_jtag_tdi),
    .io_jtag_tdo(io_jtag_tdo),
    .io_jtag_tms(io_jtag_tms),
    .io_gpioA_read       (io_gpioA_read),
    .io_gpioA_write      (io_gpioA_write),
    .io_gpioA_writeEnable(io_gpioA_writeEnable),
    .io_uart_txd(io_uart_txd),
    .io_uart_rxd(io_uart_rxd)
  );
endmodule
