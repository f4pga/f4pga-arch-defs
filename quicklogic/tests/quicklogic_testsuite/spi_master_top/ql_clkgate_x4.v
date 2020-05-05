module ql_clkgate_x4(
					input clk_in   ,
					input en       ,
                    input se       ,
                    output clk_out   
					);
					
assign   clk_out = en ? clk_in: 1'b0;

endmodule 