//////////////////////////////////////////////////////////////////////////////////
// Design Name: Multiply  Block
// Module Name: multi_dsp
// Project Name: DSP48E1 use in Artix7 board
// Target Devices: ARTIX7 Board
// Description: 
//
// This is a Multipy module with DSP48E1 initantiated and
// used in vivado.
// Here we have only used the function or instruction : INST =  A * B 
// 
//////////////////////////////////////////////////////////////////////////////////

// This is a Multipy module with DSP48E1 initantiated and
// used in vivado.
// Here we have only used the function or instruction : INST=  A * B
module multi_dsp(
    input [17:0] a,b,
    input clk,
    output [35:0] p
    );
    
    xbip_dsp48_macro_0 dsp (.A(a),.B(b),.P(p),.CLK(clk));
endmodule
