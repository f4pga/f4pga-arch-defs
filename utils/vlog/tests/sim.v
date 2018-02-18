`include "adder/sim.v"
`include "dff/sim.v"
`include "lut2/sim.v"


(* blackbox *)
module test_pb(input clk, rst, a, b, ci, output q, co);
endmodule

(* ALTERNATIVE_TO="test_pb" *)
module test_add(input clk, rst, a, b, ci, output q, co);

wire d;
adder adder_i(.a(a), .b(b), .ci(ci), .y(d), .co(co));
dff dff_i(.clk(clk), .rst(rst), .d(d), .q(q));

endmodule

(* ALTERNATIVE_TO="test_pb" *)
module test_lut(input clk, rst, a, b, ci, output q, co);

wire d;
lut2 lut2_i(.in({b, a}), .y(d), .co(co));
dff dff_i(.clk(clk), .rst(rst), .d(d), .q(q));

endmodule
