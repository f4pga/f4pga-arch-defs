`timescale 1ns / 1ps

module dsp12(
input wire [9:0]sw,
input wire [9:0]sw2,
output wire [19:0]led
    );
  assign led=sw*sw2;
endmodule

module top(
 input wire [5:0]sw,
 input wire clk,
 output reg [9:0]led
);
 reg [9:0] in1;
 wire [19:0] led_out;
 wire [9:0] led_out2;
 always @(posedge clk) begin
  if(in1==10'b1111_1111_11) begin
    in1<=10'b0;
    end
   else begin
    in1<=in1+1'b1;
    end
  end
  reg [5:0]sw1;
  always @(*) begin
    sw1<=~sw;
  end
  
 dsp12 dsp(
  .sw(in1),
  .sw2({4'd0,sw1}),
  .led(led_out)
 );
  assign led_out2=~led_out[9:0];
 always @(*)
   led <= led_out2;
endmodule
