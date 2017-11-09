module CARRY4(CO, O, CI, CYINIT, DI, S);
	output wire [3:0] CO;
	output wire [3:0] O;

	input wire CI;      // Carry in from adjacent slice
	input wire CYINIT;  // Carry in from logic fabric

	input wire [3:0] DI;
	input wire [3:0] S;
endmodule

// Flip-flop which can be configured only as a flip flop.
module W5FF(D, CE, CK, Q, SR);
	input  wire D;
	output wire Q;

	// When SR is high:
	//  * Force internal value to 1 -- SRHIGH
	//  * Force internal value to 0 -- SRLOW  (default)
	parameter SRVAL		= "SRLOW";

	// Value on Async Reset on power up
	parameter INIT 		= (SRVAL == "SRLOW") ? 1'b0 : 1'b1;

	// Shared between all flip-flops in a slice
	input wire CK; // Clock
	input wire CE; // Clock-enable - Active high
	input wire SR; // Set or Reset - Active high

	// Reset type, can be;
	// * None  -- Ignore SR
	// * Sync  -- Reset occurs on clock edge
	// * Async -- Reset occurs when ever
	parameter SRTYPE 	= "SYNC";
endmodule

// Flip-flop which can be configured as a flip flop or latch.
module WFF(D, CE, CK, Q, SR);
	input  wire D;
	output wire Q;

	// The mode this unit operates in, can be;
	// "FLIPFLOP" 	- Operate as a flip-flop (D->Q on clock low->high)
	// "LATCH" 	- Operate as a latch	 (D->Q while CLK low)
	parameter MODE		= "FLIPFLOP";

	// When SR is high:
	//  * Force internal value to 1 -- SRHIGH
	//  * Force internal value to 0 -- SRLOW  (default)
	parameter SRVAL		= "SRLOW";

	// Value on Async Reset on power up
	parameter INIT 		= (SRVAL == "SRLOW") ? 1'b0 : 1'b1;

	// Shared between all flip-flops in a slice
	input wire CK; // Clock
	input wire CE; // Clock-enable - Active high
	input wire SR; // Set or Reset - Active high

	// Reset type, can be;
	// * None  -- Ignore SR
	// * Sync  -- Reset occurs on clock edge
	// * Async -- Reset occurs when ever
	parameter SRTYPE 	= "SYNC";
endmodule

module A7_SLICEL(
	DX, D, DMUX, Dout, DQ,	// D port
	CX, C, CMUX, Cout, CQ,	// C port
	BX, B, BMUX, Bout, BQ,	// B port
	AX, A, AMUX, Aout, AQ,	// A port
	SR, CE, CLK, 		// Flip flop signals
	CARRY_IN, CARRY_OUT 	// Carry to/from adjacent slices
);
	// D port
	input wire DX;
	input wire D[6:0];
	output wire DMUX;
	output wire Dout;
	output wire DQ;

	// D port flip-flop config
	parameter D5FF_SRVAL		= "SRLOW";
	parameter D5FF_INIT		= D5FF_SRVAL;
	parameter DFF_SRVAL		= "SRLOW";
	parameter DFF_INIT		= D5FF_SRVAL;

	// C port
	input wire CX;
	input wire C[6:0];
	output wire CMUX;
	output wire Cout;
	output wire CQ;

	// B port
	input wire BX;
	input wire B[6:0];
	output wire BMUX;
	output wire Bout;
	output wire BQ;

	// A port
	input wire AX;
	input wire A[6:0];
	output wire AMUX;
	output wire Aout;
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
	input CARRY_IN;
	input CARRY_OUT;

endmodule
