
module lut4_ff_rst_share ( I0, I1, I2, I3, I4, I5, I6, I7, CLK, rst, OUT, and_out);

   input [3:0] I0, I1, I2, I3, I4, I5, I6, I7;
   input   CLK, rst;
   output [10:0] OUT, and_out;
   genvar j;
   
   assign and_out[0]= I0[0]&I0[1]&I0[2]&rst;
   assign and_out[1]= I1[0]&I1[1]&I1[2]&rst;
   assign and_out[2]= I2[0]&I2[1]&I2[2]&rst;
   assign and_out[3]= I3[0]&I3[1]&I3[2]&rst;
   assign and_out[4]= I4[0]&I4[1]&I4[2]&rst;
   assign and_out[5]= I5[0]&I5[1]&I5[2]&rst;
   assign and_out[6]= I6[0]&I6[1]&I6[2]&rst;
   assign and_out[7]= I7[0]&I7[1]&I7[2]&rst;
   assign and_out[8]= I0[3]&I1[3]&I2[3]&rst;
   assign and_out[9]= I3[3]&I4[3]&I5[3]&rst;
   assign and_out[10]= I6[3]&I7[3]&I0[3]&rst;

generate
for(j=0;j<11;j=j+1)
begin     
     
     D_ff dut(.D(and_out[j]),.QCK(CLK),.QRT(rst),.CQZ(OUT[j]));
end
endgenerate


   
endmodule


module D_ff(input QCK,QRT,D, output CQZ);

always @ (posedge QCK )

begin
if(QRT)
	CQZ <= 1'b1;
else
CQZ <= D;
end
endmodule


