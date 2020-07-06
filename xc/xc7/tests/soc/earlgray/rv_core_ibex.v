module rv_core_ibex (
	clk_i,
	rst_ni,
	test_en_i,
	hart_id_i,
	boot_addr_i,
	tl_i_o,
	tl_i_i,
	tl_d_o,
	tl_d_i,
	irq_software_i,
	irq_timer_i,
	irq_external_i,
	irq_fast_i,
	irq_nm_i,
	debug_req_i,
	fetch_enable_i,
	core_sleep_o
);
	localparam [2:0] tlul_pkg_Get = 3'h 4;
	localparam [2:0] tlul_pkg_PutFullData = 3'h 0;
	localparam [2:0] tlul_pkg_PutPartialData = 3'h 1;
	localparam top_pkg_TL_AIW = 8;
	localparam top_pkg_TL_AW = 32;
	localparam top_pkg_TL_DBW = top_pkg_TL_DW >> 3;
	localparam top_pkg_TL_DIW = 1;
	localparam top_pkg_TL_DUW = 16;
	localparam top_pkg_TL_DW = 32;
	localparam top_pkg_TL_SZW = $clog2($clog2(32 >> 3) + 1);
	parameter PMPEnable = 1'b0;
	parameter [31:0] PMPGranularity = 0;
	parameter [31:0] PMPNumRegions = 4;
	parameter [31:0] MHPMCounterNum = 8;
	parameter [31:0] MHPMCounterWidth = 40;
	parameter RV32E = 0;
	parameter RV32M = 1;
	parameter DbgTriggerEn = 1'b1;
	parameter [31:0] DmHaltAddr = 32'h1A110800;
	parameter [31:0] DmExceptionAddr = 32'h1A110808;
	parameter PipeLine = 0;
	input wire clk_i;
	input wire rst_ni;
	input wire test_en_i;
	input wire [31:0] hart_id_i;
	input wire [31:0] boot_addr_i;
	output wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_i_o;
	input wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_i_i;
	output wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_d_o;
	input wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_d_i;
	input wire irq_software_i;
	input wire irq_timer_i;
	input wire irq_external_i;
	input wire [14:0] irq_fast_i;
	input wire irq_nm_i;
	input wire debug_req_i;
	input wire fetch_enable_i;
	output wire core_sleep_o;
	localparam TL_AW = 32;
	localparam TL_DW = 32;
	localparam TL_AIW = 8;
	localparam TL_DIW = 1;
	localparam TL_DUW = 16;
	localparam TL_DBW = TL_DW >> 3;
	localparam TL_SZW = $clog2($clog2(32 >> 3) + 1);
	localparam FLASH_BANKS = 2;
	localparam FLASH_PAGES_PER_BANK = 256;
	localparam FLASH_WORDS_PER_PAGE = 256;
	localparam FLASH_BYTES_PER_WORD = 4;
	localparam FLASH_BKW = 1;
	localparam FLASH_PGW = 8;
	localparam FLASH_WDW = 8;
	localparam FLASH_AW = (FLASH_BKW + FLASH_PGW) + FLASH_WDW;
	localparam FLASH_DW = FLASH_BYTES_PER_WORD * 8;
	parameter ArbiterImpl = "PPC";
	localparam [2:0] AccessAck = 3'h 0;
	localparam [2:0] PutFullData = 3'h 0;
	localparam [2:0] AccessAckData = 3'h 1;
	localparam [2:0] PutPartialData = 3'h 1;
	localparam [2:0] Get = 3'h 4;
	localparam signed [31:0] FifoPass = (PipeLine ? 1'b0 : 1'b1);
	localparam signed [31:0] FifoDepth = (PipeLine ? 4'h2 : 4'h0);
	localparam signed [31:0] WordSize = 2;
	wire instr_req_o;
	wire instr_gnt_i;
	wire instr_rvalid_i;
	wire [31:0] instr_addr_o;
	wire [31:0] instr_rdata_i;
	wire instr_err_i;
	wire data_req_o;
	wire data_gnt_i;
	wire data_rvalid_i;
	wire data_we_o;
	wire [3:0] data_be_o;
	wire [31:0] data_addr_o;
	wire [31:0] data_wdata_o;
	wire [31:0] data_rdata_i;
	wire data_err_i;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_i_ibex2fifo;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_i_fifo2ibex;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_d_ibex2fifo;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_d_fifo2ibex;
	ibex_core #(
		.PMPEnable(PMPEnable),
		.PMPGranularity(PMPGranularity),
		.PMPNumRegions(PMPNumRegions),
		.MHPMCounterNum(MHPMCounterNum),
		.MHPMCounterWidth(MHPMCounterWidth),
		.RV32E(RV32E),
		.RV32M(RV32M),
		.DbgTriggerEn(DbgTriggerEn),
		.DmHaltAddr(DmHaltAddr),
		.DmExceptionAddr(DmExceptionAddr)
	) u_core(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.test_en_i(test_en_i),
		.hart_id_i(hart_id_i),
		.boot_addr_i(boot_addr_i),
		.instr_req_o(instr_req_o),
		.instr_gnt_i(instr_gnt_i),
		.instr_rvalid_i(instr_rvalid_i),
		.instr_addr_o(instr_addr_o),
		.instr_rdata_i(instr_rdata_i),
		.instr_err_i(instr_err_i),
		.data_req_o(data_req_o),
		.data_gnt_i(data_gnt_i),
		.data_rvalid_i(data_rvalid_i),
		.data_we_o(data_we_o),
		.data_be_o(data_be_o),
		.data_addr_o(data_addr_o),
		.data_wdata_o(data_wdata_o),
		.data_rdata_i(data_rdata_i),
		.data_err_i(data_err_i),
		.irq_software_i(irq_software_i),
		.irq_timer_i(irq_timer_i),
		.irq_external_i(irq_external_i),
		.irq_fast_i(irq_fast_i),
		.irq_nm_i(irq_nm_i),
		.debug_req_i(debug_req_i),
		.fetch_enable_i(fetch_enable_i),
		.core_sleep_o(core_sleep_o)
	);
	reg tl_i_source;
	reg tl_d_source;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			{tl_i_source, tl_d_source} <= 1'sb0;
		else begin
			if (instr_req_o && instr_gnt_i)
				tl_i_source <= !tl_i_source;
			if (data_req_o && data_gnt_i)
				tl_d_source <= !tl_d_source;
		end
	assign tl_i_ibex2fifo = sv2v_struct_50735(instr_req_o, tlul_pkg_Get, 3'h0, sv2v_cast_2_signed(WordSize), sv2v_cast_8(tl_i_source), {instr_addr_o[31:WordSize], {WordSize {1'b0}}}, {TL_DBW {1'b1}}, {TL_DW {1'b0}}, sv2v_struct_8D9F8(1'sb0, 1'sb0, 1'sb0), 1'b1);
	assign instr_gnt_i = tl_i_fifo2ibex[0] & tl_i_ibex2fifo[1 + (3 + (3 + (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16)))))))];
	assign instr_rvalid_i = tl_i_fifo2ibex[1 + (3 + (3 + (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_DIW + (top_pkg_TL_DW + (top_pkg_TL_DUW + 1)))))))];
	assign instr_rdata_i = tl_i_fifo2ibex[top_pkg_TL_DW + (top_pkg_TL_DUW + 1)-:((top_pkg_TL_DW + (top_pkg_TL_DUW + 1)) - (top_pkg_TL_DUW + 2)) + 1];
	assign instr_err_i = tl_i_fifo2ibex[1];
	tlul_fifo_sync #(
		.ReqPass(FifoPass),
		.RspPass(FifoPass),
		.ReqDepth(FifoDepth),
		.RspDepth(FifoDepth)
	) fifo_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_h_i(tl_i_ibex2fifo),
		.tl_h_o(tl_i_fifo2ibex),
		.tl_d_o(tl_i_o),
		.tl_d_i(tl_i_i),
		.spare_req_i(1'b0),
		.spare_req_o(),
		.spare_rsp_i(1'b0),
		.spare_rsp_o()
	);
	assign tl_d_ibex2fifo = sv2v_struct_50735(data_req_o, (~data_we_o ? tlul_pkg_Get : (data_be_o == 4'hf ? tlul_pkg_PutFullData : tlul_pkg_PutPartialData)), 3'h0, sv2v_cast_2_signed(WordSize), sv2v_cast_8(tl_d_source), {data_addr_o[31:WordSize], {WordSize {1'b0}}}, data_be_o, data_wdata_o, sv2v_struct_8D9F8(1'sb0, 1'sb0, 1'sb0), 1'b1);
	assign data_gnt_i = tl_d_fifo2ibex[0] & tl_d_ibex2fifo[1 + (3 + (3 + (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16)))))))];
	assign data_rvalid_i = tl_d_fifo2ibex[1 + (3 + (3 + (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_DIW + (top_pkg_TL_DW + (top_pkg_TL_DUW + 1)))))))];
	assign data_rdata_i = tl_d_fifo2ibex[top_pkg_TL_DW + (top_pkg_TL_DUW + 1)-:((top_pkg_TL_DW + (top_pkg_TL_DUW + 1)) - (top_pkg_TL_DUW + 2)) + 1];
	assign data_err_i = tl_d_fifo2ibex[1];
	tlul_fifo_sync #(
		.ReqPass(FifoPass),
		.RspPass(FifoPass),
		.ReqDepth(FifoDepth),
		.RspDepth(FifoDepth)
	) fifo_d(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_h_i(tl_d_ibex2fifo),
		.tl_h_o(tl_d_fifo2ibex),
		.tl_d_o(tl_d_o),
		.tl_d_i(tl_d_i),
		.spare_req_i(1'b0),
		.spare_req_o(),
		.spare_rsp_i(1'b0),
		.spare_rsp_o()
	);
	function automatic [15:0] sv2v_struct_8D9F8;
		input reg [6:0] rsvd1;
		input reg parity_en;
		input reg [7:0] parity;
		sv2v_struct_8D9F8 = {rsvd1, parity_en, parity};
	endfunction
	function automatic [7:0] sv2v_cast_8;
		input reg [7:0] inp;
		sv2v_cast_8 = inp;
	endfunction
	function automatic [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + ((top_pkg_TL_AIW - 1) >= 0 ? top_pkg_TL_AIW : 2 - top_pkg_TL_AIW)) + ((top_pkg_TL_AW - 1) >= 0 ? top_pkg_TL_AW : 2 - top_pkg_TL_AW)) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + ((top_pkg_TL_DW - 1) >= 0 ? top_pkg_TL_DW : 2 - top_pkg_TL_DW)) + 17) - 1:0] sv2v_struct_50735;
		input reg a_valid;
		input reg [2:0] a_opcode;
		input reg [2:0] a_param;
		input reg [top_pkg_TL_SZW - 1:0] a_size;
		input reg [top_pkg_TL_AIW - 1:0] a_source;
		input reg [top_pkg_TL_AW - 1:0] a_address;
		input reg [top_pkg_TL_DBW - 1:0] a_mask;
		input reg [top_pkg_TL_DW - 1:0] a_data;
		input reg [15:0] a_user;
		input reg d_ready;
		sv2v_struct_50735 = {a_valid, a_opcode, a_param, a_size, a_source, a_address, a_mask, a_data, a_user, d_ready};
	endfunction
	function automatic signed [1:0] sv2v_cast_2_signed;
		input reg signed [1:0] inp;
		sv2v_cast_2_signed = inp;
	endfunction
endmodule
