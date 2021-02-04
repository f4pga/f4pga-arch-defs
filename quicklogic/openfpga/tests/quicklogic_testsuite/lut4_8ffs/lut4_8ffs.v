
module lut4_8ffs(qck, qst, qrt,c, d_out);
   // Port Declaration
   input   qck;
   input [0:7]c;
   input   qst,qrt;
   output  [0:7]d_out;
   
genvar i;
generate for (i = 0; i < 8; i = i + 1) begin
   D_ff dut(.D(c[i]),.QCK(qck),.QRT(qrt),.QST(qst),.CQZ(d_out[i]));
   
end endgenerate
endmodule


module D_ff(input QCK,QRT,QST,D, output CQZ);

always @ (posedge QCK or posedge QST or posedge QRT)

begin
if (QST)
	CQZ <= 1'b1;
else if(QRT)
	CQZ <= 1'b1;
else
CQZ <= D;
end
endmodule
