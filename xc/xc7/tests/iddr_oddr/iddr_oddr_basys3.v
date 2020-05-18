module top (
    input  wire       clk,
    input  wire [7:0] sw,
    output wire [7:0] led,
    output wire [3:0] io_out,
    input  wire [3:0] io_inp
);

    // Clock
    wire CLK;
    BUFG bufg (.I(clk), .O(CLK));

    // Heartbeat
    reg [24:0] cnt;
    always @(posedge CLK)
        cnt <= cnt + 1;

    assign led[7] = cnt[24];

    // Clock divider
    reg [2:0] tcnt;
    always @(posedge CLK)
        tcnt <= tcnt + 1;

    wire tclk = tcnt[2];

    // Testers
    ioddr_tester #(.DDR_CLK_EDGE("SAME_EDGE"))
        tester0 (.CLK(tclk), .ERR(led[0]), .Q(io_out[0]), .D(io_inp[0]));

    ioddr_tester #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED"))
        tester1 (.CLK(tclk), .ERR(led[1]), .Q(io_out[1]), .D(io_inp[1]));

    ioddr_tester #(.DDR_CLK_EDGE("OPPOSITE_EDGE"))
        tester2 (.CLK(tclk), .ERR(led[2]), .Q(io_out[2]), .D(io_inp[2]));

    ioddr_tester #(.USE_PHY_ODDR(0))
        tester3 (.CLK(tclk), .ERR(led[3]), .Q(io_out[3]), .D(io_inp[3]));

    // Unused LEDs
    assign led[6:4] = |sw;

endmodule
