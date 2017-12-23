`include "wlut/sim.ALUT.v"
`include "wlut/sim.BLUT.v"
`include "wlut/sim.CLUT.v"
`include "wlut/sim.DLUT.v"
`include "w5ff/sim.A5FF.v"
`include "w5ff/sim.B5FF.v"
`include "w5ff/sim.C5FF.v"
`include "w5ff/sim.D5FF.v"
`include "wff/sim.AFF.v"
`include "wff/sim.BFF.v"
`include "wff/sim.CFF.v"
`include "wff/sim.DFF.v"
`include "muxes/f7amux/sim.v"
`include "muxes/f7bmux/sim.v"
`include "muxes/f8mux/sim.v"

`include "routing/affmux/sim.v"
`include "routing/bffmux/sim.v"
`include "routing/cffmux/sim.v"
`include "routing/dffmux/sim.v"

`include "routing/aoutmux/sim.v"
`include "routing/boutmux/sim.v"
`include "routing/coutmux/sim.v"
`include "routing/doutmux/sim.v"

`include "routing/precyinit_rmux/sim.v"
`include "routing/coutused/sim.v"

`include "routing/srusedmux/sim.v"
`include "routing/ceusedmux/sim.v"

`include "routing/w5ffmux/sim.A5FFMUX.v"
`include "routing/w5ffmux/sim.B5FFMUX.v"
`include "routing/w5ffmux/sim.C5FFMUX.v"
`include "routing/w5ffmux/sim.D5FFMUX.v"

`include "routing/wcy0/sim.ACY0.v"
`include "routing/wcy0/sim.BCY0.v"
`include "routing/wcy0/sim.CCY0.v"
`include "routing/wcy0/sim.DCY0.v"

`include "routing/wused/sim.AUSED.v"
`include "routing/wused/sim.BUSED.v"
`include "routing/wused/sim.CUSED.v"
`include "routing/wused/sim.DUSED.v"

`include "carry4/carry4_split/sim.v"
`include "carry4/carry4_complete/sim.v"

`include "routing/clkinv/sim.v"

