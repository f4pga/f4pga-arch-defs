// Copyright (C) 2021 The SymbiFlow Authors.
//
// Use of this source code is governed by a ISC-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/ISC
//
// SPDX-License-Identifier: ISC


// Description: 
//
// This is a BCD adder module with DSP48E1 initantiated and
// used in vivado.
// Here we have only used the function or instruction : INST=  A + C
// 

module adder( 
    input [16:0] sw,
    input clk,
    output [8:0] led);

    
    wire [7:0] a,b;
    wire cin;
    wire cout;
    wire [7:0] sum;
    assign a = sw[7:0];
    assign b = sw[15:8];
    assign cin = sw[16];
    assign led = {cout,sum};
	wire c10;
    bcd_fadd inst1 (.a(a[3:0]), .b(b[3:0]), .cin(cin), .cout(c10), .sum(sum[3:0]),.clk(clk));
    bcd_fadd inst2 (.a(a[7:4]), .b(b[7:4]), .cin(c10), .cout(cout), .sum(sum[7:4]),.clk(clk));
endmodule

module bcd_fadd (
    input [3:0] a, b,
    input cin,clk,
    output cout,
    output [3:0] sum
);
//Internal variables
    reg [4:0] sum_temp;
    wire [4:0] sum_temp1;
    reg [3:0] sum;
    reg cout;  
    wire [47:0] outp;
    
    assign sum_temp1 = outp[4:0];

// Dsp block instantiation
DSP48E1  sum1 (
  .CLK(clk),          // input wire CLK
  .CARRYIN(cin),  // input wire CARRYIN
  .A({{26{1'b0}},a}),              // input wire [3 : 0] A
  .C({{44{1'b0}},b}),              // input wire [3 : 0] C
  .P(outp),             // output wire [4 : 0] P
  .B({18{1'b1}}),
  .D({25{1'b1}}),
  .OPMODE(7'b0000011),
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
  .CARRYCASCIN(1'b1),
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
//always block for 1doing the addition
    always @(sum_temp1)
    begin
        if(sum_temp > 9)    begin
            sum_temp = sum_temp1+6; //add 6, if result is more than 9.
            cout = 1;  //set the carry output
            sum = sum_temp1[3:0];    end
        else    begin
            cout = 0;
            sum = sum_temp1[3:0];
        end
    end 
    
endmodule
