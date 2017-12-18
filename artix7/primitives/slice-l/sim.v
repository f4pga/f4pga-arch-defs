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

// BEL
module MUX(O, I, S);
	parameter INPUTS = 2;

	output wire O;
	input wire [INPUTS:0] I;
	input wire [$clog2(INPUTS):0] S;

	always_comb begin
		O = 'z;
		for(int i = 0; i < INPUTS; i++) begin
			if(onehot == (1 << i))
				O = I[i];
		end
endmodule

// FIXME: Rewrite these MUXes in terms of the MUX above
// F7BMUX
module F7BMUX(I0, I1, S0, OUT);
	input wire I0;
	input wire I1;
	input wire I0;
	output wire OUT;

	assign OUT = S0 ? I1 : I0;
endmodule

// F7AMUX
module F7AMUX(I0, I1, S0, OUT);
	input wire I0;
	input wire I1;
	input wire I0;
	output wire OUT;

	assign OUT = S0 ? I1 : I0;
endmodule

// F8MUX
module F8MUX(I0, I1, S0, OUT);
	input wire I0;
	input wire I1;
	input wire I0;
	output wire OUT;

	assign OUT = S0 ? I1 : I0;
endmodule

// Carry logic
module CARRY4(CO, O, CI, CYINIT, DI, S);
	output wire [3:0] CO;
	output wire [3:0] O;

	input wire CI;      // Carry in from adjacent slice
	input wire CYINIT;  // Carry in from logic fabric

	input wire [3:0] DI;
	input wire [3:0] S;

	assign O = S ^ {CO[2:0], CI | CYINIT};
	assign CO[0] = S[0] ? CI | CYINIT : DI[0];
	assign CO[1] = S[1] ? CO[0] : DI[1];
	assign CO[2] = S[2] ? CO[1] : DI[2];
	assign CO[3] = S[3] ? CO[2] : DI[3];

endmodule

module CARRY4_WMUX(I0, I1, S0, OUT);
	input wire I0;
	input wire I1;
	input wire S0;
	output wire OUT;

  	assign OUT = S0 ? I1 : I1;
endmodule

module CARRY4_WXOR(I0, I1, S0, OUT);
	input wire I0;
	input wire I1;
	input wire S0;
	output wire OUT;

	// FIXME: What is S0 used for?
  	assign OUT = I0 ^ I1;
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
	input wire [6:0] D;
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
	input wire [6:0] C;
	output wire CMUX;
	output wire Cout;
	output wire CQ;

	// B port
	input wire BX;
	input wire [6:0] B;
	output wire BMUX;
	output wire Bout;
	output wire BQ;

	// A port
	input wire AX;
	input wire [6:0] A;
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

	// Internal routing configuration

endmodule