module SLICEL(
	DX, D, DMUX, DO, DQ,	// D port
	CX, C, CMUX, CO, CQ,	// C port
	BX, B, BMUX, BO, BQ,	// B port
	AX, A, AMUX, AO, AQ,	// A port
	SR, CE, CLK, 		// Flip flop signals
	CIN, CYINIT, COUT,	// Carry to/from adjacent slices
);
	// D port
	input wire DX;
	input wire [6:1] D;
	output wire DMUX;
	output wire DO;
	output wire DQ;

	// D port flip-flop config
	parameter D5FF_SRVAL		= "SRLOW";
	parameter D5FF_INIT		= D5FF_SRVAL;
	parameter DFF_SRVAL		= "SRLOW";
	parameter DFF_INIT		= D5FF_SRVAL;

	// C port
	input wire CX;
	input wire [6:1] C;
	output wire CMUX;
	output wire CO;
	output wire CQ;

	// B port
	input wire BX;
	input wire [6:1] B;
	output wire BMUX;
	output wire BO;
	output wire BQ;

	// A port
	input wire AX;
	input wire [6:1] A;
	output wire AMUX;
	output wire AO;
	output wire AQ;

	// Shared Flip flop signals
	input wire CLK; // Clock
	input wire SR;	// Set/Reset
	input wire CE;	// Clock enable

	// Reset type for all flip flops, can be;
	// * None  -- Ignore SR
	// * Sync  -- Reset occurs on clock edge
	// * Async -- Reset occurs when ever
	parameter SR_TYPE = "SYNC";

	// The mode this unit operates in, can be;
	// "FLIPFLOP" 	- Operate as a flip-flop (D->Q on clock low->high)
	// "LATCH" 	- Operate as a latch	 (D->Q while CLK low)
	parameter FF_MODE = "FLIPFLOP";

	// Carry to/from adjacent slices
	input wire CIN;
	input wire CYINIT;
	output wire COUT;

	// Internal routing configuration
	wire A5LUT_O5;
	wire B5LUT_O5;
	wire C5LUT_O5;
	wire D5LUT_O5;
	wire D6LUT_O6;
	wire C6LUT_O6;
	wire B6LUT_O6;
	wire A6LUT_O6;

	ALUT alut (.A(A), .O6(A6LUT_O6), .O5(A5LUT_O5));
	BLUT blut (.A(B), .O6(B6LUT_O6), .O5(B5LUT_O5));
	CLUT clut (.A(C), .O6(C6LUT_O6), .O5(C5LUT_O5));
	DLUT dlut (.A(D), .O6(D6LUT_O6), .O5(D5LUT_O5));

	wire F7AMUX_OUT;
	wire F8MUX_OUT;

	wire A5FFMUX_OUT;
	wire B5FFMUX_OUT;
	wire C5FFMUX_OUT;
	wire D5FFMUX_OUT;

	A5FFMUX a5ffmux (.IN_B(AX), .IN_A(A5LUT_O5), .O(A5FFMUX_OUT));
	B5FFMUX b5ffmux (.IN_B(BX), .IN_A(B5LUT_O5), .O(B5FFMUX_OUT));
	C5FFMUX c5ffmux (.IN_B(CX), .IN_A(C5LUT_O5), .O(C5FFMUX_OUT));
	D5FFMUX d5ffmux (.IN_B(DX), .IN_A(D5LUT_O5), .O(D5FFMUX_OUT));

	wire ACY0_OUT;
	wire BCY0_OUT;
	wire CCY0_OUT;
	wire DCY0_OUT;

	ACY0 acy0 (.O5(A5LUT_O5), .AX(AX), .O(ACY0_OUT));
	BCY0 bcy0 (.O5(B5LUT_O5), .BX(BX), .O(BCY0_OUT));
	CCY0 ccy0 (.O5(C5LUT_O5), .CX(CX), .O(CCY0_OUT));
	DCY0 dcy0 (.O5(D5LUT_O5), .DX(DX), .O(DCY0_OUT));

	wire F7BMUX_OUT;
	F7BMUX f7bmux (.I0(D6LUT_O6), .I1(C6LUT_O6), .OUT(F7BMUX_OUT), .S0(CX));
	wire F7AMUX_OUT;
	F7BMUX f7amux (.I0(B6LUT_O6), .I1(A6LUT_O6), .OUT(F7AMUX_OUT), .S0(AX));
	wire F8MUX_OUT;
	F8MUX f8mux (.I0(F7BMUX_OUT), .I1(F7AMUX_OUT), .OUT(F8MUX_OUT), .S0(BX));

	wire PRECYINIT_OUT;
	PRECYINIT_RMUX precyinit_mux (/*.I0(0), .I1(1),*/ .CI(CIN), .CYINIT(CYINIT), .OUT(PRECYINIT_OUT));

	wire [3:0] CARRY4_CO;
	wire [3:0] CARRY4_O;

	CARRY4_SPLIT carry4 (
		.CO(CARRY4_CO),
		.O(CARRY4_O),
		.DI({ACY0_OUT, BCY0_OUT, CCY0_OUT, DCY0_OUT}),
		.S({A6LUT_O6, B6LUT_O6, C6LUT_O6, D6LUT_O6}),
		.CIN(PRECYINIT_OUT));

	COUTUSED coutused (.IN(CARRY4_O[3]), .OUT(COUT));

	wire A5FF_Q;
	wire B5FF_Q;
	wire C5FF_Q;
	wire D5FF_Q;

	AOUTMUX aoutmux (
		.A5Q(A5FF_Q), .XOR(CARRY4_O[0]), .O6(A6LUT_O6), .O5(A5LUT_O5), .CY(CARRY4_CO[0]), .F7(F7AMUX_OUT),
		.OUT(AMUX));
	BOUTMUX boutmux (
		.B5Q(B5FF_Q), .XOR(CARRY4_O[1]), .O6(B6LUT_O6), .O5(B5LUT_O5), .CY(CARRY4_CO[1]), .F8(F8MUX_OUT),
		.OUT(BMUX));
	COUTMUX coutmux (
		.C5Q(C5FF_Q), .XOR(CARRY4_O[2]), .O6(C6LUT_O6), .O5(C5LUT_O5), .CY(CARRY4_CO[2]), .F7(F7BMUX_OUT),
		.OUT(CMUX));
	DOUTMUX doutmux (
		.D5Q(D5FF_Q), .XOR(CARRY4_O[3]), .O6(D6LUT_O6), .O5(D5LUT_O5), .CY(CARRY4_CO[3]),
		.OUT(DMUX));

	wire AFFMUX_OUT;
	wire BFFMUX_OUT;
	wire CFFMUX_OUT;
	wire DFFMUX_OUT;

	AFFMUX affmux (
		.AX(AX), .XOR(CARRY4_O[0]), .O6(A6LUT_O6), .O5(A5LUT_O5), .CY(CARRY4_CO[0]), .F7(F7AMUX_OUT),
		.OUT(AFFMUX_OUT));
	BFFMUX bffmux (
		.BX(BX), .XOR(CARRY4_O[1]), .O6(B6LUT_O6), .O5(B5LUT_O5), .CY(CARRY4_CO[1]), .F8(F8MUX_OUT),
		.OUT(BFFMUX_OUT));
	CFFMUX cffmux (
		.CX(CX), .XOR(CARRY4_O[2]), .O6(C6LUT_O6), .O5(C5LUT_O5), .CY(CARRY4_CO[2]), .F7(F7BMUX_OUT),
		.OUT(CFFMUX_OUT));
	DFFMUX dffmux (
		.DX(DX), .XOR(CARRY4_O[3]), .O6(D6LUT_O6), .O5(D5LUT_O5), .CY(CARRY4_CO[3]),
		.OUT(DFFMUX_OUT));

	wire CEUSEDMUX_OUT;
	wire SRUSEDMUX_OUT;
	wire CLKINV_OUT;

	CLKINV clkinv (.CLK(CLK), .OUT(CLKINV_OUT));

	A5FF a5ff (.CE(CEUSEDMUX_OUT), .CK(CLKINV_OUT), .SR(SRUSEDMUX_OUT), .D(A5FFMUX_OUT), .Q(A5FF_Q));
	B5FF b5ff (.CE(CEUSEDMUX_OUT), .CK(CLKINV_OUT), .SR(SRUSEDMUX_OUT), .D(B5FFMUX_OUT), .Q(B5FF_Q));
	C5FF c5ff (.CE(CEUSEDMUX_OUT), .CK(CLKINV_OUT), .SR(SRUSEDMUX_OUT), .D(C5FFMUX_OUT), .Q(C5FF_Q));
	D5FF d5ff (.CE(CEUSEDMUX_OUT), .CK(CLKINV_OUT), .SR(SRUSEDMUX_OUT), .D(D5FFMUX_OUT), .Q(D5FF_Q));

	A5FF aff  (.CE(CEUSEDMUX_OUT), .CK(CLKINV_OUT), .SR(SRUSEDMUX_OUT), .D(AFFMUX_OUT),  .Q(AQ));
	B5FF bff  (.CE(CEUSEDMUX_OUT), .CK(CLKINV_OUT), .SR(SRUSEDMUX_OUT), .D(BFFMUX_OUT),  .Q(BQ));
	C5FF cff  (.CE(CEUSEDMUX_OUT), .CK(CLKINV_OUT), .SR(SRUSEDMUX_OUT), .D(CFFMUX_OUT),  .Q(CQ));
	D5FF dff  (.CE(CEUSEDMUX_OUT), .CK(CLKINV_OUT), .SR(SRUSEDMUX_OUT), .D(DFFMUX_OUT),  .Q(DQ));

	AUSED aused (.I0(A6LUT_O6), .O(AO));
	BUSED bused (.I0(B6LUT_O6), .O(BO));
	CUSED cused (.I0(C6LUT_O6), .O(CO));
	DUSED dused (.I0(D6LUT_O6), .O(DO));

	CEUSEDMUX ceusedmux (.IN(CE), .OUT(CEUSEDMUX_OUT));
	SRUSEDMUX srusedmux (.IN(SR), .OUT(SRUSEDMUX_OUT));

endmodule
