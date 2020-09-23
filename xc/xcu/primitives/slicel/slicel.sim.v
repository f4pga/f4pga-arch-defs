// LUTs
`include "../common_slice/Nlut/alut.sim.v"
`include "../common_slice/Nlut/blut.sim.v"
`include "../common_slice/Nlut/clut.sim.v"
`include "../common_slice/Nlut/dlut.sim.v"
`include "../common_slice/Nlut/elut.sim.v"
`include "../common_slice/Nlut/flut.sim.v"
`include "../common_slice/Nlut/glut.sim.v"
`include "../common_slice/Nlut/hlut.sim.v"

// Muxes
`include "../common_slice/muxes/f7mux_ab/f7mux_ab.sim.v"
`include "../common_slice/muxes/f7mux_cd/f7mux_cd.sim.v"
`include "../common_slice/muxes/f7mux_ef/f7mux_ef.sim.v"
`include "../common_slice/muxes/f7mux_gh/f7mux_gh.sim.v"
`include "../common_slice/muxes/f8mux_top/f8mux_top.sim.v"
`include "../common_slice/muxes/f8mux_bot/f8mux_bot.sim.v"
`include "../common_slice/muxes/f9mux/f9mux.sim.v"

// OUTMUX
`include "../common_slice/routing/outmux/outmux.sim.v"

// FFMUX
`include "../common_slice/routing/ffmux/ffmuxa1.sim.v"
`include "../common_slice/routing/ffmux/ffmuxa2.sim.v"
`include "../common_slice/routing/ffmux/ffmuxb1.sim.v"
`include "../common_slice/routing/ffmux/ffmuxb2.sim.v"
`include "../common_slice/routing/ffmux/ffmuxc1.sim.v"
`include "../common_slice/routing/ffmux/ffmuxc2.sim.v"
`include "../common_slice/routing/ffmux/ffmuxd1.sim.v"
`include "../common_slice/routing/ffmux/ffmuxd2.sim.v"
`include "../common_slice/routing/ffmux/ffmuxe1.sim.v"
`include "../common_slice/routing/ffmux/ffmuxe2.sim.v"
`include "../common_slice/routing/ffmux/ffmuxf1.sim.v"
`include "../common_slice/routing/ffmux/ffmuxf2.sim.v"
`include "../common_slice/routing/ffmux/ffmuxg1.sim.v"
`include "../common_slice/routing/ffmux/ffmuxg2.sim.v"
`include "../common_slice/routing/ffmux/ffmuxh1.sim.v"
`include "../common_slice/routing/ffmux/ffmuxh2.sim.v"

