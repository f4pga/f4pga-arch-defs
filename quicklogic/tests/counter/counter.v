module top(
    input  wire       clk,
    output wire [1:0] led
);

    reg [7:0] cnt;
    initial cnt <= 0;

    always @(posedge clk)
        cnt <= cnt + 1;

    assign led[1:0] = cnt[7:6];

endmodule
