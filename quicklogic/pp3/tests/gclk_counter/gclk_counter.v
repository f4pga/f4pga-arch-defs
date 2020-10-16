module top(
    input  wire [1:0] clk,
    output wire [3:0] led
);

    // Counters
    reg [23:0] cnt0;
    initial cnt0 <= 0;
    always @(posedge clk[0])
        cnt0 <= cnt0 + 1;

    reg [23:0] cnt1;
    initial cnt1 <= 0;
    always @(posedge clk[1])
        cnt1 <= cnt1 + 1;

    // Outputs
    assign led[0] = cnt0[22];
    assign led[1] = cnt0[23];

    assign led[2] = cnt1[22];
    assign led[3] = cnt1[23];

endmodule
