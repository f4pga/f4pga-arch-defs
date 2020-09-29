// OUTMUX
`include "routing/outmux/outmuxa.sim.v"
`include "routing/outmux/outmuxb.sim.v"
`include "routing/outmux/outmuxc.sim.v"
`include "routing/outmux/outmuxd.sim.v"
`include "routing/outmux/outmuxe.sim.v"
`include "routing/outmux/outmuxf.sim.v"
`include "routing/outmux/outmuxg.sim.v"
`include "routing/outmux/outmuxh.sim.v"

// FFMUX
`include "routing/ffmux/ffmuxa1.sim.v"
`include "routing/ffmux/ffmuxa2.sim.v"
`include "routing/ffmux/ffmuxb1.sim.v"
`include "routing/ffmux/ffmuxb2.sim.v"
`include "routing/ffmux/ffmuxc1.sim.v"
`include "routing/ffmux/ffmuxc2.sim.v"
`include "routing/ffmux/ffmuxd1.sim.v"
`include "routing/ffmux/ffmuxd2.sim.v"
`include "routing/ffmux/ffmuxe1.sim.v"
`include "routing/ffmux/ffmuxe2.sim.v"
`include "routing/ffmux/ffmuxf1.sim.v"
`include "routing/ffmux/ffmuxf2.sim.v"
`include "routing/ffmux/ffmuxg1.sim.v"
`include "routing/ffmux/ffmuxg2.sim.v"
`include "routing/ffmux/ffmuxh1.sim.v"
`include "routing/ffmux/ffmuxh2.sim.v"

