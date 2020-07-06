module debug_rom (
	clk_i,
	req_i,
	addr_i,
	rdata_o
);
	input wire clk_i;
	input wire req_i;
	input wire [63:0] addr_i;
	output reg [63:0] rdata_o;
	localparam [31:0] RomSize = 19;
	wire [(RomSize * 64) + -1:0] mem = {64'h00000000_7b200073, 64'h7b302573_7b202473, 64'h10852423_f1402473, 64'ha85ff06f_7b302573, 64'h7b202473_10052223, 64'h00100073_7b302573, 64'h7b202473_10052623, 64'h00c51513_00c55513, 64'h00000517_fd5ff06f, 64'hfa041ce3_00247413, 64'h40044403_00a40433, 64'hf1402473_02041c63, 64'h00147413_40044403, 64'h00a40433_10852023, 64'hf1402473_00c51513, 64'h00c55513_00000517, 64'h7b351073_7b241073, 64'h0ff0000f_04c0006f, 64'h07c0006f_00c0006f};
	reg [4:0] addr_q;
	always @(posedge clk_i)
		if (req_i)
			addr_q <= addr_i[7:3];
	always @(*) begin : p_outmux
		rdata_o = 1'sb0;
		if (addr_q < sv2v_cast_5(RomSize))
			rdata_o = mem[addr_q * 64+:64];
	end
	function automatic [4:0] sv2v_cast_5;
		input reg [4:0] inp;
		sv2v_cast_5 = inp;
	endfunction
endmodule
