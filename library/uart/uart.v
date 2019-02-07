// Bi-direction UART.
module UART (
    input rst,
    // IO ports
    input clk,
    input rx,
    output tx,
    // Tx data port
    input tx_data_ready,
    input [7:0] tx_data,
    output tx_data_accepted,
    // Rx data port
    output [7:0] rx_data,
    output rx_data_ready,
    output rx_framing_error
);
    // COUNTER*OVERSAMPLE == effective baud rate.
    //
    // So given a 100 MHz clock (100000000), an 8x oversample and a counter
    // of 25, (100000000/(8*25)) => 500000 baud.
    //
    // BAUDGEN generates an edge COUNTER clock cycles.
    // Two BAUDGEN's are used, one for the Tx which is at the baudrate, and
    // one for the Rx which is at OVERSAMPLE times the baudrate.
    parameter COUNTER = 25;
    parameter OVERSAMPLE = 8;

    wire tx_baud_edge;
    wire rx_baud_edge;

    BAUDGEN #(.COUNTER(COUNTER*OVERSAMPLE)) tx_baud (
        .clk(clk),
        .rst(rst),
        .baud_edge(tx_baud_edge)
    );

    UART_TX tx_gen(
        .rst(rst),
        .clk(clk),
        .baud_edge(tx_baud_edge),
        .data_ready(tx_data_ready),
        .data(tx_data),
        .tx(tx),
        .data_accepted(tx_data_accepted)
    );

    BAUDGEN #(.COUNTER(COUNTER)) rx_baud (
        .clk(clk),
        .rst(rst),
        .baud_edge(rx_baud_edge)
    );

    UART_RX rx_gen(
        .rst(rst),
        .clk(clk),
        .baud_edge(rx_baud_edge),
        .rx(rx),
        .data(rx_data),
        .data_ready(rx_data_ready),
        .framing_error(rx_framing_error)
    );
endmodule
