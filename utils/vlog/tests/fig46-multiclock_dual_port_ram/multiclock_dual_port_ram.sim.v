`include "../../../../vpr/ff/vpr_ff.sim.v"

module multiclock_dual_port_ram (we1, addr1, data1, clk1, addr2, clk2, data2);
	localparam ADDR_WIDTH = 9;
	localparam DATA_WIDTH = 64;
	localparam MEM_SIZE = 2 ** ADDR_WIDTH;

	input wire we1;
	input wire [ADDR_WIDTH-1:0] addr1;
	input wire [DATA_WIDTH-1:0] data1;
	input wire clk1;

	input wire [ADDR_WIDTH-1:0] addr2;
	input wire clk2;
	output wire [DATA_WIDTH-1:0] data2;

	wire q_we1;
        VPR_FF ff(
                .D(we1),
                .clk(clk1),
                .Q(q_we1),
        );

	wire [ADDR_WIDTH-1:0] q_addr1;
	generate
		genvar i;
		for (i=0; i < ADDR_WIDTH; i=i+1) begin
			VPR_FF ff(
				.D(addr1[i]),
				.clk(clk1),
				.Q(q_addr1[i]),
			);
		end
	endgenerate

	wire [DATA_WIDTH-1:0] q_data1;
	generate
		genvar i;
		for (i=0; i < DATA_WIDTH; i=i+1) begin
			VPR_FF ff(
				.D(data1[i]),
				.clk(clk1),
				.Q(q_data1[i]),
			);
		end
	endgenerate

	wire [ADDR_WIDTH-1:0] q_addr2;
	generate
		genvar i;
		for (i=0; i < ADDR_WIDTH; i=i+1) begin
			VPR_FF ff(
				.D(addr2[i]),
				.clk(clk2),
				.Q(q_addr2[i]),
			);
		end
	endgenerate

	wire [DATA_WIDTH-1:0] o_data2;
	generate
		genvar i;
		for (i=0; i < DATA_WIDTH; i=i+1) begin
			VPR_FF ff(
				.D(o_data2[i]),
				.clk(clk2),
				.Q(data2[i]),
			);
		end
	endgenerate

	reg [DATA_WIDTH-1:0] storage[MEM_SIZE-1:0];

	assign o_data2 = storage[q_addr2];
	//assign storage[q_addr1] = q_data1;

endmodule
