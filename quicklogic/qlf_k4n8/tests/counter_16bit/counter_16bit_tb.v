// Copyright (c) 2018 QuickLogic Corporation.  All Rights Reserved.
//
// Description :
//    testbench for simple 16 bit up counter in Verilog HDL
//
// Version 1.0 : Initial Creation
//

`timescale 10ns /10ps
`define GSIM 1
module counter_16bit_tb; 
  reg clk, reset, enable; 
  wire [15:0] count;
  reg status; 
 
reg [15:0] count_compare; 

top DUT (.clk(clk), .reset(reset), .enable(enable), .count(count)); 

event terminate_sim;  
  initial begin  
  @ (terminate_sim);
    $display("FAIL"); 
    #5 $fatal; 
  end 

always @ (posedge clk) 
if (reset == 1'b1) begin
  count_compare <= 0; 
end else if ( enable == 1'b1) begin
  count_compare <= count_compare + 1; 
end

  initial begin
    clk = 0; 
    reset = 1; 
    enable = 0;
    #50 reset = 0;
    #50 enable = 1;
    #10 status = 0;
  end 
    
  always  
    #15 clk = !clk;     
  
  always @ (posedge clk) 
  if (count_compare != count) begin 
    $display ("DUT Error at time %d", $time); 
    $display (" Expected value %d, Got Value %d", count_compare, count); 
    status =1;
    #5 -> terminate_sim; 
  end 

  initial  begin
  $dumpfile("counter_16bit_tb.vcd");
  $dumpvars(0,counter_16bit_tb);
  $display("\t\ttime,\tclk,\treset,\tenable,\tcount"); 
  $monitor("%d,\t%b,\t%b,\t%b,\t%d",$time, clk,reset,enable,count);
  if(status == 1'b0)
	 $display("PASS"); 
  end 

  initial 
  #3000 $finish;     
  
endmodule
