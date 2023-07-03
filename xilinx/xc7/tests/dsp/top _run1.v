`timescale 1ns / 1ps

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
   	.AREG(1'b0),
   	.BREG(1'b0),
   	.MASK(48'b111111111111111111111111111111111111111111111111),
   /*	.ADREG(),
   	.ALUMODEREG(),
   	.ACASCREG(),
   	.BCASCREG(),
   	.CARRYINREG(),
   	.CARRYINSELREG(),
   	.DREG(),
   	.INMODEREG(),  */
   	.IS_ALUMODE_INVERTED(4'b1100),
   	.IS_INMODE_INVERTED(5'b11111),
   	.IS_OPMODE_INVERTED(7'b1000101),
  /* 	.MREG(),
   	.OPMODEREG(),
   	.PREG()   */
   )
   dsp25x18(
   	.A(A),
   	.ACIN(30'b000000000000000000000000000000),
   	.ALUMODE(4'b0011),
   	.B(B),
   	.BCIN(18'b000000000000000000),
   	.C(48'b111111111111111111111111111111111111111111111111),
   	.CARRYCASCIN(1'b0),
        .CARRYIN(1'b0),
        .CARRYINSEL(3'b000),
        .CEA1(1'b0),
        .CEA2(1'b0),
        .CEAD(1'b0),
        .CEALUMODE(1'b0),
        .CEB1(1'b0),
        .CEB2(1'b0),
        .CEC(1'b0),
        .CECARRYIN(1'b0),
        .CECTRL(1'b0),
        .CED(1'b0),
        .CEINMODE(1'b0),
        .CEM(1'b0),
        .CEP(1'b0),
        .CLK(1'b0),
        .D(25'b0000000000000000000000000),
        .INMODE(5'b00000),
        .MULTSIGNIN(1'b0),
        .OPMODE(7'b0111111),
        .PCIN(48'b000000000000000000000000000000000000000000000000),
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
    
   
   
endmodule // MULT25X18
