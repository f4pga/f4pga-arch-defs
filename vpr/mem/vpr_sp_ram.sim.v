module VPR_SP_RAM #(
	parameter ADDR_WIDTH = 1,
	parameter DATA_WIDTH = 1
) (
	addr, data, we, out
);
	input wire [ADDR_WIDTH-1:0] addr;
	input wire [DATA_WIDTH-1:0] data;
	input wire we;
	output wire [DATA_WIDTH-1:0] out;

	localparam MEM_SIZE = 2 ** ADDR_WIDTH;

	reg [DATA_WIDTH-1:0] storage[MEM_SIZE-1:0];

	assign out = storage[addr];

endmodule
