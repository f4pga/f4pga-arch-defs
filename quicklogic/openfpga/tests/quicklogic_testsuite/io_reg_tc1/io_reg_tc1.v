module io_reg_tc1 (mux_in, demux_out,mux_sel, demux_sel,clk);
input [0:511] mux_in;
input [8:0]mux_sel; 
input clk;
input [8:0]demux_sel;
output [511:0]demux_out;

mux_512x1 mux0 (.in(mux_in),.sel(mux_sel),.out(mux_out),.clk(clk));
demux_1x512 demux0 (.in(mux_out),.sel(demux_sel),.out(demux_out),.clk(clk));

endmodule 

