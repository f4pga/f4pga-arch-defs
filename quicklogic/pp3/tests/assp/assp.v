module top(
    output wire [3:0] led,
    output wire [7:0] num
);
    wire SYSCLK;
    wire clk;

    // Use the internal oscillator accessible in the left ASSP to generate
    // clock.
    // TODO: Verify that the internal oscillator works in hardware
    qlal3_left_assp_macro left_assp (
        .SYSCLK (SYSCLK),
        .osc_en (1'b1)
    );

    gclkbuff u_gclkbuff_clock (
        .A(SYSCLK),
        .Z(clk)
    );

    // Counter with LED output
    reg [23:0] cnt;
    initial cnt <= 0;

    always @(posedge clk)
        cnt <= cnt + 1;

    assign led[3:0] = cnt[23:20];

    // Use the multiplier in the right ASSP to compute squares of some numbers
    reg [3:0] dat;
    always @(posedge clk)
        dat <= dat + 1;

    wire [63:0] squared;
    qlal3_right_assp_macro right_assp (
        .Amult1({27'd0, dat}),
        .Bmult1({27'd0, dat}),
        .Cmult1(squared),
    );

    assign num = squared[7:0];

endmodule
