`include "routing/rmux.sim.v"
`include "../logicbox/logicbox.sim.v"
module USE_MUX (a, b, c, o1, o2);
	input wire a;
	input wire b;
	input wire c;
	output wire o1;
	output wire o2;

	wire logic_a;
	wire logic_b;
	wire logic_c;
	LOGICBOX lboxa (.I(a), .O(logic_a));
	LOGICBOX lboxb (.I(b), .O(logic_b));
	LOGICBOX lboxc (.I(c), .O(logic_c));

	parameter FASM_MUX1 = "I0";
	RMUX #(.MODE(FASM_MUX1)) mux1 (.I0(logic_a), .I1(logic_b), .O(o1));

	parameter FASM_MUX2 = "I0";
	RMUX #(.MODE(FASM_MUX2)) mux2 (.I0(logic_a), .I1(logic_c), .O(o2));
endmodule
