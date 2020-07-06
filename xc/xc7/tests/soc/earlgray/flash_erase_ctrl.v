module flash_erase_ctrl (
	op_start_i,
	op_type_i,
	op_addr_i,
	op_done_o,
	op_err_o,
	flash_req_o,
	flash_addr_o,
	flash_op_o,
	flash_done_i,
	flash_error_i
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
	parameter signed [31:0] AddrW = 10;
	parameter signed [31:0] WordsPerPage = 256;
	parameter signed [31:0] PagesPerBank = 256;
	parameter signed [31:0] EraseBitWidth = 1;
	input op_start_i;
	input [EraseBitWidth - 1:0] op_type_i;
	input [AddrW - 1:0] op_addr_i;
	output wire op_done_o;
	output wire op_err_o;
	output wire flash_req_o;
	output wire [AddrW - 1:0] flash_addr_o;
	output wire [EraseBitWidth - 1:0] flash_op_o;
	input flash_done_i;
	input flash_error_i;
	localparam signed [31:0] FlashTotalPages = top_pkg_FLASH_BANKS * top_pkg_FLASH_PAGES_PER_BANK;
	localparam signed [31:0] AllPagesW = 9;
	parameter [((5 + top_pkg_FLASH_AW) + top_pkg_FLASH_DW) - 1:0] FLASH_REQ_DEFAULT = sv2v_struct_C7318(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'sb0, 1'sb0);
	parameter [((3 + top_pkg_FLASH_DW) + 1) - 1:0] FLASH_RSP_DEFAULT = sv2v_struct_BA92C(1'b0, 1'b0, 1'b0, 1'sb0, 1'b0);
	localparam [0:0] PageErase = 0;
	localparam [0:0] BankErase = 1;
	localparam [0:0] WriteDir = 1'b0;
	localparam [0:0] ReadDir = 1'b1;
	localparam [1:0] FlashRead = 2'h0;
	localparam [1:0] FlashProg = 2'h1;
	localparam [1:0] FlashErase = 2'h2;
	localparam signed [31:0] WordsBitWidth = $clog2(WordsPerPage);
	localparam signed [31:0] PagesBitWidth = $clog2(PagesPerBank);
	localparam [AddrW - 1:0] PageAddrMask = ~(('h1 << WordsBitWidth) - 1'b1);
	localparam [AddrW - 1:0] BankAddrMask = ~(('h1 << (PagesBitWidth + WordsBitWidth)) - 1'b1);
	assign op_done_o = flash_req_o & flash_done_i;
	assign op_err_o = flash_req_o & flash_error_i;
	assign flash_req_o = op_start_i;
	assign flash_op_o = op_type_i;
	assign flash_addr_o = (op_type_i == PageErase ? op_addr_i & PageAddrMask : op_addr_i & BankAddrMask);
	wire [WordsBitWidth - 1:0] unused_addr_i;
	assign unused_addr_i = op_addr_i[WordsBitWidth - 1:0];
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
