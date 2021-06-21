// Assume that you have two 8-bit 2's complement numbers, a[7:0] and b[7:0].
// These numbers are added to produce s[7:0] and we also compute whether a (signed) overflow has occurred.

module top_module (
    input wire [15:0] sw;
    output [8:0] led;
); //
    wire [7:0] a, b, s;
    wire overflow;
    assign a = sw[7:0];
    assign b = sw[15:8];
    assign led = {overflow,s};
    assign s = {a+b};
    assign overflow = ((a[7] == b[7]) & (a[7] != s[7]));

endmodule