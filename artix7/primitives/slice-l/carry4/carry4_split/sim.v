
`include "carry4_wmux/sim.CARRY4_AMUX.v"
`include "carry4_wmux/sim.CARRY4_BMUX.v"
`include "carry4_wmux/sim.CARRY4_CMUX.v"
`include "carry4_wmux/sim.CARRY4_DMUX.v"

`include "carry4_wxor/sim.CARRY4_AXOR.v"
`include "carry4_wxor/sim.CARRY4_BXOR.v"
`include "carry4_wxor/sim.CARRY4_CXOR.v"
`include "carry4_wxor/sim.CARRY4_DXOR.v"

module CARRY4_SPLIT(CO, O, CIN, DI, S);

	output wire [3:0] CO;
	output wire [3:0] O;
	input CIN;
	input [3:0] DI;
	input [3:0] S;

	CARRY4_AMUX muxcy0 (.O(CO[0]), .CI(CIN),   .DI(DI[0]), .S(S[0]));
	CARRY4_BMUX muxcy1 (.O(CO[1]), .CI(CO[0]), .DI(DI[1]), .S(S[1]));
	CARRY4_CMUX muxcy2 (.O(CO[2]), .CI(CO[1]), .DI(DI[2]), .S(S[2]));
	CARRY4_DMUX muxcy3 (.O(CO[3]), .CI(CO[2]), .DI(DI[3]), .S(S[3]));

	CARRY4_AXOR xorcy0 (.O(O[0]), .CI(CIN),   .LI(S[0]));
	CARRY4_BXOR xorcy1 (.O(O[1]), .CI(CO[0]), .LI(S[1]));
	CARRY4_CXOR xorcy2 (.O(O[2]), .CI(CO[1]), .LI(S[2]));
	CARRY4_DXOR xorcy3 (.O(O[3]), .CI(CO[2]), .LI(S[3]));
endmodule
