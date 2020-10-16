module top( x0, y0, A0, x1, y1, A1, valid );
    input [1:0] x0;
    input [1:0] y0;
    output [3:0] A0;

    input [1:0] x1;
    input [1:0] y1;
    output [3:0] A1;

    input [1:0] valid;

    qlal4s3_mult_32x32_cell mul0 (
        .Amult(x0),
        .Bmult(y0),
        .Valid_mult(valid),
        .Cmult(A0)
    );

    qlal4s3_mult_16x16_cell mul1 (
        .Amult(x1),
        .Bmult(y1),
        .Valid_mult(valid),
        .Cmult(A1)
    );
endmodule
