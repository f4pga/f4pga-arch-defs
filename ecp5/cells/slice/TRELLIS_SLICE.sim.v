`include "../../primitives/slice/CCU2C/CCU2C.sim.v"
`include "../../primitives/slice/L6MUX21/L6MUX21.sim.v"
`include "../../primitives/slice/LUT4/LUT4.sim.v"
`include "../../primitives/slice/PFUMX/PFUMX.sim.v"
`include "../../primitives/slice/TRELLIS_FF/TRELLIS_FF.sim.v"
`include "../../primitives/slice/TRELLIS_RAM16X2/TRELLIS_RAM16X2.sim.v"

`default_nettype none
module TRELLIS_SLICE(
	input A0, B0, C0, D0,
	input A1, B1, C1, D1,
	input M0, M1,
	input FCI, FXA, FXB,

	input CLK, LSR, CE,
	input DI0, DI1,

	input WD0, WD1,
	input WAD0, WAD1, WAD2, WAD3,
	input WRE, WCK,

	output F0, Q0,
	output F1, Q1,
	output FCO, OFX0, OFX1,

	output WDO0, WDO1, WDO2, WDO3,
	output WADO0, WADO1, WADO2, WADO3
);

	parameter MODE = "LOGIC";
	parameter GSR = "ENABLED";
	parameter SRMODE = "LSR_OVER_CE";
	parameter [127:0] CEMUX = "1";
	parameter CLKMUX = "CLK";
	parameter LSRMUX = "LSR";
	parameter LUT0_INITVAL = 16'h0000;
	parameter LUT1_INITVAL = 16'h0000;
	parameter REG0_SD = "0";
	parameter REG1_SD = "0";
	parameter REG0_REGSET = "RESET";
	parameter REG1_REGSET = "RESET";
	parameter [127:0] CCU2_INJECT1_0 = "NO";
	parameter [127:0] CCU2_INJECT1_1 = "NO";
	parameter WREMUX = "WRE";

	generate
		if (MODE == "LOGIC") begin
			// LUTs
			LUT4 #(
				.INIT(LUT0_INITVAL)
			) lut4_0 (
				.A(A0), .B(B0), .C(C0), .D(D0),
				.Z(F0)
			);
			LUT4 #(
				.INIT(LUT1_INITVAL)
			) lut4_1 (
				.A(A1), .B(B1), .C(C1), .D(D1),
				.Z(F1)
			);
			// LUT expansion muxes
			PFUMX lut5_mux (.ALUT(F1), .BLUT(F0), .C0(M0), .Z(OFX0));
			L6MUX21 lutx_mux (.D0(FXA), .D1(FXB), .SD(M1), .Z(OFX1));
		end else if (MODE == "CCU2") begin
			CCU2C #(
				.INIT0(LUT0_INITVAL),
				.INIT1(LUT1_INITVAL),
				.INJECT1_0(CCU2_INJECT1_0),
				.INJECT1_1(CCU2_INJECT1_1)
		  ) ccu2c_i (
				.CIN(FCI),
				.A0(A0), .B0(B0), .C0(C0), .D0(D0),
				.A1(A1), .B1(B1), .C1(C1), .D1(D1),
				.S0(F0), .S1(F1),
				.COUT(FCO)
			);
		end else if (MODE == "RAMW") begin
			assign WDO0 = C1;
			assign WDO1 = A1;
			assign WDO2 = D1;
			assign WDO3 = B1;
			assign WADO0 = D0;
			assign WADO1 = B0;
			assign WADO2 = C0;
			assign WADO3 = A0;
		end else if (MODE == "DPRAM") begin
			TRELLIS_RAM16X2 #(
				.INITVAL_0(LUT0_INITVAL),
				.INITVAL_1(LUT1_INITVAL),
				.WREMUX(WREMUX)
			) ram_i (
				.DI0(WD0), .DI1(WD1),
				.WAD0(WAD0), .WAD1(WAD1), .WAD2(WAD2), .WAD3(WAD3),
				.WRE(WRE), .WCK(WCK),
				.RAD0(D0), .RAD1(C0), .RAD2(B0), .RAD3(A0),
				.DO0(F0), .DO1(F1)
			);
			// TODO: confirm RAD and INITVAL ordering
			// DPRAM mode contract?
			always @(*) begin
				assert(A0==A1);
				assert(B0==B1);
				assert(C0==C1);
				assert(D0==D1);
			end
		end else begin
			ERROR_UNKNOWN_SLICE_MODE error();
		end
	endgenerate

	// FF input selection muxes
	wire muxdi0 = (REG0_SD == "1") ? DI0 : M0;
	wire muxdi1 = (REG1_SD == "1") ? DI1 : M1;
	// Flipflops
	TRELLIS_FF #(
		.GSR(GSR),
		.CEMUX(CEMUX),
		.CLKMUX(CLKMUX),
		.LSRMUX(LSRMUX),
		.SRMODE(SRMODE),
		.REGSET(REG0_REGSET)
	) ff_0 (
		.CLK(CLK), .LSR(LSR), .CE(CE),
		.DI(muxdi0),
		.Q(Q0)
	);
	TRELLIS_FF #(
		.GSR(GSR),
		.CEMUX(CEMUX),
		.CLKMUX(CLKMUX),
		.LSRMUX(LSRMUX),
		.SRMODE(SRMODE),
		.REGSET(REG1_REGSET)
	) ff_1 (
		.CLK(CLK), .LSR(LSR), .CE(CE),
		.DI(muxdi1),
		.Q(Q1)
	);
endmodule
