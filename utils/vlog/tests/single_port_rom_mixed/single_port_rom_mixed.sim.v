module single_port_rom_mixed (addr, clk, out);
	localparam ADDR_WIDTH = 9;
	localparam DATA_WIDTH = 64;

	input wire [ADDR_WIDTH-1:0] addr;
	input wire clk;
	output wire [DATA_WIDTH-1:0] out;

	localparam MEM_SIZE = 2 ** ADDR_WIDTH;
	reg [DATA_WIDTH-1:0] storage[MEM_SIZE-1:0];

	reg q_addr;
	always @(posedge clk) begin
		q_addr <= addr;
	end

	assign out = storage[q_addr];

endmodule
