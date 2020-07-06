module flash_ctrl (
	clk_i,
	rst_ni,
	tl_i,
	tl_o,
	flash_i,
	flash_o,
	intr_prog_empty_o,
	intr_prog_lvl_o,
	intr_rd_full_o,
	intr_rd_lvl_o,
	intr_op_done_o,
	intr_op_error_o
);
	localparam top_pkg_FLASH_BYTES_PER_WORD = 4;
	localparam top_pkg_FLASH_AW = (top_pkg_FLASH_BKW + top_pkg_FLASH_PGW) + top_pkg_FLASH_WDW;
	localparam top_pkg_FLASH_BANKS = 2;
	localparam top_pkg_FLASH_BKW = 1;
	localparam top_pkg_FLASH_DW = top_pkg_FLASH_BYTES_PER_WORD * 8;
	localparam top_pkg_FLASH_PAGES_PER_BANK = 256;
	localparam top_pkg_FLASH_PGW = 8;
	localparam top_pkg_FLASH_WDW = 8;
	localparam top_pkg_FLASH_WORDS_PER_PAGE = 256;
	localparam top_pkg_TL_AIW = 8;
	localparam top_pkg_TL_AW = 32;
	localparam top_pkg_TL_DBW = top_pkg_TL_DW >> 3;
	localparam top_pkg_TL_DIW = 1;
	localparam top_pkg_TL_DUW = 16;
	localparam top_pkg_TL_DW = 32;
	localparam top_pkg_TL_SZW = $clog2($clog2(32 >> 3) + 1);
	input clk_i;
	input rst_ni;
	input wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_i;
	output wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_o;
	input wire [((3 + top_pkg_FLASH_DW) + 1) - 1:0] flash_i;
	output wire [((5 + top_pkg_FLASH_AW) + top_pkg_FLASH_DW) - 1:0] flash_o;
	output wire intr_prog_empty_o;
	output wire intr_prog_lvl_o;
	output wire intr_rd_full_o;
	output wire intr_rd_lvl_o;
	output wire intr_op_done_o;
	output wire intr_op_error_o;
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
	parameter signed [31:0] NumRegions = 8;
	parameter [6:0] FLASH_CTRL_INTR_STATE_OFFSET = 7'h 0;
	parameter [6:0] FLASH_CTRL_INTR_ENABLE_OFFSET = 7'h 4;
	parameter [6:0] FLASH_CTRL_INTR_TEST_OFFSET = 7'h 8;
	parameter [6:0] FLASH_CTRL_CONTROL_OFFSET = 7'h c;
	parameter [6:0] FLASH_CTRL_ADDR_OFFSET = 7'h 10;
	parameter [6:0] FLASH_CTRL_REGION_CFG_REGWEN_OFFSET = 7'h 14;
	parameter [6:0] FLASH_CTRL_MP_REGION_CFG0_OFFSET = 7'h 18;
	parameter [6:0] FLASH_CTRL_MP_REGION_CFG1_OFFSET = 7'h 1c;
	parameter [6:0] FLASH_CTRL_MP_REGION_CFG2_OFFSET = 7'h 20;
	parameter [6:0] FLASH_CTRL_MP_REGION_CFG3_OFFSET = 7'h 24;
	parameter [6:0] FLASH_CTRL_MP_REGION_CFG4_OFFSET = 7'h 28;
	parameter [6:0] FLASH_CTRL_MP_REGION_CFG5_OFFSET = 7'h 2c;
	parameter [6:0] FLASH_CTRL_MP_REGION_CFG6_OFFSET = 7'h 30;
	parameter [6:0] FLASH_CTRL_MP_REGION_CFG7_OFFSET = 7'h 34;
	parameter [6:0] FLASH_CTRL_DEFAULT_REGION_OFFSET = 7'h 38;
	parameter [6:0] FLASH_CTRL_BANK_CFG_REGWEN_OFFSET = 7'h 3c;
	parameter [6:0] FLASH_CTRL_MP_BANK_CFG_OFFSET = 7'h 40;
	parameter [6:0] FLASH_CTRL_OP_STATUS_OFFSET = 7'h 44;
	parameter [6:0] FLASH_CTRL_STATUS_OFFSET = 7'h 48;
	parameter [6:0] FLASH_CTRL_SCRATCH_OFFSET = 7'h 4c;
	parameter [6:0] FLASH_CTRL_FIFO_LVL_OFFSET = 7'h 50;
	parameter [6:0] FLASH_CTRL_PROG_FIFO_OFFSET = 7'h 54;
	parameter [6:0] FLASH_CTRL_PROG_FIFO_SIZE = 7'h 4;
	parameter [6:0] FLASH_CTRL_RD_FIFO_OFFSET = 7'h 58;
	parameter [6:0] FLASH_CTRL_RD_FIFO_SIZE = 7'h 4;
	parameter [83:0] FLASH_CTRL_PERMIT = {4'b 0001, 4'b 0001, 4'b 0001, 4'b 1111, 4'b 1111, 4'b 0001, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0111, 4'b 1111, 4'b 0011};
	localparam FLASH_CTRL_INTR_STATE = 0;
	localparam FLASH_CTRL_INTR_ENABLE = 1;
	localparam FLASH_CTRL_MP_REGION_CFG4 = 10;
	localparam FLASH_CTRL_MP_REGION_CFG5 = 11;
	localparam FLASH_CTRL_MP_REGION_CFG6 = 12;
	localparam FLASH_CTRL_MP_REGION_CFG7 = 13;
	localparam FLASH_CTRL_DEFAULT_REGION = 14;
	localparam FLASH_CTRL_BANK_CFG_REGWEN = 15;
	localparam FLASH_CTRL_MP_BANK_CFG = 16;
	localparam FLASH_CTRL_OP_STATUS = 17;
	localparam FLASH_CTRL_STATUS = 18;
	localparam FLASH_CTRL_SCRATCH = 19;
	localparam FLASH_CTRL_INTR_TEST = 2;
	localparam FLASH_CTRL_FIFO_LVL = 20;
	localparam FLASH_CTRL_CONTROL = 3;
	localparam FLASH_CTRL_ADDR = 4;
	localparam FLASH_CTRL_REGION_CFG_REGWEN = 5;
	localparam FLASH_CTRL_MP_REGION_CFG0 = 6;
	localparam FLASH_CTRL_MP_REGION_CFG1 = 7;
	localparam FLASH_CTRL_MP_REGION_CFG2 = 8;
	localparam FLASH_CTRL_MP_REGION_CFG3 = 9;
	localparam signed [31:0] NumBanks = top_pkg_FLASH_BANKS;
	localparam signed [31:0] PagesPerBank = top_pkg_FLASH_PAGES_PER_BANK;
	localparam signed [31:0] WordsPerPage = top_pkg_FLASH_WORDS_PER_PAGE;
	localparam signed [31:0] BankW = top_pkg_FLASH_BKW;
	localparam signed [31:0] PageW = top_pkg_FLASH_PGW;
	localparam signed [31:0] WordW = top_pkg_FLASH_WDW;
	localparam signed [31:0] AllPagesW = BankW + PageW;
	localparam signed [31:0] AddrW = top_pkg_FLASH_AW;
	localparam signed [31:0] DataWidth = top_pkg_FLASH_DW;
	localparam signed [31:0] DataBitWidth = 2;
	localparam signed [31:0] EraseBitWidth = 1;
	localparam signed [31:0] FifoDepth = 16;
	localparam signed [31:0] FifoDepthW = 5;
	localparam signed [31:0] MpRegions = 8;
	wire [295:0] reg2hw;
	wire [32:0] hw2reg;
	wire [((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (2 * ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17)) + -1 : (2 * (2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17))) + ((((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1) - 1)):((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1)] tl_fifo_h2d;
	wire [((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (2 * ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2)) + -1 : (2 * (2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2))) + ((((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1) - 1)):((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1)] tl_fifo_d2h;
	flash_ctrl_reg_top u_reg(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_i(tl_i),
		.tl_o(tl_o),
		.tl_win_o(tl_fifo_h2d),
		.tl_win_i(tl_fifo_d2h),
		.reg2hw(reg2hw),
		.hw2reg(hw2reg),
		.devmode_i(1'b1)
	);
	wire prog_fifo_wready;
	wire prog_fifo_rvalid;
	wire prog_fifo_req;
	wire prog_fifo_wen;
	wire prog_fifo_ren;
	wire [DataWidth - 1:0] prog_fifo_wdata;
	wire [DataWidth - 1:0] prog_fifo_rdata;
	wire [FifoDepthW - 1:0] prog_fifo_depth;
	wire rd_fifo_wready;
	wire rd_fifo_rvalid;
	wire rd_fifo_wen;
	wire rd_fifo_ren;
	wire [DataWidth - 1:0] rd_fifo_wdata;
	wire [DataWidth - 1:0] rd_fifo_rdata;
	wire [FifoDepthW - 1:0] rd_fifo_depth;
	wire prog_flash_req;
	wire prog_flash_ovfl;
	wire [AddrW - 1:0] prog_flash_addr;
	wire rd_flash_req;
	wire rd_flash_ovfl;
	wire [AddrW - 1:0] rd_flash_addr;
	wire erase_flash_req;
	wire [AddrW - 1:0] erase_flash_addr;
	wire [EraseBitWidth - 1:0] erase_flash_type;
	wire [2:0] ctrl_done;
	wire [2:0] ctrl_err;
	reg flash_req;
	wire flash_rd_done;
	wire flash_prog_done;
	wire flash_erase_done;
	wire flash_error;
	reg [AddrW - 1:0] flash_addr;
	wire [DataWidth - 1:0] flash_prog_data;
	wire [DataWidth - 1:0] flash_rd_data;
	wire init_busy;
	wire rd_op;
	wire prog_op;
	wire erase_op;
	wire [AllPagesW - 1:0] err_page;
	wire [BankW - 1:0] err_bank;
	assign rd_op = reg2hw[270-:2] == FlashRead;
	assign prog_op = reg2hw[270-:2] == FlashProg;
	assign erase_op = reg2hw[270-:2] == FlashErase;
	tlul_adapter_sram #(
		.SramAw(1),
		.SramDw(DataWidth),
		.ByteAccess(0),
		.ErrOnRead(1)
	) u_to_prog_fifo(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_i(tl_fifo_h2d[((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1) + ((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17))+:((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17))]),
		.tl_o(tl_fifo_d2h[((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1) + ((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2))+:((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2))]),
		.req_o(prog_fifo_req),
		.gnt_i(prog_fifo_wready),
		.we_o(prog_fifo_wen),
		.addr_o(),
		.wmask_o(),
		.wdata_o(prog_fifo_wdata),
		.rdata_i(sv2v_cast_664F5(0)),
		.rvalid_i(1'b0),
		.rerror_i(2'b0)
	);
	prim_fifo_sync #(
		.Width(DataWidth),
		.Depth(FifoDepth)
	) u_prog_fifo(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.clr_i(reg2hw[267]),
		.wvalid(prog_fifo_req & prog_fifo_wen),
		.wready(prog_fifo_wready),
		.wdata(prog_fifo_wdata),
		.depth(prog_fifo_depth),
		.rvalid(prog_fifo_rvalid),
		.rready(prog_fifo_ren),
		.rdata(prog_fifo_rdata)
	);
	flash_prog_ctrl #(
		.DataW(DataWidth),
		.AddrW(AddrW)
	) u_flash_prog_ctrl(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.op_start_i(reg2hw[271] & prog_op),
		.op_num_words_i(reg2hw[266-:12]),
		.op_done_o(ctrl_done[0]),
		.op_err_o(ctrl_err[0]),
		.op_addr_i(reg2hw[223 + DataBitWidth+:AddrW]),
		.data_i(prog_fifo_rdata),
		.data_rdy_i(prog_fifo_rvalid),
		.data_rd_o(prog_fifo_ren),
		.flash_req_o(prog_flash_req),
		.flash_addr_o(prog_flash_addr),
		.flash_ovfl_o(prog_flash_ovfl),
		.flash_data_o(flash_prog_data),
		.flash_done_i(flash_prog_done),
		.flash_error_i(flash_error)
	);
	reg adapter_rvalid;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			adapter_rvalid <= 1'b0;
		else
			adapter_rvalid <= rd_fifo_ren && rd_fifo_rvalid;
	tlul_adapter_sram #(
		.SramAw(1),
		.SramDw(DataWidth),
		.ByteAccess(0),
		.ErrOnWrite(1)
	) u_to_rd_fifo(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_i(tl_fifo_h2d[((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1)+:((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17))]),
		.tl_o(tl_fifo_d2h[((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1)+:((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2))]),
		.req_o(rd_fifo_ren),
		.gnt_i(rd_fifo_rvalid),
		.we_o(),
		.addr_o(),
		.wmask_o(),
		.wdata_o(),
		.rdata_i(rd_fifo_rdata),
		.rvalid_i(adapter_rvalid),
		.rerror_i(2'b0)
	);
	prim_fifo_sync #(
		.Width(DataWidth),
		.Depth(FifoDepth)
	) u_rd_fifo(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.clr_i(reg2hw[267]),
		.wvalid(rd_fifo_wen),
		.wready(rd_fifo_wready),
		.wdata(rd_fifo_wdata),
		.depth(rd_fifo_depth),
		.rvalid(rd_fifo_rvalid),
		.rready(adapter_rvalid),
		.rdata(rd_fifo_rdata)
	);
	flash_rd_ctrl #(
		.DataW(DataWidth),
		.AddrW(AddrW)
	) u_flash_rd_ctrl(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.op_start_i(reg2hw[271] & rd_op),
		.op_num_words_i(reg2hw[266-:12]),
		.op_done_o(ctrl_done[1]),
		.op_err_o(ctrl_err[1]),
		.op_addr_i(reg2hw[223 + DataBitWidth+:AddrW]),
		.data_rdy_i(rd_fifo_wready),
		.data_o(rd_fifo_wdata),
		.data_wr_o(rd_fifo_wen),
		.flash_req_o(rd_flash_req),
		.flash_addr_o(rd_flash_addr),
		.flash_ovfl_o(rd_flash_ovfl),
		.flash_data_i(flash_rd_data),
		.flash_done_i(flash_rd_done),
		.flash_error_i(flash_error)
	);
	flash_erase_ctrl #(
		.AddrW(AddrW),
		.PagesPerBank(PagesPerBank),
		.WordsPerPage(WordsPerPage),
		.EraseBitWidth(EraseBitWidth)
	) u_flash_erase_ctrl(
		.op_start_i(reg2hw[271] & erase_op),
		.op_type_i(reg2hw[268]),
		.op_done_o(ctrl_done[2]),
		.op_err_o(ctrl_err[2]),
		.op_addr_i(reg2hw[223 + DataBitWidth+:AddrW]),
		.flash_req_o(erase_flash_req),
		.flash_addr_o(erase_flash_addr),
		.flash_op_o(erase_flash_type),
		.flash_done_i(flash_erase_done),
		.flash_error_i(flash_error)
	);
	always @(*)
		case (reg2hw[270-:2])
			FlashRead: begin
				flash_req = rd_flash_req;
				flash_addr = rd_flash_addr;
			end
			FlashProg: begin
				flash_req = prog_flash_req;
				flash_addr = prog_flash_addr;
			end
			FlashErase: begin
				flash_req = erase_flash_req;
				flash_addr = erase_flash_addr;
			end
			default: begin
				flash_req = 1'b0;
				flash_addr = 1'sb0;
			end
		endcase
	wire [((MpRegions + 1) * 22) + -1:0] region_cfgs;
	assign region_cfgs[22 * ((MpRegions - 1) - (MpRegions - 1))+:22 * MpRegions] = reg2hw[47 + (22 * ((MpRegions - 1) - (MpRegions - 1)))+:22 * MpRegions];
	assign region_cfgs[(MpRegions * 22) + 17-:9] = 1'sb0;
	assign region_cfgs[(MpRegions * 22) + 8-:9] = {AllPagesW {1'b1}};
	assign region_cfgs[(MpRegions * 22) + 21] = 1'b1;
	assign region_cfgs[(MpRegions * 22) + 20] = reg2hw[46];
	assign region_cfgs[(MpRegions * 22) + 19] = reg2hw[45];
	assign region_cfgs[(MpRegions * 22) + 18] = reg2hw[44];
	flash_mp #(
		.MpRegions(MpRegions),
		.NumBanks(NumBanks),
		.AllPagesW(AllPagesW)
	) u_flash_mp(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.region_cfgs_i(region_cfgs),
		.bank_cfgs_i(reg2hw[43-:2]),
		.req_i(flash_req),
		.req_addr_i(flash_addr[WordW+:AllPagesW]),
		.addr_ovfl_i(rd_flash_ovfl | prog_flash_ovfl),
		.req_bk_i(flash_addr[WordW + PageW+:BankW]),
		.rd_i(rd_op),
		.prog_i(prog_op),
		.pg_erase_i(erase_op & (erase_flash_type == PageErase)),
		.bk_erase_i(erase_op & (erase_flash_type == BankErase)),
		.rd_done_o(flash_rd_done),
		.prog_done_o(flash_prog_done),
		.erase_done_o(flash_erase_done),
		.error_o(flash_error),
		.err_addr_o(err_page),
		.err_bank_o(err_bank),
		.req_o(flash_o[1 + (1 + (1 + (1 + (1 + (top_pkg_FLASH_AW + (top_pkg_FLASH_DW + -1))))))]),
		.rd_o(flash_o[1 + (1 + (1 + (1 + (top_pkg_FLASH_AW + (top_pkg_FLASH_DW + -1)))))]),
		.prog_o(flash_o[1 + (1 + (1 + (top_pkg_FLASH_AW + (top_pkg_FLASH_DW + -1))))]),
		.pg_erase_o(flash_o[1 + (1 + (top_pkg_FLASH_AW + (top_pkg_FLASH_DW + -1)))]),
		.bk_erase_o(flash_o[1 + (top_pkg_FLASH_AW + (top_pkg_FLASH_DW + -1))]),
		.rd_done_i(flash_i[1 + (1 + (1 + top_pkg_FLASH_DW))]),
		.prog_done_i(flash_i[1 + (1 + top_pkg_FLASH_DW)]),
		.erase_done_i(flash_i[1 + top_pkg_FLASH_DW])
	);
	assign hw2reg[18] = 1'b1;
	assign hw2reg[17] = |ctrl_done;
	assign hw2reg[16] = 1'b1;
	assign hw2reg[15] = |ctrl_err;
	assign hw2reg[14] = ~rd_fifo_wready;
	assign hw2reg[13] = ~rd_fifo_rvalid;
	assign hw2reg[12] = ~prog_fifo_wready;
	assign hw2reg[11] = ~prog_fifo_rvalid;
	assign hw2reg[10] = init_busy;
	assign hw2reg[9-:9] = err_page;
	assign hw2reg[0] = err_bank;
	assign hw2reg[20] = 1'b0;
	assign hw2reg[19] = |ctrl_done;
	assign flash_o[top_pkg_FLASH_AW + (top_pkg_FLASH_DW + -1)-:((top_pkg_FLASH_AW + (top_pkg_FLASH_DW + -1)) - top_pkg_FLASH_DW) + 1] = flash_addr;
	assign flash_o[top_pkg_FLASH_DW + -1-:top_pkg_FLASH_DW] = flash_prog_data;
	assign flash_rd_data = flash_i[top_pkg_FLASH_DW-:top_pkg_FLASH_DW];
	assign init_busy = flash_i[0];
	wire [3:0] intr_src;
	reg [3:0] intr_src_q;
	wire [3:0] intr_assert;
	assign intr_src = {~prog_fifo_rvalid, reg2hw[9-:5] == prog_fifo_depth, ~rd_fifo_wready, reg2hw[4-:5] == rd_fifo_depth};
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			intr_src_q <= 4'h8;
		else
			intr_src_q <= intr_src;
	assign intr_assert = ~intr_src_q & intr_src;
	assign intr_prog_empty_o = reg2hw[289] & reg2hw[295];
	assign intr_prog_lvl_o = reg2hw[288] & reg2hw[294];
	assign intr_rd_full_o = reg2hw[287] & reg2hw[293];
	assign intr_rd_lvl_o = reg2hw[286] & reg2hw[292];
	assign intr_op_done_o = reg2hw[285] & reg2hw[291];
	assign intr_op_error_o = reg2hw[284] & reg2hw[290];
	assign hw2reg[32] = 1'b1;
	assign hw2reg[31] = intr_assert[3] | (reg2hw[282] & reg2hw[283]);
	assign hw2reg[30] = 1'b1;
	assign hw2reg[29] = intr_assert[2] | (reg2hw[280] & reg2hw[281]);
	assign hw2reg[28] = 1'b1;
	assign hw2reg[27] = intr_assert[1] | (reg2hw[278] & reg2hw[279]);
	assign hw2reg[26] = 1'b1;
	assign hw2reg[25] = intr_assert[0] | (reg2hw[276] & reg2hw[277]);
	assign hw2reg[24] = 1'b1;
	assign hw2reg[23] = |ctrl_done | (reg2hw[274] & reg2hw[275]);
	assign hw2reg[22] = 1'b1;
	assign hw2reg[21] = |ctrl_err | (reg2hw[272] & reg2hw[273]);
	wire [DataBitWidth - 1:0] unused_byte_sel;
	wire [31 - AddrW:0] unused_higher_addr_bits;
	wire [31:0] unused_scratch;
	assign unused_byte_sel = reg2hw[223 + (DataBitWidth - 1):223];
	assign unused_higher_addr_bits = reg2hw[254:223 + AddrW];
	assign unused_scratch = reg2hw[41-:32];
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
	function automatic [top_pkg_FLASH_DW - 1:0] sv2v_cast_664F5;
		input reg [top_pkg_FLASH_DW - 1:0] inp;
		sv2v_cast_664F5 = inp;
	endfunction
endmodule
