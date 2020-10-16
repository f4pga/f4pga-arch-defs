

/*-------------------------------------------------------------------------------
 MODULE NAME :  Up Counter with Count Enable, Terminal Count and Asynchronous Reset
 DESCRIPTION :						
--------------------------------------------------------------------------------*/
module top (count, clk, enable, set,comb_out);
parameter Width = 32;
input clk, enable, set;//, reset;
output [Width-1:0] count;
output comb_out;
reg [Width-1:0] count;
always @(posedge clk or posedge set)
if(set)
count <= 32'hFFFFFFFF;
//else if(set)
//count = 4'b1;
else if(enable)
count <= count + 1;
else
count <= 32'b0;

assign comb_out = enable &set;
endmodule  /* counter_4bit */







