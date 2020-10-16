// file           : baud_generator.v 
// description  : Baud Generator Module
// Modified        : 2013/09/09 
// Modified by     : Rakesh Moolacheri	
// -----------------------------------------------------------------------------
// copyright (c) 2012
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author              description
// 2008/xx/xx      1.0        XXXXX               created
// -----------------------------------------------------------------------------
// Comments: 
// -----------------------------------------------------------------------------
module baud_generator ( Baud_Rate_o,
						Bus_Clk_i, 
						Divisor_i,
						RST_i
					);	
	
	output 		Baud_Rate_o;
	input 		Bus_Clk_i;
	input [15:0]Divisor_i;
	input		RST_i; 

  
	reg [16:0] 	count16;
	reg 		Baud_Rate_r;
	wire [16:0] half_div; 
	wire [16:0] divisor_int;

	assign Baud_Rate_o = (Divisor_i[15:0] == 16'h0000)? Bus_Clk_i : Baud_Rate_r;
	assign half_div = {1'b0,Divisor_i[15:0]};
	assign divisor_int ={Divisor_i[15:0],1'b0};

	always @(posedge Bus_Clk_i or posedge RST_i)
	begin
		if (RST_i)
		begin
			count16 <= 17'h00000;
		end
		else begin
			if (count16 == divisor_int) 
				count16 <= 17'h00001;
			else
				count16 <= count16 + 1;
		end
	end

	always @(posedge Bus_Clk_i or posedge RST_i)
	begin
		if (RST_i)
		begin
			Baud_Rate_r <= 1'b0;
		end
		else begin
			if (count16 == divisor_int)
				Baud_Rate_r <= 1'b0;
			else if (count16 == half_div)
				Baud_Rate_r <= 1'b1;
			else 
				Baud_Rate_r <= Baud_Rate_r;
		end
	end

endmodule



