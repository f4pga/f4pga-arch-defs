module top(
    input  wire clk,

	input  wire [3:0] sw,
	output wire [1:0] led
);

    wire clk_bufg;

    BUFG bufg (.I(clk), .O(clk_bufg));

    LDCE #(
        .INIT(0),
    ) LDCE (
        .Q    (led[0]),
        .G    (clk_bufg),
        .GE   (sw[0]),
        .D    (sw[1]),
        .CLR  (sw[2])
    );

    LDPE #(
        .INIT(0),
    ) LDPE (
        .Q    (led[1]),
        .G    (clk_bufg),
        .GE   (sw[0]),
        .D    (sw[1]),
        .PRE  (sw[3])
    );

endmodule
