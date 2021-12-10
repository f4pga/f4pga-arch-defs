module top (
    (* clkbuf_inhibit *)
    input  wire        CLK,
    input  wire [ 7:0] A,
    input  wire [ 7:0] B,
    input  wire [ 7:0] C,
    output reg  [15:0] D,
);

    wire [63:0] AxB;
    wire [63:0] AxBxC;

    qlal3_mult_32x32_cell mult_AB (
        .Amult      ({23'd0, A}),
        .Bmult      ({23'd0, B}),
        .Valid_mult (1'b1),
        .Cmult      (AxB)
    );

    qlal3_mult_32x32_cell mult_ABC (
        .Amult      (AxB[31:0]),
        .Bmult      ({23'd0, C}),
        .Valid_mult (1'b1),
        .Cmult      (AxBxC)
    );

    always @(posedge CLK)
        D <= AxBxC[15:0];

endmodule
