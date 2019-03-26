module top
(
input  wire         clk,
input  wire         rst,

output wire         ser_tx,
input  wire         ser_rx,

output wire [3:0]   leds
);

// ============================================================================

// Clock divider k = 1/(1<<N_CLK_DIV)
localparam integer N_CLK_DIV = 7;

reg [N_CLK_DIV-1:0] clk_out;
wire clk_div = clk_out[N_CLK_DIV-1];

clk_div clk_div_0 (.clk_in(clk), .clk_out(clk_out[0]));
genvar i;
generate for(i=0; i<(N_CLK_DIV-1); i=i+1) begin
    clk_div clk_div_n (.clk_in(clk_out[i]), .clk_out(clk_out[i+1]));
end endgenerate

// ============================================================================
//
scalable_proc #
(
.NUM_PROCESSING_UNITS   (2),
.UART_PRESCALER         ((100000000 >> N_CLK_DIV) / 9600),
)
scalable_proc
(
.CLK        (clk_div),
.RST        (rst),

.UART_TX    (ser_tx),
.UART_RX    (ser_rx)
);

assign leds = {1'b0, 1'b0, !ser_tx, !rst};

endmodule

// ============================================================================

module clk_div (
    input  clk_in,
    output clk_out
);

initial begin
    clk_out <= 0;
end

always @(posedge clk_in)
    clk_out <= ~clk_out;

endmodule
