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
endmodule
