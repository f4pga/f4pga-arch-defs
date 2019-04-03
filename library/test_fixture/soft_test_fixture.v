module SOFT_TEST_FIXTURE(
    input clk,
    output rst,

    // Test fixture port
    output [COUNTER_WIDTH-1:0] count,
    input [N_OUTPUTS-1:0] expected_output,
    input [N_OUTPUTS-1:0] actual_output,

    // UART port
    input uart_rx,
    output uart_tx
);

parameter BAUD_COUNTER = 25;
parameter BAUD_OVERSAMPLE = 8;
parameter MAX_COUNT = 15;
parameter COUNTER_WIDTH = $clog2(MAX_COUNT);
parameter N_OUTPUTS = 1;

wire uart_tx_data_ready;
wire uart_tx_data_accepted;
wire [7:0] uart_tx_data;
wire uart_tx_idle;

wire uart_rx_data_ready;
wire [7:0] uart_rx_data;
wire do_reset;
wire rst;
wire [COUNTER_WIDTH-1:0] count;
wire count_saturated;
wire error;

wire frame_tx_data_accepted;
wire frame_tx_idle;
wire [7:0] frame_tx_data;
wire frame_tx_data_ready;
wire frame_tx_start_of_new_frame;
wire frame_tx_end_of_frame;

UART #(
    .COUNTER(BAUD_COUNTER),
    .OVERSAMPLE(BAUD_OVERSAMPLE)
) uart (
    .rst(rst),
    .clk(clk),
    .rx(uart_rx),
    .tx(uart_tx),
    .tx_data_ready(uart_tx_data_ready),
    .tx_data(uart_tx_data),
    .tx_data_accepted(uart_tx_data_accepted),
    .tx_idle(uart_tx_idle),

    .rx_data(uart_rx_data),
    .rx_data_ready(uart_rx_data_ready),
    .rx_framing_error()
);

RESET_CONTROLLER reset(
    .clk(clk),
    .rx_data_ready(uart_rx_data_ready),
    .rx_data(uart_rx_data),
    .do_reset(do_reset),
    .rst(rst)
);

SATURATING_COUNTER #(
    .MAX_COUNT(MAX_COUNT),
    .COUNTER_WIDTH(COUNTER_WIDTH)
) counter(
    .clk(clk),
    .rst(rst),
    .count(count),
    .saturated(count_saturated)
);

OUTPUT_COMPARATOR #(
    .N_OUTPUTS(N_OUTPUTS)
) comp(
    .expected_output(expected_output),
    .actual_output(actual_output),
    .error(error)
);

OUTPUT_GENERATOR #(
    .N_OUTPUTS(N_OUTPUTS),
    .COUNTER_WIDTH(COUNTER_WIDTH),
    .STAT_WIDTH(STAT_WIDTH)
) output_gen(
    .clk(clk),
    .rst(rst),

    .count_saturated(count_saturated),
    .count(count),

    .error(error),
    .error_output(actual_output),

    .tx_data_accepted(frame_tx_data_accepted),
    .tx_idle(frame_tx_idle),

    .tx_data(frame_tx_data),
    .tx_data_ready(frame_tx_data_ready),
    .tx_start_of_new_frame(frame_tx_start_of_new_frame),
    .tx_end_of_frame(frame_tx_end_of_frame),

    .do_reset(do_reset)
);

FRAME_GENERATOR frame_gen(
    .clk(clk),
    .rst(rst),

    .frame_tx_data(frame_tx_data),
    .frame_tx_data_ready(frame_tx_data_ready),
    .frame_tx_start_of_new_frame(frame_tx_start_of_new_frame),
    .frame_tx_end_of_frame(frame_tx_end_of_frame),
    .frame_tx_data_accepted(frame_tx_data_accepted),
    .frame_tx_idle(frame_tx_idle),

    .uart_tx_data_accepted(uart_tx_data_accepted),
    .uart_tx_idle(uart_tx_idle),
    .uart_tx_data(uart_tx_data),
    .uart_tx_data_ready(uart_tx_data_ready)
);

endmodule
