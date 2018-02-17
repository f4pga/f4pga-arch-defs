`include "adder/sim.v"
`include "dff/sim.v"

module test_pb(input clk, rst, a, b, ci, output q, co);

wire d;

adder adder_i(.a(a), .b(b), .ci(ci), .y(d), .co(co));

dff dff_i(.clk(clk), .rst(rst), .d(d), .q(q));

endmodule
