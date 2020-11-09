// -----------------------------------------------------------------------------
// title          : AL4S3B Example Fabric Register Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : ksa32.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2019/01/18	
// last update    : 2019/01/18
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: Kogg stone adder implementation.
// -----------------------------------------------------------------------------
// copyright (c) 2019
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         description
// 2019/01/18      1.0        Anand A Wadke  Initial Release
//
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//
module ksa32 (a,b,cin,sum,cout);

input [31:0] a,b;
input cin;
output [31:0] sum;
output cout; 

wire [31:0] b_w;

wire [31:0] p,g,c;
wire [31:0] cp1,cg1, c_gen,s_gen;



assign b_w = b;

assign p = a ^ b_w;
assign g = a & b_w;


assign cp1[0] = p[0];
assign cg1[0] = g[0];

assign c_gen[0] = g[0];
assign s_gen[0] = p[0];



genvar cp_idx; 
generate 
for( cp_idx=1; cp_idx<32; cp_idx=cp_idx+1 ) 
begin  
assign cp1[cp_idx] = (p[cp_idx] & p[cp_idx-1]); 

assign cg1[cp_idx] = ((p[cp_idx] & g[cp_idx-1]) | g[cp_idx]);


assign c_gen[cp_idx] = (cp1[cp_idx] & c_gen[cp_idx-1]) | cg1[cp_idx]; 


assign s_gen[cp_idx] = p[cp_idx] ^ c_gen[cp_idx-1]; 



end 
endgenerate


assign cout = c_gen[31];
assign sum  = s_gen;

endmodule
