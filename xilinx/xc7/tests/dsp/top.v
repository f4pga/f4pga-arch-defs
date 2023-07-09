`timescale 1ns / 1ps
// Structural instantiation of dsp48e1 block in 25x18 multiplier mode using pipelining registers(A1,A2,B1,B2). 
module top
  (
   A, 
   B,
   OUT
  );
   
   
   (* IOSTANDARD = "LVCMOS33" *) input wire [24:0] A;
   (* IOSTANDARD = "LVCMOS33" *) input wire [17:0] B;
   (* IOSTANDARD = "LVCMOS33" *) output wire [16:0] OUT;

   
   DSP48E1 #(
   	.AREG(2'b10),
   	.BREG(2'b10),
   	.MASK(48'b111110111111101111111111100001111011110111111101),
   	.ADREG(1'b0),
   	.ALUMODEREG(1'b0),
   	.ACASCREG(1'b1),
   	.BCASCREG(1'b1),
   	.CARRYINREG(1'b0),
   	.CARRYINSELREG(1'b0),
   	.DREG(1'b0),
   	.INMODEREG(1'b0),  
   	.IS_ALUMODE_INVERTED(4'b1101),
   	.IS_INMODE_INVERTED(5'b11111),
   	.IS_OPMODE_INVERTED(7'b1000101),
   	.MREG(1'b0),
   	.OPMODEREG(1'b0),
   	.PREG(1'b0),
   	.CREG(1'b0),
   	.A_INPUT("CASCADE"),
   	.B_INPUT("CASCADE"),
   	.USE_DPORT("TRUE"),
   	.USE_SIMD("FOUR12"),
   	.AUTORESET_PATDET("RESET_MATCH"),
   	.PATTERN(48'b111110111111101111111111100001111011110111111101),
   	.SEL_MASK("ROUNDING_MODE1"),
   	.IS_CARRYIN_INVERTED(1'b1),
   	.IS_CLK_INVERTED(1'b1)   
   )
   dsp25x18(
   	.A(A),   	
   	.ALUMODE(4'b0011),
   	.B(B),   	
   	.C(48'b111111111111111111111111111111111111111111111111),   
        .CARRYIN(1'b0),
        .CARRYINSEL(3'b000),
     .CEA1(1'b1),
     .CEA2(1'b1),
     .CEAD(1'b1),
     .CEALUMODE(1'b1),
     .CEB1(1'b1),
     .CEB2(1'b1),
     .CEC(1'b1),
     .CECARRYIN(1'b1),
     .CECTRL(1'b1),
     .CED(1'b1),
     .CEINMODE(1'b1),
     .CEM(1'b1),
     .CEP(1'b1),
     .CLK(1'b1),
        .D(25'b0000000000000000000000000),
        .INMODE(5'b00000),        
        .OPMODE(7'b0111111),        
        .RSTA(1'b0),
        .RSTALLCARRYIN(1'b0),
        .RSTALUMODE(1'b0),
        .RSTB(1'b0),
        .RSTC(1'b0),
        .RSTCTRL(1'b0),
        .RSTD(1'b0),
        .RSTINMODE(1'b0),
        .RSTM(1'b0),
        .RSTP(1'b0),
        .P(OUT)
   );   
endmodule
