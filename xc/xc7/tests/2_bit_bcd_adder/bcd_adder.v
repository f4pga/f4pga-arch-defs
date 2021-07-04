//////////////////////////////////////////////////////////////////////////////////
// Company: SymbiFlow
// Engineer: Ajinkya.S.Raghuwanshi
// 
// Design Name: 2 bit BCD adder Block
// Module Name: adder
// Project Name: DSP48E1 use in Artix7 board
// Target Devices: ARTIX7 Board
// Tool Versions: 
// Description: 
//
// This is a BCD adder module with DSP48E1 initantiated and
// used in vivado.
// Here we have only used the function or instruction : INST=  A * C
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// This is a Multipy and accumulate module with DSP48E1 initantiated and
// used in vivado.
// Here we have only used the function or instruction : INST=  A + C

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

// Dsp block instantiation
xbip_dsp48_macro_0 sum1 (
  .CLK(clk),          // input wire CLK
  .CARRYIN(cin),  // input wire CARRYIN
  .A(a),              // input wire [3 : 0] A
  .C(b),              // input wire [3 : 0] C
  .P(sum_temp1)              // output wire [4 : 0] P
);
//always block for doing the addition
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
