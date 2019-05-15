`include "../common_slice/Nlut/alut.sim.v"
`include "../common_slice/Nlut/blut.sim.v"
`include "../common_slice/Nlut/clut.sim.v"
`include "../common_slice/Nlut/dlut.sim.v"
`include "../common_slice/muxes/f7amux/f7amux.sim.v"
`include "../common_slice/muxes/f7bmux/f7bmux.sim.v"
`include "../common_slice/muxes/f8mux/f8mux.sim.v"

`include "../common_slice/routing/affmux/affmux.sim.v"
`include "../common_slice/routing/bffmux/bffmux.sim.v"
`include "../common_slice/routing/cffmux/cffmux.sim.v"
`include "../common_slice/routing/dffmux/dffmux.sim.v"

`include "../common_slice/routing/aoutmux/aoutmux.sim.v"
`include "../common_slice/routing/boutmux/boutmux.sim.v"
`include "../common_slice/routing/coutmux/coutmux.sim.v"
`include "../common_slice/routing/doutmux/doutmux.sim.v"

`include "../common_slice/routing/precyinit_mux/precyinit_mux.sim.v"
`include "../common_slice/routing/coutused/coutused.sim.v"

`include "../common_slice/routing/srusedmux/srusedmux.sim.v"
`include "../common_slice/routing/ceusedmux/ceusedmux.sim.v"

`include "../common_slice/routing/N5ffmux/a5ffmux.sim.v"
`include "../common_slice/routing/N5ffmux/b5ffmux.sim.v"
`include "../common_slice/routing/N5ffmux/c5ffmux.sim.v"
`include "../common_slice/routing/N5ffmux/d5ffmux.sim.v"

`include "../common_slice/routing/Ncy0/acy0.sim.v"
`include "../common_slice/routing/Ncy0/bcy0.sim.v"
`include "../common_slice/routing/Ncy0/ccy0.sim.v"
`include "../common_slice/routing/Ncy0/dcy0.sim.v"

`include "../common_slice/routing/Nused/aused.sim.v"
`include "../common_slice/routing/Nused/bused.sim.v"
`include "../common_slice/routing/Nused/cused.sim.v"
`include "../common_slice/routing/Nused/dused.sim.v"

`include "../common_slice/carry/carry4_vpr.sim.v"

`include "../common_slice/routing/clkinv/clkinv.sim.v"

module SLICEL(
	DX, D1, D2, D3, D4, D5, D6, DMUX, D, DQ,	// D port
	CX, C1, C2, C3, C4, C5, C6, CMUX, C, CQ,	// C port
	BX, B1, B2, B3, B4, B5, B6, BMUX, B, BQ,	// B port
	AX, A1, A2, A3, A4, A5, A6, AMUX, A, AQ,	// A port
	SR, CE, CLK, 		// Flip flop signals
	CIN, CYINIT, COUT,	// Carry to/from adjacent slices
);
	// D port
	input wire DX;
	input wire D1;
	input wire D2;
	input wire D3;
	input wire D4;
	input wire D5;
	input wire D6;
	output wire DMUX;
	output wire D;
	output wire DQ;

	// D port flip-flop config
	parameter D5FF_SRVAL		= "SRLOW";
	parameter D5FF_INIT		= D5FF_SRVAL;
	parameter DFF_SRVAL		= "SRLOW";
	parameter DFF_INIT		= D5FF_SRVAL;

	// C port
	input wire CX;
	input wire C1;
	input wire C2;
	input wire C3;
	input wire C4;
	input wire C5;
	input wire C6;
	output wire CMUX;
	output wire C;
	output wire CQ;

	// B port
	input wire BX;
	input wire B1;
	input wire B2;
	input wire B3;
	input wire B4;
	input wire B5;
	input wire B6;
	output wire BMUX;
	output wire B;
	output wire BQ;

	// A port
	input wire AX;
	input wire A1;
	input wire A2;
	input wire A3;
	input wire A4;
	input wire A5;
	input wire A6;
	output wire AMUX;
	output wire A;
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

	ALUT alut (.A1(A1), .A2(A2), .A3(A3), .A4(A4), .A5(A5), .A6(A6), .O6(A6LUT_O6), .O5(A5LUT_O5));
	BLUT blut (.A1(B1), .A2(B2), .A3(B3), .A4(B4), .A5(B5), .A6(B6), .O6(B6LUT_O6), .O5(B5LUT_O5));
	CLUT clut (.A1(C1), .A2(C2), .A3(C3), .A4(C4), .A5(C5), .A6(C6), .O6(C6LUT_O6), .O5(C5LUT_O5));
	DLUT dlut (.A1(D1), .A2(D2), .A3(D3), .A4(D4), .A5(D5), .A6(D6), .O6(D6LUT_O6), .O5(D5LUT_O5));

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
	PRECYINIT_MUX precyinit_mux (.C0(0), .C1(1), .CI(CIN), .CYINIT(CYINIT), .OUT(PRECYINIT_OUT));

	wire [3:0] CARRY4_CO;
	wire [3:0] CARRY4_O;

	CARRY4_MODES carry4 (
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

	AUSED aused (.I0(A6LUT_O6), .O(A));
	BUSED bused (.I0(B6LUT_O6), .O(B));
	CUSED cused (.I0(C6LUT_O6), .O(C));
	DUSED dused (.I0(D6LUT_O6), .O(D));

	CEUSEDMUX ceusedmux (.IN(CE), .OUT(CEUSEDMUX_OUT));
	SRUSEDMUX srusedmux (.IN(SR), .OUT(SRUSEDMUX_OUT));

endmodule
