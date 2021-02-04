
module lut4_ff_32x32 ( qck, qst, qrt,c, qen, d_out,);
 
   input   qck;

  
   input c;
   input qst,qrt,qen;

   output  d_out;
   
   
   wire [0:8016]t;
   genvar i,j;

assign t[0]=c;
generate
for(j=0;j<8016;j=j+1)
begin     
     
     D_ff dut1(.D(t[j]),.QCK(qck),.QRT(qrt),.QST(qst),.QEN(qen),.CQZ(t[j+1]));
end
endgenerate

assign d_out=t[8016];
endmodule




module D_ff(input QCK,QRT,QST,D, QEN, output CQZ);

always @ (posedge QCK )

begin
if (QEN)
begin
if (QST)
	CQZ <= 1'b1;
else if(QRT)
	CQZ <= 1'b1;
else
CQZ <= D;
end
end
endmodule
