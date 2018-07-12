`include "../../../../vpr/ff/vpr_ff.sim.v"
`include "../../../../vpr/mem/vpr_sp_ram.sim.v"

module single_port_ram_seq_comb (we, addr, data, clk, out);
	localparam ADDR_WIDTH = 9;
	localparam DATA_WIDTH = 64;

	input wire we;
	input wire [ADDR_WIDTH-1:0] addr;
	input wire [DATA_WIDTH-1:0] data;
	input wire clk;
	output wire [DATA_WIDTH-1:0] out;

	wire [ADDR_WIDTH-1:0] q_addr;
	generate
		genvar i;
		for (i=0; i < ADDR_WIDTH; i=i+1) begin
			VPR_FF ff(
				.D(addr[i]),
				.clk(clk),
				.Q(q_addr[i]),
			);
		end
	endgenerate

	wire [DATA_WIDTH-1:0] q_data;
	generate
		genvar i;
		for (i=0; i < DATA_WIDTH; i=i+1) begin
			VPR_FF ff(
				.D(data[i]),
				.clk(clk),
				.Q(q_data[i]),
			);
		end
	endgenerate

	VPR_SP_RAM #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) storage (
		.we(we),
		.addr(q_addr),
		.data(q_data),
		.out(out)
	);

	wire [DATA_WIDTH-1:0] o_out;
	generate
		genvar i;
		for (i=0; i < DATA_WIDTH; i=i+1) begin
			VPR_FF ff(
				.D(o_out[i]),
				.clk(clk),
				.Q(out[i]),
			);
		end
	endgenerate

endmodule
