`include "adder/sim.v"
`include "dff/sim.v"
`include "lut2/sim.v"

module test_pb(input clk, rst, a, b, ci, output q, co);

wire d;

(* MODE="ADD" *) adder adder_i(.a(a), .b(b), .ci(ci), .y(d), .co(co));
(* MODE="LUT" *) lut2 lut2_i(.a(a), .b(b), .y(d), .co(co));

dff dff_i(.clk(clk), .rst(rst), .d(d), .q(q));

endmodule
