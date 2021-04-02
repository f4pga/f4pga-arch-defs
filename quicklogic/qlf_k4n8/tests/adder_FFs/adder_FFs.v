// Creating a scaleable adder


module adder_FFs(a,b,clk,clr,d_out,cout);

input [127:0] a,b;
output [127:0] d_out;
input clr, clk;
output [1:0]cout;

shift_reg sf1(.shift_in(a[0]),.clk(clk),.clr(clr),.shift_out(s_out_w));
adder ad1(.a(a),.b(b),.cin(s_out_w),.sum(d_out),.cout(cout[0]));
shift_reg sf2(.shift_in(cout[0]),.clk(clk),.clr(clr),.shift_out(cout[1]));


endmodule

module adder(cout, sum, a, b, cin);
parameter size = 128;  /* declare a parameter. default required */
output cout;
output [size-1:0] sum; 	 // sum uses the size parameter
input cin;
input [size-1:0] a, b;  // 'a' and 'b' use the size parameter

assign {cout, sum} = a + b + cin;

endmodule

module shift_reg #( parameter size = 128 ) (shift_in, clk, clr, shift_out);

   // Port Declaration
   input   shift_in;
   input   clk;
   input   clr;
   output  shift_out;
   
   reg [ size:0 ] shift; // shift register  
   
    always @ (posedge clk or posedge clr)
     begin
	if (clr)
          shift = 0;	  	
	else 
	  shift = { shift[size-1:0] , shift_in } ;	
     end
   
   assign shift_out = shift[size];   
   
endmodule 







