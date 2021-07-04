//////////////////////////////////////////////////////////////////////////////////
// Design Name: Multiply and Accumulate Block
// Module Name: mac_dsp
// Project Name: DSP48E1 use in Artix7 board
// Target Devices: ARTIX7 Board
// Description: 
//
// This is a Multipy and accumulate module with DSP48E1 initantiated and
// used in vivado.
// Here we have only used the function or instruction : INST=  A * B + C
// 
//////////////////////////////////////////////////////////////////////////////////

// This is a Multipy and accumulate module with DSP48E1 initantiated and
// used in vivado.
// Here we have only used the function or instruction : INST=  A * B + C
module mac_dsp(
    input [17:0] a,b,
    input [47:0] c,
    input clk,
    output [47:0] p
    );
    
    xbip_dsp48_macro_0 dsp (.A(a),.B(b),.C(c),.P(p),.CLK(clk));
endmodule
