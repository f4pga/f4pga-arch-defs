module single_port_ram_mixed (we, addr, data, clk, out);
	localparam ADDR_WIDTH = 9;
	localparam DATA_WIDTH = 64;

	input wire we;
	input wire [ADDR_WIDTH-1:0] addr;
	input wire [DATA_WIDTH-1:0] data;
	input wire clk;
	output wire [DATA_WIDTH-1:0] out;

	localparam MEM_SIZE = 2 ** ADDR_WIDTH;
	reg [DATA_WIDTH-1:0] storage[MEM_SIZE-1:0];

	reg q_we;
	reg q_addr;
	reg q_data;
	always @(posedge clk) begin
		q_we = we;
		q_addr = addr;
		q_data = data;
		if (q_we) begin
			storage[q_addr] <= q_data;
		end
	end

	assign out = storage[q_addr];

endmodule
