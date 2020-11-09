module top( x0, y0, A0, valid );
    input [7:0] x0;
    input [7:0] y0;
    output [15:0] A0;
    input [1:0] valid;

    MULT mul0 (
        .Amult({24'b0,x0}),
        .Bmult({24'b0,y0}),
        .Valid_mult(valid),
        .sel_mul_32x32(1'b1),
	.Cmult(A0)
    );

endmodule
