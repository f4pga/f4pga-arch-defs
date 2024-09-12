// Copyright (C) 2021 The SymbiFlow Authors.
//
// Use of this source code is governed by a ISC-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/ISC
//
// SPDX-License-Identifier: ISC



// This is a Multipy and accumulate module with DSP48E1 initantiated and
// used in vivado.
// Here we have only used the function or instruction : INST=  A * B + C
module mac_dsp(
    input [17:0] a,b,
    input [47:0] c,
    input clk,
    output [47:0] p
    );
    


   DSP48E1  sum1 (
  .CLK(clk),          // input wire CLK
  .CARRYIN(1'b0),  
  .A({{12{1'b0}},a}),              // input wire [17 : 0] A
  .C({48{1'b0}}),              
  .P(p),             // output wire [47 : 0] P
  .B(b),                // input wire [17:0] B
  .D({25{1'b1}}),
  .OPMODE(7'b1001000),
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
  .MULTSIGNIN(1'b0),
  .ACOUT(),
  .BCOUT(),
  .PCOUT(),
  .CARRYOUT(),
  .CARRYCASCOUT(),
  .MULTSIGNOUT(),
  .PATTERNDETECT(),
  .PATTERNBDETECT(),
  .OVERFLOW(),
  .UNDERFLOW()
);
endmodule
