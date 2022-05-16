module top(
    input  wire clk,

    input  wire rx,
    output wire tx,

	  input  wire [15:0] sw,
	  output wire [15:0] led
);
    assign led[15:1] = sw[15:1];

    FDCE #(
        .INIT(0),
    ) fdse (
        .Q    (led[0]),
        .C    (clk),
        .CE   (sw[0]),
        .D    (sw[1]),
        .CLR  (sw[2])
    );

    // uart loopback
    assign tx = rx;

endmodule
