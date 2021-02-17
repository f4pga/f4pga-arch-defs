
module ff_1000(qck, qrt,c, d_out);
   // Port Declaration
   input   qck;
   input [0:999]c;
   input  qrt;
   output  [0:999]d_out;

genvar i;
generate for (i = 0; i < 1000; i = i + 1) begin
   D_ff dut1(.D(c[i]),.QCK(qck),.QRT(qrt),.CQZ(d_out[i]));
  
end endgenerate
endmodule


module D_ff(input QCK,QRT,D, output reg CQZ);

always @ (posedge QCK or posedge QRT)

begin
if(QRT)
	CQZ <= 1'b1;
else
CQZ <= D;
end
endmodule
