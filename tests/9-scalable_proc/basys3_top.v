module top
(
input  wire         clk,

output wire         ser_tx,
input  wire         ser_rx,

input wire [15:0]   sw,
output wire [15:0]  led
);

// ============================================================================

reg rst = 1;
reg rst1 = 1;
reg rst2 = 1;
reg rst3 = 1;
assign led[0] = rst;
assign led[13:1] = sw[13:1];
assign led[14] = ^sw;
assign led[15] = ser_rx;

always @(posedge clk) begin
    rst3 <= 0;
    rst2 <= rst3;
    rst1 <= rst2;
    rst <= rst1;
end

// ============================================================================
//
scalable_proc #
(
.NUM_PROCESSING_UNITS   (2),
.UART_PRESCALER         ((100000000) / (500000))
)
scalable_proc
(
.CLK        (clk),
.RST        (rst),

.UART_TX    (ser_tx),
.UART_RX    (ser_rx)
);

endmodule
