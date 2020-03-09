`include "../../../../../vpr/muxes/logic/mux8/mux8.sim.v"
`include "../nreg/reg.sim.v"
`include "carryin_mux/carryin_mux.sim.v"

module CARRYINSEL_LOGIC (CARRYIN, CARRYCASCIN, CARRYCASCOUT, A, B, P, PCIN, CARRYINSEL, CIN,
			 RSTALLCARRYIN, CECARRYIN, CEM, CLK);

   parameter MREG = 1;
   parameter CARRYINREG = 1;

   input wire 	     CARRYIN;
   input wire 	     CARRYCASCIN;
   input wire 	     CARRYCASCOUT;
   input wire [24:0] A;
   input wire [17:0] B;
   input wire [47:0] P;
   input wire [47:0] PCIN;
   input wire [2:0]  CARRYINSEL;

   output wire 	     CIN;

   input wire 	     RSTALLCARRYIN;
   input wire 	     CECARRYIN;
   input wire 	     CEM;
   input wire 	     CLK;

`ifndef PB_TYPE
   wire 	     ROUND;
   wire 	     ROUND_REG;
   wire 	     ROUND_MUX_OUT;
   assign ROUND = A[24] ~^ B[17];
   REG 		     round_reg (.D(ROUND), .Q(ROUND_REG), .CE(CEM), .CLK(CLK), .RESET(RSTALLCARRYIN));
   // TODO(elms): not sure if the select is correct: "signal can be optionally registered to match the MREG pipeline delay"
   CARRYIN_MUX #(.S(MREG)) round_mux (.BYPASS(ROUND), .REG(ROUND_REG), .O(ROUND_MUX_OUT));

   wire 	     CARRYIN_REG;
   wire 	     CARRYIN_MUX_OUT;

   REG 		     carryin_reg (.D(CARRYIN), .Q(CARRYIN_REG), .CE(CECARRYIN), .CLK(CLK), .RESET(RSTALLCARRYIN));
   CARRYIN_MUX #(.S(CARRYINREG)) carryin_mux (.BYPASS(CARRYIN), .REG(CARRYIN_REG), .O(CARRYIN_MUX_OUT));

   MUX8 carryinsel_mux (.I0(CARRYIN_MUX_OUT), .I1(~PCIN[47]), .I2(CARRYCASCIN), .I3(PCIN[47]), .I4(CARRYCASCOUT), .I5(~P[47]), .I6(ROUND_MUX_OUT), .I7(P[47]),
			.S0(CARRYINSEL[0]), .S1(CARRYINSEL[1]), .S2(CARRYINSEL[2]), .O(CIN));
`endif //  `ifndef PB_TYPE

endmodule // CARRYINSEL_LOGIC
