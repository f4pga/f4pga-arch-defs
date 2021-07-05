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
    
    wire [47:0] outp;
    assign p = outp[35:0];
    xbip_dsp48_macro_0  sum1 (
  .CLK(clk),          // input wire CLK
  .CARRYIN(1'b0),  
  .A({{12{1'b0}},a}),              // input wire [17 : 0] A
  .C({{48{1'b0}}),              
  .P(outp),             // output wire [35 : 0] P
  .B(b),                // input wire [17:0] B
  .D({25{1'b1}}),
  .OPMODE(7'b0000101),
  .ALUMODE(4'b0000),
  .CARRYINSEL(3'b000),
  .INMODE(4'b0000),
  .CEA1(1'b1),
  .CEA2(1'b1),
  .CEB1(1'b1),
  .CEB2(1'b1),
  .CEC(1'b1),
  .CED(1'b1),
  .CEM(1'b1),
  .CEP(1'b1),
  .CEAD(1'b1),
  .CEALUMODE(1'b1),
  .CECTRL(1'b1),
  .CECARRYIN(1'b1),
  .CEINMODE(1'b1),
  .RSTA(1'b0),
  .RSTB(1'b0),
  .RSTC(1'b0),
  .RSTD(1'b0),
  .RSTM(1'b0),
  .RSTP(1'b0),
  .RSTCTRL(1'b0),
  .RSTALLCARRYIN(1'b0),
  .RSTALUMODE(1'b0),
  .RSTINMODE(1'b0),
  .ACIN({30{1'b0}}),
  .BCIN({18{1'b0}}),
  .PCIN({48{1'b0}}),
  .CARRYCASCIN(1'b0),
  .MULTISIGNIN(1'b0),
  .ACOUT(),
  .BCOUT(),
  .PCOUT(),
  .CARRYOUT(),
  .CARRYCASCOUT(),
  .MULTISIGNOUT(),
  .PATTERNDETECT(),
  .PATTERNBDETECT(),
  .OVERFLOW(),
  .UNDERFLOW()
);
endmodule