// Flip-Flop
`include "../ff/slice_ff.sim.v"

(* whitebox *)
module COMMON_SLICE(
	A5LUT_O5, A6LUT_O6, AMUX, AQ, AQ2, AX, A_I, A_O, // A port
	B5LUT_O5, B6LUT_O6, BMUX, BQ, BQ2, BX, B_I, B_O, // B port
	C5LUT_O5, C6LUT_O6, CMUX, CQ, CQ2, CX, C_I, C_O, // C port
	D5LUT_O5, D6LUT_O6, DMUX, DQ, DQ2, DX, D_I, D_O, // D port
	E5LUT_O5, E6LUT_O6, EMUX, EQ, EQ2, EX, E_I, E_O, // E port
	F5LUT_O5, F6LUT_O6, FMUX, FQ, FQ2, FX, F_I, F_O, // F port
	G5LUT_O5, G6LUT_O6, GMUX, GQ, GQ2, GX, G_I, G_O, // G port
	H5LUT_O5, H6LUT_O6, HMUX, HQ, HQ2, HX, H_I, H_O, // H port
	F7MUX_AB_OUT, F7MUX_CD_OUT, F7MUX_EF_OUT, F7MUX_GH_OUT,	// F7 Muxes
	F8MUX_TOP_OUT, F8MUX_BOT_OUT, // F8 Muxes
	F9MUX_OUT, // F9 Mux
	SRST1, SRST2, CKEN1, CKEN2, CKEN3, CKEN4, CLK1,	CLK2, // Flip-Flop signals
	CIN, COUT // Carry to/from signals
);

	// A port
	input wire AX;
	input wire A_I;
	output wire AMUX;
	output wire AQ;
	output wire AQ2;
	output wire A_O;

	// B port
	input wire BX;
	input wire B_I;
	output wire BMUX;
	output wire BQ;
	output wire BQ2;
	output wire B_O;

	// C port
	input wire CX;
	input wire C_I;
	output wire CMUX;
	output wire CQ;
	output wire CQ2;
	output wire C_O;

	// D port
	input wire DX;
	input wire D_I;
	output wire DMUX;
	output wire DQ;
	output wire DQ2;
	output wire D_O;

	// E port
	input wire EX;
	input wire E_I;
	output wire EMUX;
	output wire EQ;
	output wire EQ2;
	output wire E_O;

	// F port
	input wire FX;
	input wire F_I;
	output wire FMUX;
	output wire FQ;
	output wire FQ2;
	output wire F_O;

	// G port
	input wire GX;
	input wire G_I;
	output wire GMUX;
	output wire GQ;
	output wire GQ2;
	output wire G_O;

	// H port
	input wire HX;
	input wire H_I;
	output wire HMUX;
	output wire HQ;
	output wire HQ2;
	output wire H_O;

	// Flip-flop ports
	input wire SRST1;
	input wire SRST2;
	input wire CKEN1;
	input wire CKEN2;
	input wire CKEN3;
	input wire CKEN4;
	input wire CLK1;
	input wire CLK2;

	// Carry-chain ports
	input wire CIN;
	output wire COUT;

	// Internal routing configuration

	// O5
	input wire A5LUT_O5;
	input wire B5LUT_O5;
	input wire C5LUT_O5;
	input wire D5LUT_O5;
	input wire E5LUT_O5;
	input wire F5LUT_O5;
	input wire G5LUT_O5;
	input wire H5LUT_O5;

	// O6
	input wire A6LUT_O6;
	input wire B6LUT_O6;
	input wire C6LUT_O6;
	input wire D6LUT_O6;
	input wire E6LUT_O6;
	input wire F6LUT_O6;
	input wire G6LUT_O6;
	input wire H6LUT_O6;

	// F7 Muxes
	input wire F7MUX_AB_OUT;
	input wire F7MUX_CD_OUT;
	input wire F7MUX_EF_OUT;
	input wire F7MUX_GH_OUT;

	// F8 Muxes
	input wire F8MUX_TOP_OUT;
	input wire F8MUX_BOT_OUT;

	// F9 Mux
	input wire F9MUX_OUT;

	OUTMUXA OUTMUXA (/*.F78(1'b0),*/         .D6(A6LUT_O6), .D5(A5LUT_O5), .OUT(AMUX));
	OUTMUXB OUTMUXB (.F78(F7MUX_AB_OUT),     .D6(B6LUT_O6), .D5(B5LUT_O5), .OUT(BMUX));
	OUTMUXC OUTMUXC (.F78(F8MUX_BOT_OUT),    .D6(C6LUT_O6), .D5(C5LUT_O5), .OUT(CMUX));
	OUTMUXD OUTMUXD (.F78(F7MUX_CD_OUT),     .D6(D6LUT_O6), .D5(D5LUT_O5), .OUT(DMUX));
	OUTMUXE OUTMUXE (.F78(F9MUX_OUT),        .D6(E6LUT_O6), .D5(E5LUT_O5), .OUT(EMUX));
	OUTMUXF OUTMUXF (.F78(F7MUX_EF_OUT),     .D6(F6LUT_O6), .D5(F5LUT_O5), .OUT(FMUX));
	OUTMUXG OUTMUXG (.F78(F8MUX_TOP_OUT),    .D6(G6LUT_O6), .D5(G5LUT_O5), .OUT(GMUX));
	OUTMUXH OUTMUXH (.F78(F7MUX_GH_OUT),     .D6(H6LUT_O6), .D5(H5LUT_O5), .OUT(HMUX));

	wire FFMUXA1_OUT1;
	wire FFMUXA2_OUT2;
	FFMUXA1 AFFMUX1 (/*.F78(),*/ .D6(A6LUT_O6), .D5(A5LUT_O5), .BYP(AX), .OUT(FFMUXA1_OUT1));
	FFMUXA2 AFFMUX2 (/*.F78(),*/ .D6(A6LUT_O6), .D5(A5LUT_O5), .BYP(A_I), .OUT(FFMUXA2_OUT2));

	wire FFMUXB1_OUT1;
	wire FFMUXB2_OUT2;
	FFMUXB1 BFFMUX1 (.F78(F7MUX_AB_OUT), .D6(B6LUT_O6), .D5(B5LUT_O5), .BYP(BX), .OUT(FFMUXB1_OUT1));
	FFMUXB2 BFFMUX2 (.F78(F7MUX_AB_OUT), .D6(B6LUT_O6), .D5(B5LUT_O5), .BYP(B_I), .OUT(FFMUXB2_OUT2));

	wire FFMUXC1_OUT1;
	wire FFMUXC2_OUT2;
	FFMUXC1 CFFMUX1 (.F78(F8MUX_BOT_OUT), .D6(C6LUT_O6), .D5(C5LUT_O5), .BYP(CX), .OUT(FFMUXC1_OUT1));
	FFMUXC2 CFFMUX2 (.F78(F8MUX_BOT_OUT), .D6(C6LUT_O6), .D5(C5LUT_O5), .BYP(C_I), .OUT(FFMUXC2_OUT2));

	wire FFMUXD1_OUT1;
	wire FFMUXD2_OUT2;
	FFMUXD1 DFFMUX1 (.F78(F7MUX_CD_OUT), .D6(D6LUT_O6), .D5(D5LUT_O5), .BYP(DX), .OUT(FFMUXD1_OUT1));
	FFMUXD2 DFFMUX2 (.F78(F7MUX_CD_OUT), .D6(D6LUT_O6), .D5(D5LUT_O5), .BYP(D_I), .OUT(FFMUXD2_OUT2));

	wire FFMUXE1_OUT1;
	wire FFMUXE2_OUT2;
	FFMUXE1 EFFMUX1 (.F78(F9MUX_OUT), .D6(E6LUT_O6), .D5(E5LUT_O5), .BYP(EX), .OUT(FFMUXE1_OUT1));
	FFMUXE2 EFFMUX2 (.F78(F9MUX_OUT), .D6(E6LUT_O6), .D5(E5LUT_O5), .BYP(E_I), .OUT(FFMUXE2_OUT2));

	wire FFMUXF1_OUT1;
	wire FFMUXF2_OUT2;
	FFMUXF1 FFFMUX1 (.F78(F7MUX_EF_OUT), .D6(F6LUT_O6), .D5(F5LUT_O5), .BYP(FX), .OUT(FFMUXF1_OUT1));
	FFMUXF2 FFFMUX2 (.F78(F7MUX_EF_OUT), .D6(F6LUT_O6), .D5(F5LUT_O5), .BYP(F_I), .OUT(FFMUXF2_OUT2));

	wire FFMUXG1_OUT1;
	wire FFMUXG2_OUT2;
	FFMUXG1 GFFMUX1 (.F78(F8MUX_TOP_OUT), .D6(G6LUT_O6), .D5(G5LUT_O5), .BYP(GX), .OUT(FFMUXG1_OUT1));
	FFMUXG2 GFFMUX2 (.F78(F8MUX_TOP_OUT), .D6(G6LUT_O6), .D5(G5LUT_O5), .BYP(G_I), .OUT(FFMUXG2_OUT2));

	wire FFMUXH1_OUT1;
	wire FFMUXH2_OUT2;
	FFMUXH1 HFFMUX1 (.F78(F7MUX_GH_OUT), .D6(H6LUT_O6), .D5(H5LUT_O5), .BYP(HX),  .OUT(FFMUXH1_OUT1));
	FFMUXH2 HFFMUX2 (.F78(F7MUX_GH_OUT), .D6(H6LUT_O6), .D5(H5LUT_O5), .BYP(H_I), .OUT(FFMUXH2_OUT2));

	SLICE_FF SLICE_FF(
		.D({FFMUXA1_OUT1, FFMUXA2_OUT2,
			FFMUXB1_OUT1, FFMUXB2_OUT2,
			FFMUXC1_OUT1, FFMUXC2_OUT2,
			FFMUXD1_OUT1, FFMUXD2_OUT2,
			FFMUXE1_OUT1, FFMUXE2_OUT2,
			FFMUXF1_OUT1, FFMUXF2_OUT2,
			FFMUXG1_OUT1, FFMUXG2_OUT2,
			FFMUXH1_OUT1, FFMUXH2_OUT2}),
		.SR({SRST1, SRST2}),
		.CE({CKEN1, CKEN2, CKEN3, CKEN4}),
		.CLK({CLK1, CLK2}),
		.Q({AQ, AQ2,
			BQ, BQ2,
			CQ, CQ2,
			DQ, DQ2,
			EQ, EQ2,
			FQ, FQ2,
			GQ, GQ2,
			HQ, HQ2}),
	);

endmodule
