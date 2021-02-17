module decoder_3x8 (b,en,y);

input [2:0] b;
input en;
output reg [7:0] y;

always @(b,en)
begin
 if(en == 0)
  y = 0;
 else
   case (b)
   3'b 000 : y = 8'b 00000001;
   3'b 001 : y = 8'b 00000010;
   3'b 010 : y = 8'b 00000100;
   3'b 011 : y = 8'b 00001000;
   3'b 100 : y = 8'b 00010000;
   3'b 101 : y = 8'b 00100000;
   3'b 110 : y = 8'b 01000000;
   3'b 111 : y = 8'b 10000000;
   endcase
end
endmodule 