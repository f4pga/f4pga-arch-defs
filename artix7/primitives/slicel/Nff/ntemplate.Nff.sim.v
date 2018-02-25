// DFF, CFF, BFF, AFF == WFF
// Flip-flop which can be configured as a flip flop or latch.
module {N}FF(D, CE, CK, Q, SR);
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

	// Reset type, can be;
	// * None  -- Ignore SR
	// * Sync  -- Reset occurs on clock edge
	// * Async -- Reset occurs when ever
	parameter SRTYPE 	= "SYNC";

	input  wire D;
	//output wire Q;
	output reg Q;

	// Shared between all flip-flops in a slice
	input wire CK; // Clock
	input wire CE; // Clock-enable - Active high
	input wire SR; // Set or Reset - Active high

	//parameter [0:0] INIT = 1'b0;
	//parameter [0:0] IS_C_INVERTED = 1'b0;
	//parameter [0:0] IS_D_INVERTED = 1'b0;
	//parameter [0:0] IS_S_INVERTED = 1'b0;
	initial Q <= INIT;

	//always @(posedge CK) if (SR == !IS_S_INVERTED) Q <= 1'b1; else if (CE) Q <= D ^ 1;
	always @(posedge CK) if (SR == 1'b1) Q <= 1'b1; else if (CE) Q <= D;

endmodule
