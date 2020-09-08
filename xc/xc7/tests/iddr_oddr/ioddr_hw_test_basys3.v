module top (
    input  wire       clk,
    input  wire [7:0] sw,
    output wire [7:0] led,
    output wire [3:0] io_out,
    input  wire [3:0] io_inp
);

    // PLL (to get clock division and still keep 50% duty cycle)
    wire fb;
    wire clk_ddr;
    wire clk_ddr_nobuf;

    PLLE2_ADV # (
        .CLKFBOUT_MULT  (16),
        .CLKOUT0_DIVIDE (64)    // 25MHz

    ) pll (
        .CLKIN1         (clk),

        .CLKFBIN        (fb),
        .CLKFBOUT       (fb),

        .CLKOUT0        (clk_ddr_nobuf)
    );

    BUFG bufg (.I(clk_ddr_nobuf), .O(clk_ddr));

    // Heartbeat
    reg [23:0] cnt;
    always @(posedge clk_ddr)
        cnt <= cnt + 1;

    assign led[7] = cnt[23];

    // IDELAYCTRL
    IDELAYCTRL idelayctrl (
        .REFCLK (clk_ddr),
        .RDY    (led[6])
    );

    // Testers
    ioddr_tester #(.DDR_CLK_EDGE("SAME_EDGE"))
        tester0 (.CLK(clk_ddr), .CLKB(clk_ddr), .ERR(led[0]), .Q(io_out[0]), .D(io_inp[0]));

    ioddr_tester #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), .USE_IDELAY(1))
        tester1 (.CLK(clk_ddr), .CLKB(clk_ddr), .ERR(led[1]), .Q(io_out[1]), .D(io_inp[1]));

    ioddr_tester #(.DDR_CLK_EDGE("OPPOSITE_EDGE"))
        tester2 (.CLK(clk_ddr), .CLKB(clk_ddr), .ERR(led[2]), .Q(io_out[2]), .D(io_inp[2]));

    ioddr_tester #(.USE_PHY_ODDR(0))
        tester3 (.CLK(clk_ddr), .CLKB(clk_ddr), .ERR(led[3]), .Q(io_out[3]), .D(io_inp[3]));

    // Unused LEDs
    assign led[5:4] = |sw;

endmodule
