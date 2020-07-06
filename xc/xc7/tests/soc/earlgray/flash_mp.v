module flash_mp (
	clk_i,
	rst_ni,
	region_cfgs_i,
	bank_cfgs_i,
	req_i,
	req_addr_i,
	addr_ovfl_i,
	req_bk_i,
	rd_i,
	prog_i,
	pg_erase_i,
	bk_erase_i,
	rd_done_o,
	prog_done_o,
	erase_done_o,
	error_o,
	err_addr_o,
	err_bank_o,
	req_o,
	rd_o,
	prog_o,
	pg_erase_o,
	bk_erase_o,
	rd_done_i,
	prog_done_i,
	erase_done_i
);
	localparam top_pkg_FLASH_WORDS_PER_PAGE = 256;
	localparam top_pkg_FLASH_BKW = 1;
	localparam top_pkg_FLASH_BYTES_PER_WORD = 4;
	localparam top_pkg_FLASH_PGW = 8;
	localparam top_pkg_FLASH_WDW = 8;
	localparam top_pkg_FLASH_AW = (top_pkg_FLASH_BKW + top_pkg_FLASH_PGW) + top_pkg_FLASH_WDW;
	localparam top_pkg_FLASH_BANKS = 2;
	localparam top_pkg_FLASH_DW = top_pkg_FLASH_BYTES_PER_WORD * 8;
	localparam top_pkg_FLASH_PAGES_PER_BANK = 256;
	parameter signed [31:0] MpRegions = 8;
	parameter signed [31:0] NumBanks = 2;
	parameter signed [31:0] AllPagesW = 16;
	localparam signed [31:0] TotalRegions = MpRegions + 1;
	localparam signed [31:0] BankW = $clog2(NumBanks);
	input clk_i;
	input rst_ni;
	input wire [((TotalRegions - 1) >= 0 ? (TotalRegions * 22) + -1 : ((2 - TotalRegions) * 22) + (((TotalRegions - 1) * 22) - 1)):((TotalRegions - 1) >= 0 ? 0 : (TotalRegions - 1) * 22)] region_cfgs_i;
	input wire [((NumBanks - 1) >= 0 ? NumBanks + -1 : (2 - NumBanks) + ((NumBanks - 1) - 1)):((NumBanks - 1) >= 0 ? 0 : NumBanks - 1)] bank_cfgs_i;
	input req_i;
	input [AllPagesW - 1:0] req_addr_i;
	input addr_ovfl_i;
	input [BankW - 1:0] req_bk_i;
	input rd_i;
	input prog_i;
	input pg_erase_i;
	input bk_erase_i;
	output wire rd_done_o;
	output wire prog_done_o;
	output wire erase_done_o;
	output wire error_o;
	output reg [AllPagesW - 1:0] err_addr_o;
	output reg [BankW - 1:0] err_bank_o;
	output wire req_o;
	output wire rd_o;
	output wire prog_o;
	output wire pg_erase_o;
	output wire bk_erase_o;
	input rd_done_i;
	input prog_done_i;
	input erase_done_i;
	localparam signed [31:0] FlashTotalPages = top_pkg_FLASH_BANKS * top_pkg_FLASH_PAGES_PER_BANK;
	parameter [((5 + top_pkg_FLASH_AW) + top_pkg_FLASH_DW) - 1:0] FLASH_REQ_DEFAULT = sv2v_struct_C7318(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'sb0, 1'sb0);
	parameter [((3 + top_pkg_FLASH_DW) + 1) - 1:0] FLASH_RSP_DEFAULT = sv2v_struct_BA92C(1'b0, 1'b0, 1'b0, 1'sb0, 1'b0);
	localparam [0:0] PageErase = 0;
	localparam [0:0] BankErase = 1;
	localparam [0:0] WriteDir = 1'b0;
	localparam [0:0] ReadDir = 1'b1;
	localparam [1:0] FlashRead = 2'h0;
	localparam [1:0] FlashProg = 2'h1;
	localparam [1:0] FlashErase = 2'h2;
	reg [AllPagesW - 1:0] region_end [0:TotalRegions - 1];
	reg [TotalRegions - 1:0] region_match;
	wire [TotalRegions - 1:0] region_sel;
	reg [TotalRegions - 1:0] rd_en;
	reg [TotalRegions - 1:0] prog_en;
	reg [TotalRegions - 1:0] pg_erase_en;
	reg [NumBanks - 1:0] bk_erase_en;
	wire final_rd_en;
	wire final_prog_en;
	wire final_pg_erase_en;
	wire final_bk_erase_en;
	assign region_sel[0] = region_match[0];
	generate
		genvar i;
		for (i = 1; i < TotalRegions; i = i + 1) begin : gen_region_priority
			assign region_sel[i] = region_match[i] & ~|region_match[i - 1:0];
		end
	endgenerate
	always @(*) begin : sv2v_autoblock_148
		reg [31:0] i;
		for (i = 0; i < TotalRegions; i = i + 1)
			begin : region_comps
				region_end[i] = region_cfgs_i[(((TotalRegions - 1) >= 0 ? i : 0 - (i - (TotalRegions - 1))) * 22) + 17-:9] + region_cfgs_i[(((TotalRegions - 1) >= 0 ? i : 0 - (i - (TotalRegions - 1))) * 22) + 8-:9];
				region_match[i] = ((req_addr_i >= region_cfgs_i[(((TotalRegions - 1) >= 0 ? i : 0 - (i - (TotalRegions - 1))) * 22) + 17-:9]) & (req_addr_i < region_end[i])) & req_i;
				rd_en[i] = (region_cfgs_i[(((TotalRegions - 1) >= 0 ? i : 0 - (i - (TotalRegions - 1))) * 22) + 21] & region_cfgs_i[(((TotalRegions - 1) >= 0 ? i : 0 - (i - (TotalRegions - 1))) * 22) + 20]) & region_sel[i];
				prog_en[i] = (region_cfgs_i[(((TotalRegions - 1) >= 0 ? i : 0 - (i - (TotalRegions - 1))) * 22) + 21] & region_cfgs_i[(((TotalRegions - 1) >= 0 ? i : 0 - (i - (TotalRegions - 1))) * 22) + 19]) & region_sel[i];
				pg_erase_en[i] = (region_cfgs_i[(((TotalRegions - 1) >= 0 ? i : 0 - (i - (TotalRegions - 1))) * 22) + 21] & region_cfgs_i[(((TotalRegions - 1) >= 0 ? i : 0 - (i - (TotalRegions - 1))) * 22) + 18]) & region_sel[i];
			end
	end
	always @(*) begin : sv2v_autoblock_149
		reg [31:0] i;
		for (i = 0; i < NumBanks; i = i + 1)
			begin : bank_comps
				bk_erase_en[i] = (req_bk_i == i) & bank_cfgs_i[((NumBanks - 1) >= 0 ? i : 0 - (i - (NumBanks - 1)))];
			end
	end
	assign final_rd_en = rd_i & |rd_en;
	assign final_prog_en = prog_i & |prog_en;
	assign final_pg_erase_en = pg_erase_i & |pg_erase_en;
	assign final_bk_erase_en = bk_erase_i & |bk_erase_en;
	assign rd_o = req_i & final_rd_en;
	assign prog_o = req_i & final_prog_en;
	assign pg_erase_o = req_i & final_pg_erase_en;
	assign bk_erase_o = req_i & final_bk_erase_en;
	assign req_o = ((rd_o | prog_o) | pg_erase_o) | bk_erase_o;
	reg txn_err;
	wire txn_ens;
	wire no_allowed_txn;
	assign txn_ens = ((final_rd_en | final_prog_en) | final_pg_erase_en) | final_bk_erase_en;
	assign no_allowed_txn = req_i & (addr_ovfl_i | ~txn_ens);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			txn_err <= 1'b0;
			err_addr_o <= 1'sb0;
			err_bank_o <= 1'sb0;
		end
		else if (txn_err)
			txn_err <= 1'b0;
		else if (no_allowed_txn) begin
			txn_err <= 1'b1;
			err_addr_o <= req_addr_i;
			err_bank_o <= req_bk_i;
		end
	assign rd_done_o = rd_done_i | txn_err;
	assign prog_done_o = prog_done_i | txn_err;
	assign erase_done_o = erase_done_i | txn_err;
	assign error_o = txn_err;
	function automatic [((3 + ((top_pkg_FLASH_DW - 1) >= 0 ? top_pkg_FLASH_DW : 2 - top_pkg_FLASH_DW)) + 1) - 1:0] sv2v_struct_BA92C;
		input reg rd_done;
		input reg prog_done;
		input reg erase_done;
		input reg [top_pkg_FLASH_DW - 1:0] rd_data;
		input reg init_busy;
		sv2v_struct_BA92C = {rd_done, prog_done, erase_done, rd_data, init_busy};
	endfunction
	function automatic [((5 + ((top_pkg_FLASH_AW - 1) >= 0 ? top_pkg_FLASH_AW : 2 - top_pkg_FLASH_AW)) + ((top_pkg_FLASH_DW - 1) >= 0 ? top_pkg_FLASH_DW : 2 - top_pkg_FLASH_DW)) - 1:0] sv2v_struct_C7318;
		input reg req;
		input reg rd;
		input reg prog;
		input reg pg_erase;
		input reg bk_erase;
		input reg [top_pkg_FLASH_AW - 1:0] addr;
		input reg [top_pkg_FLASH_DW - 1:0] prog_data;
		sv2v_struct_C7318 = {req, rd, prog, pg_erase, bk_erase, addr, prog_data};
	endfunction
endmodule
