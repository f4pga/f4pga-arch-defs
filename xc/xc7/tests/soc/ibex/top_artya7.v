module top (
	IO_CLK,
	IO_RST_N,
	LED
);
	input IO_CLK;
	input IO_RST_N;
	output [3:0] LED;
	parameter signed [31:0] MEM_SIZE = 65536;
	parameter [31:0] MEM_START = 32'h00000000;
	parameter [31:0] MEM_MASK = (MEM_SIZE - 1);
	wire clk_sys;
	wire rst_sys_n;
	wire instr_req;
	reg instr_gnt;
	wire instr_rvalid;
	wire [31:0] instr_addr;
	wire [31:0] instr_rdata;
	wire data_req;
	reg data_gnt;
	reg data_rvalid;
	wire data_we;
	wire [3:0] data_be;
	wire [31:0] data_addr;
	wire [31:0] data_wdata;
	wire [31:0] data_rdata;
	reg [31:0] mem_addr;
	reg mem_req;
	reg mem_write;
	reg [3:0] mem_be;
	reg [31:0] mem_wdata;
	wire mem_rvalid;
	wire [31:0] mem_rdata;
	ibex_core #(
		.DmHaltAddr(32'h00000000),
		.DmExceptionAddr(32'h00000000)
	) u_core(
		.clk_i(clk_sys),
		.rst_ni(rst_sys_n),
		.test_en_i('b0),
		.hart_id_i(32'b0),
		.boot_addr_i(32'h00000000),
		.instr_req_o(instr_req),
		.instr_gnt_i(instr_gnt),
		.instr_rvalid_i(instr_rvalid),
		.instr_addr_o(instr_addr),
		.instr_rdata_i(instr_rdata),
		.instr_err_i('b0),
		.data_req_o(data_req),
		.data_gnt_i(data_gnt),
		.data_rvalid_i(data_rvalid),
		.data_we_o(data_we),
		.data_be_o(data_be),
		.data_addr_o(data_addr),
		.data_wdata_o(data_wdata),
		.data_rdata_i(data_rdata),
		.data_err_i('b0),
		.irq_software_i(1'b0),
		.irq_timer_i(1'b0),
		.irq_external_i(1'b0),
		.irq_fast_i(15'b0),
		.irq_nm_i(1'b0),
		.debug_req_i('b0),
		.fetch_enable_i('b1),
		.core_sleep_o()
	);
	always @(*) begin
		mem_req = 1'b0;
		mem_addr = 32'b0;
		mem_write = 1'b0;
		mem_be = 4'b0;
		mem_wdata = 32'b0;
		if (instr_req) begin
			mem_req = ((instr_addr & ~MEM_MASK) == MEM_START);
			mem_addr = instr_addr;
		end
		else if (data_req) begin
			mem_req = ((data_addr & ~MEM_MASK) == MEM_START);
			mem_write = data_we;
			mem_be = data_be;
			mem_addr = data_addr;
			mem_wdata = data_wdata;
		end
	end
	ram_1p #(.Depth((MEM_SIZE / 4))) u_ram(
		.clk_i(clk_sys),
		.rst_ni(rst_sys_n),
		.req_i(mem_req),
		.we_i(mem_write),
		.be_i(mem_be),
		.addr_i(mem_addr),
		.wdata_i(mem_wdata),
		.rvalid_o(mem_rvalid),
		.rdata_o(mem_rdata)
	);
	assign instr_rdata = mem_rdata;
	assign data_rdata = mem_rdata;
	assign instr_rvalid = mem_rvalid;
	always @(posedge clk_sys or negedge rst_sys_n)
		if (!rst_sys_n) begin
			instr_gnt <= 'b0;
			data_gnt <= 'b0;
			data_rvalid <= 'b0;
		end
		else begin
			instr_gnt <= (instr_req && mem_req);
			data_gnt <= ((~instr_req && data_req) && mem_req);
			data_rvalid <= ((~instr_req && data_req) && mem_req);
		end
	reg [3:0] leds;
	always @(posedge clk_sys or negedge rst_sys_n)
		if (!rst_sys_n)
			leds <= 4'b0;
		else if (((mem_req && data_req) && data_we)) begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; (i < 4); i = (i + 1))
				if ((data_be[i] == 1'b1))
					leds <= data_wdata[(i * 8)+:4];
		end
	assign LED = leds;
	clkgen_xil7series clkgen(
		.IO_CLK(IO_CLK),
		.IO_RST_N(IO_RST_N),
		.clk_sys(clk_sys),
		.rst_sys_n(rst_sys_n)
	);
endmodule
