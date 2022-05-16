module top(
    output wire [3:0] led
);
    wire Clk_C16;
    wire clk;

    qlal4s3b_cell_macro u_qlal4s3b_cell_macro (
        .Clk_C16 (Clk_C16),
    );

    gclkbuff u_gclkbuff_clock (
        .A(Clk_C16),
        .Z(clk)
    );

    reg [23:0] cnt;
    initial cnt <= 0;

    always @(posedge clk)
        cnt <= cnt + 1;

    assign led[3:0] = cnt[23:20];

endmodule
