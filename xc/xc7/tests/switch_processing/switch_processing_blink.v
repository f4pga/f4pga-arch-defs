module top(
    input [3:0] in,
    output [3:0] out,
    input clk,
    input rst
    );
    
    wire clk_2hz;
    clk_div #(
        .WIDTH(28),
        .N(28'h17D7840)
    ) inst (
        .clk(clk),
        .rst(~rst),
        .clk_out(clk_2hz)
    );
        
    assign out = clk_2hz ? in : 4'b0;
endmodule

module clk_div
#( 
parameter WIDTH = 3, // Width of the register required
parameter [WIDTH-1:0] N = 6// We will divide by 12 for example in this case
)
(clk,rst, clk_out);
 
	input clk;
	input rst;
	output clk_out;
	 
	reg [WIDTH-1:0] r_reg;
	wire [WIDTH-1:0] r_nxt;
	reg clk_track;
	 
	always @(posedge clk or posedge rst)
	 
	begin
	  if (rst)
		 begin
			r_reg <= 0;
		clk_track <= 1'b0;
		 end
	 
	  else if (r_nxt == N)
		   begin
			 r_reg <= 0;
			 clk_track <= ~clk_track;
		   end
	 
	  else 
		  r_reg <= r_nxt;
	end
	 
	assign r_nxt = r_reg+1;   	      
	assign clk_out = clk_track;
endmodule
