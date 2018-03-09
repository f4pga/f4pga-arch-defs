`include "adder/adder.sim.v"
`include "dff/dff.sim.v"
`include "lut2/lut2.sim.v"


(* MODES="ADD, LUT" *)
module tests(input clk, a, b, ci, output q, co);
  parameter MODE = "ADD";
  wire d;
  generate
    if(MODE == "ADD") begin
    adder adder_i(.a(a), .b(b), .ci(ci), .y(d), .co(co));
    end else if(MODE == "LUT") begin
    assign co = 0;
    lut2 lut2_i(.in({b, a}), .y(d));
    end
  endgenerate
  dff dff_i(.clk(clk), .d(d), .q(q));

endmodule
