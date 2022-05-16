`include "add_2.v"

module top (in, out);

    input  wire [7:0] in;
    output wire [7:0] out;

    wire [7:0] x;
    add_2 add_2_inst (
        .in  (in),
        .out (x)
    );

    wire [7:0] y;
    add_3 add_3_inst (
        .in  (x),
        .out (y)
    );

    assign out = y;

endmodule