// Flip-Flop
`include "../ff/ff.sim.v"

(* whitebox *)
module SLICEL(
	A1, A2, A3, A4, A5, A6, AMUX, AQ, AQ2, AX, A_I, A_O, // A port
	B1, B2,	B3, B4,	B5, B6,	BMUX, BQ, BQ2, BX, B_I, B_O, // B port
	C1, C2,	C3, C4,	C5, C6, CMUX, CQ, CQ2, CX, C_I, C_O, // C port
	D1, D2,	D3, D4,	D5, D6, DMUX, DQ, DQ2, DX, D_I, D_O, // D port
	E1, E2,	E3, E4,	E5, E6, EMUX, EQ, EQ2, EX, E_I, E_O, // E port
	F1, F2,	F3, F4, F5, F6, FMUX, FQ, FQ2, FX, F_I, F_O, // F port
	G1, G2,	G3, G4,	G5, G6, GMUX, GQ, GQ2, GX, G_I, G_O, // G port
	H1, H2,	H3, H4,	H5, H6, HMUX, HQ, HQ2, HX, H_I, H_O, // H port
	SRST1, SRST2, CKEN1, CKEN2, CKEN3, CKEN4, CLK1,	CLK2, // Flip-Flop signals
	CIN, COUT // Carry to/from signals
);

	// A port
	input wire A1;
	input wire A2;
	input wire A3;
	input wire A4;
	input wire A5;
	input wire A6;
	input wire AX;
	input wire A_I;
	output wire AMUX;
	output wire AQ;
	output wire AQ2;
	output wire A_O;

	// B port
	input wire B1;
	input wire B2;
	input wire B3;
	input wire B4;
	input wire B5;
	input wire B6;
	input wire BX;
	input wire B_I;
	output wire BMUX;
	output wire BQ;
	output wire BQ2;
	output wire B_O;

	// C port
	input wire C1;
	input wire C2;
	input wire C3;
	input wire C4;
	input wire C5;
	input wire C6;
	input wire CX;
	input wire C_I;
	output wire CMUX;
	output wire CQ;
	output wire CQ2;
	output wire C_O;

	// D port
	input wire D1;
	input wire D2;
	input wire D3;
	input wire D4;
	input wire D5;
	input wire D6;
	input wire DX;
	input wire D_I;
	output wire DMUX;
	output wire DQ;
	output wire DQ2;
	output wire D_O;

	// E port
	input wire E1;
	input wire E2;
	input wire E3;
	input wire E4;
	input wire E5;
	input wire E6;
	input wire EX;
	input wire E_I;
	output wire EMUX;
	output wire EQ;
	output wire EQ2;
	output wire E_O;

	// F port
	input wire F1;
	input wire F2;
	input wire F3;
	input wire F4;
	input wire F5;
	input wire F6;
	input wire FX;
	input wire F_I;
	output wire FMUX;
	output wire FQ;
	output wire FQ2;
	output wire F_O;

	// G port
	input wire G1;
	input wire G2;
	input wire G3;
	input wire G4;
	input wire G5;
	input wire G6;
	input wire GX;
	input wire G_I;
	output wire GMUX;
	output wire GQ;
	output wire GQ2;
	output wire G_O;

	// H port
	input wire H1;
	input wire H2;
	input wire H3;
	input wire H4;
	input wire H5;
	input wire H6;
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
	wire A5LUT_O5;
	wire B5LUT_O5;
	wire C5LUT_O5;
	wire D5LUT_O5;
	wire E5LUT_O5;
	wire F5LUT_O5;
	wire G5LUT_O5;
	wire H5LUT_O5;

	// O6
	wire A6LUT_O6;
	wire B6LUT_O6;
	wire C6LUT_O6;
	wire D6LUT_O6;
	wire E6LUT_O6;
	wire F6LUT_O6;
	wire G6LUT_O6;
	wire H6LUT_O6;

	ALUT ALUT (.A1(A1), .A2(A2), .A3(A3), .A4(A4), .A5(A5), .A6(A6), .O6(A6LUT_O6), .O5(A5LUT_O5));
	BLUT BLUT (.A1(B1), .A2(B2), .A3(B3), .A4(B4), .A5(B5), .A6(B6), .O6(B6LUT_O6), .O5(B5LUT_O5));
	CLUT CLUT (.A1(C1), .A2(C2), .A3(C3), .A4(C4), .A5(C5), .A6(C6), .O6(C6LUT_O6), .O5(C5LUT_O5));
	DLUT DLUT (.A1(D1), .A2(D2), .A3(D3), .A4(D4), .A5(D5), .A6(D6), .O6(D6LUT_O6), .O5(D5LUT_O5));
	ELUT ELUT (.A1(E1), .A2(E2), .A3(E3), .A4(E4), .A5(E5), .A6(E6), .O6(E6LUT_O6), .O5(E5LUT_O5));
	FLUT FLUT (.A1(F1), .A2(F2), .A3(F3), .A4(F4), .A5(F5), .A6(F6), .O6(F6LUT_O6), .O5(F5LUT_O5));
	GLUT GLUT (.A1(G1), .A2(G2), .A3(G3), .A4(G4), .A5(G5), .A6(G6), .O6(G6LUT_O6), .O5(G5LUT_O5));
	HLUT HLUT (.A1(H1), .A2(H2), .A3(H3), .A4(H4), .A5(H5), .A6(H6), .O6(H6LUT_O6), .O5(H5LUT_O5));

	wire F7MUX_AB_OUT;
	wire F7MUX_CD_OUT;
	wire F7MUX_EF_OUT;
	wire F7MUX_GH_OUT;
	F7MUX_AB F7MUX_AB (.I0(B6LUT_O6), .I1(A6LUT_O6), .O(F7MUX_AB_OUT), .S(AX));
	F7MUX_CD F7MUX_CD (.I0(D6LUT_O6), .I1(C6LUT_O6), .O(F7MUX_CD_OUT), .S(CX));
	F7MUX_EF F7MUX_EF (.I0(F6LUT_O6), .I1(E6LUT_O6), .O(F7MUX_EF_OUT), .S(EX));
	F7MUX_GH F7MUX_GH (.I0(H6LUT_O6), .I1(G6LUT_O6), .O(F7MUX_GH_OUT), .S(GX));

	wire F8MUX_TOP_OUT;
	wire F8MUX_BOT_OUT;
	F8MUX_TOP F8MUX_TOP (.I0(F7MUX_GH_OUT), .I1(F7MUX_EF_OUT), .O(F8MUX_TOP_OUT), .S(FX));
	F8MUX_BOT F8MUX_BOT (.I0(F7MUX_CD_OUT), .I1(F7MUX_AB_OUT), .O(F8MUX_BOT_OUT), .S(BX));

	wire F9MUX_OUT;
	F9MUX f9mux (.I0(F8MUX_TOP_OUT), .I1(F8MUX_BOT_OUT), .O(F9MUX_OUT), .S(DX));

	OUTMUX AOUTMUX (/*.F78(1'b0),*/         .D6(A6LUT_O6), .D5(A5LUT_O5), .OUT(AMUX));
	OUTMUX BOUTMUX (.F78(F7MUX_AB_OUT),     .D6(B6LUT_O6), .D5(B5LUT_O5), .OUT(BMUX));
	OUTMUX COUTMUX (.F78(F8MUX_BOT_OUT),    .D6(C6LUT_O6), .D5(C5LUT_O5), .OUT(CMUX));
	OUTMUX DOUTMUX (.F78(F7MUX_CD_OUT),     .D6(D6LUT_O6), .D5(D5LUT_O5), .OUT(DMUX));
	OUTMUX EOUTMUX (.F78(F9MUX_OUT),        .D6(E6LUT_O6), .D5(E5LUT_O5), .OUT(EMUX));
	OUTMUX FOUTMUX (.F78(F7MUX_EF_OUT),     .D6(F6LUT_O6), .D5(F5LUT_O5), .OUT(FMUX));
	OUTMUX GOUTMUX (.F78(F8MUX_TOP_OUT),    .D6(G6LUT_O6), .D5(G5LUT_O5), .OUT(GMUX));
	OUTMUX HOUTMUX (.F78(F7MUX_GH_OUT),     .D6(H6LUT_O6), .D5(H5LUT_O5), .OUT(HMUX));

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

	FF AFF1 (.D(FFMUXA1_OUT1), .SR(SRST1), .CE(CKEN1), .CLK(CLK1), .Q(AQ));
	FF AFF2 (.D(FFMUXA2_OUT2), .SR(SRST1), .CE(CKEN2), .CLK(CLK1), .Q(AQ2));

	FF BFF1 (.D(FFMUXB1_OUT1), .SR(SRST1), .CE(CKEN1), .CLK(CLK1), .Q(BQ));
	FF BFF2 (.D(FFMUXB2_OUT2), .SR(SRST1), .CE(CKEN2), .CLK(CLK1), .Q(BQ2));

	FF CFF1 (.D(FFMUXC1_OUT1), .SR(SRST1), .CE(CKEN1), .CLK(CLK1), .Q(CQ));
	FF CFF2 (.D(FFMUXC2_OUT2), .SR(SRST1), .CE(CKEN2), .CLK(CLK1), .Q(CQ2));

	FF DFF1 (.D(FFMUXD1_OUT1), .SR(SRST1), .CE(CKEN1), .CLK(CLK1), .Q(DQ));
	FF DFF2 (.D(FFMUXD2_OUT2), .SR(SRST1), .CE(CKEN2), .CLK(CLK1), .Q(DQ2));

	FF EFF1 (.D(FFMUXE1_OUT1), .SR(SRST2), .CE(CKEN3), .CLK(CLK2), .Q(EQ));
	FF EFF2 (.D(FFMUXE2_OUT2), .SR(SRST2), .CE(CKEN4), .CLK(CLK2), .Q(EQ2));

	FF FFF1 (.D(FFMUXF1_OUT1), .SR(SRST2), .CE(CKEN3), .CLK(CLK2), .Q(FQ));
	FF FFF2 (.D(FFMUXF2_OUT2), .SR(SRST2), .CE(CKEN4), .CLK(CLK2), .Q(FQ2));

	FF GFF1 (.D(FFMUXG1_OUT1), .SR(SRST2), .CE(CKEN3), .CLK(CLK2), .Q(GQ));
	FF GFF2 (.D(FFMUXG2_OUT2), .SR(SRST2), .CE(CKEN4), .CLK(CLK2), .Q(GQ2));

	FF HFF1 (.D(FFMUXH1_OUT1), .SR(SRST2), .CE(CKEN3), .CLK(CLK2), .Q(HQ));
	FF HFF2 (.D(FFMUXH2_OUT2), .SR(SRST2), .CE(CKEN4), .CLK(CLK2), .Q(HQ2));

endmodule
