module top (
    input  wire clk,
    input  wire sw,
    output wire led
);
    wire O_LOCKED;
    wire RST;

    wire clk0;
    wire clk1;
    wire clk_out;
    wire clk_fb_i;
    wire clk_fb_o;
    reg [25:0] cnt;

    assign RST = 1'b0;

    BUFG bufg0 (
        .I(clk_fb_i),
        .O(clk_fb_o)
    );

    wire clk_ibuf;
    IBUF ibuf0 (
        .I(clk),
        .O(clk_ibuf)
    );

    wire clk_bufg;
    BUFG bufg1 (
        .I(clk_ibuf),
        .O(clk_bufg)
    );

    PLLE2_ADV #(
        .BANDWIDTH          ("HIGH"),
        .COMPENSATION       ("ZHOLD"),

        .CLKIN1_PERIOD      (10.0),  // 100MHz

        .CLKFBOUT_MULT      (16),
        .CLKOUT0_DIVIDE     (8),
        .CLKOUT1_DIVIDE     (32),

        .STARTUP_WAIT       ("FALSE"),

        .DIVCLK_DIVIDE      (1)
    )
    pll (
        .CLKIN1     (clk_bufg),
        .CLKINSEL   (1),

        .RST        (RST),
        .PWRDWN     (0),
        .LOCKED     (O_LOCKED),

        .CLKFBIN    (clk_fb_i),
        .CLKFBOUT   (clk_fb_o),

        .CLKOUT0    (clk0),
        .CLKOUT1    (clk1)
    );

    BUFGMUX bufgmux (
      .I0(clk0),
      .I1(clk1),
      .S(sw[0]),
      .O(clk_out)
    );

    always @(posedge clk_out) begin
        cnt <= cnt + 1'b1;
    end
    assign led[0] = cnt[25];
endmodule
