module spi_device (
	clk_i,
	rst_ni,
	tl_i,
	tl_o,
	cio_sck_i,
	cio_csb_i,
	cio_miso_o,
	cio_miso_en_o,
	cio_mosi_i,
	intr_rxf_o,
	intr_rxlvl_o,
	intr_txlvl_o,
	intr_rxerr_o,
	intr_rxoverflow_o,
	intr_txunderflow_o,
	scanmode_i
);
	localparam top_pkg_TL_AIW = 8;
	localparam top_pkg_TL_AW = 32;
	localparam top_pkg_TL_DBW = top_pkg_TL_DW >> 3;
	localparam top_pkg_TL_DIW = 1;
	localparam top_pkg_TL_DUW = 16;
	localparam top_pkg_TL_DW = 32;
	localparam top_pkg_TL_SZW = $clog2($clog2(32 >> 3) + 1);
	localparam FwModeRxFifo = 0;
	localparam FwModeTxFifo = 1;
	parameter signed [31:0] SramAw = 9;
	parameter signed [31:0] SramDw = 32;
	input clk_i;
	input rst_ni;
	input wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_i;
	output wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_o;
	input cio_sck_i;
	input cio_csb_i;
	output wire cio_miso_o;
	output wire cio_miso_en_o;
	input cio_mosi_i;
	output wire intr_rxf_o;
	output wire intr_rxlvl_o;
	output wire intr_txlvl_o;
	output wire intr_rxerr_o;
	output wire intr_rxoverflow_o;
	output wire intr_txunderflow_o;
	input scanmode_i;
	localparam signed [31:0] MEM_AW = 12;
	localparam [1:0] FwMode = 'h0;
	localparam [1:0] EepromRam = 'h1;
	localparam [1:0] EepromFlash = 'h2;
	localparam [1:0] PassThrough = 'h3;
	localparam [1:0] AddrByte = 2'h0;
	localparam [1:0] Spi = 2'h0;
	localparam [1:0] AddrWord = 2'h1;
	localparam [1:0] Espi = 2'h1;
	localparam [1:0] AddrFull = 2'h2;
	localparam [1:0] Tpm = 2'h2;
	localparam [7:0] Nop = 8'h00;
	localparam [7:0] WrSts = 8'h01;
	localparam [7:0] Write = 8'h02;
	localparam [7:0] Read = 8'h03;
	localparam [7:0] WrDi = 8'h04;
	localparam [7:0] RdSts = 8'h05;
	localparam [7:0] WrEn = 8'h06;
	localparam [7:0] HsRd = 8'h0B;
	localparam [7:0] RdSts2 = 8'h35;
	localparam [7:0] DlRd = 8'h3B;
	localparam [7:0] QdRd = 8'h6B;
	parameter [11:0] SPI_DEVICE_INTR_STATE_OFFSET = 12'h 0;
	parameter [11:0] SPI_DEVICE_INTR_ENABLE_OFFSET = 12'h 4;
	parameter [11:0] SPI_DEVICE_INTR_TEST_OFFSET = 12'h 8;
	parameter [11:0] SPI_DEVICE_CONTROL_OFFSET = 12'h c;
	parameter [11:0] SPI_DEVICE_CFG_OFFSET = 12'h 10;
	parameter [11:0] SPI_DEVICE_FIFO_LEVEL_OFFSET = 12'h 14;
	parameter [11:0] SPI_DEVICE_ASYNC_FIFO_LEVEL_OFFSET = 12'h 18;
	parameter [11:0] SPI_DEVICE_STATUS_OFFSET = 12'h 1c;
	parameter [11:0] SPI_DEVICE_RXF_PTR_OFFSET = 12'h 20;
	parameter [11:0] SPI_DEVICE_TXF_PTR_OFFSET = 12'h 24;
	parameter [11:0] SPI_DEVICE_RXF_ADDR_OFFSET = 12'h 28;
	parameter [11:0] SPI_DEVICE_TXF_ADDR_OFFSET = 12'h 2c;
	parameter [11:0] SPI_DEVICE_BUFFER_OFFSET = 12'h 800;
	parameter [11:0] SPI_DEVICE_BUFFER_SIZE = 12'h 800;
	parameter [47:0] SPI_DEVICE_PERMIT = {4'b 0001, 4'b 0001, 4'b 0001, 4'b 0111, 4'b 0011, 4'b 1111, 4'b 0111, 4'b 0001, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111};
	localparam SPI_DEVICE_INTR_STATE = 0;
	localparam SPI_DEVICE_INTR_ENABLE = 1;
	localparam SPI_DEVICE_RXF_ADDR = 10;
	localparam SPI_DEVICE_TXF_ADDR = 11;
	localparam SPI_DEVICE_INTR_TEST = 2;
	localparam SPI_DEVICE_CONTROL = 3;
	localparam SPI_DEVICE_CFG = 4;
	localparam SPI_DEVICE_FIFO_LEVEL = 5;
	localparam SPI_DEVICE_ASYNC_FIFO_LEVEL = 6;
	localparam SPI_DEVICE_STATUS = 7;
	localparam SPI_DEVICE_RXF_PTR = 8;
	localparam SPI_DEVICE_TXF_PTR = 9;
	localparam signed [31:0] FifoWidth = 8;
	localparam signed [31:0] FifoDepth = 8;
	localparam signed [31:0] SDW = $clog2(SramDw / 8);
	localparam signed [31:0] PtrW = (SramAw + 1) + SDW;
	localparam signed [31:0] AsFifoDepthW = 4;
	wire clk_spi_in;
	wire clk_spi_out;
	wire [168:0] reg2hw;
	wire [67:0] hw2reg;
	wire [((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 16 : (2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17)) + ((((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1) - 1)):((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1)] tl_sram_h2d;
	wire [((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 1 : (2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2)) + ((((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1) - 1)):((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1)] tl_sram_d2h;
	wire mem_a_req;
	wire mem_a_write;
	wire [SramAw - 1:0] mem_a_addr;
	wire [SramDw - 1:0] mem_a_wdata;
	wire mem_a_rvalid;
	wire [SramDw - 1:0] mem_a_rdata;
	wire [1:0] mem_a_rerror;
	wire mem_b_req;
	wire mem_b_write;
	wire [SramAw - 1:0] mem_b_addr;
	wire [SramDw - 1:0] mem_b_wdata;
	wire mem_b_rvalid;
	wire [SramDw - 1:0] mem_b_rdata;
	wire [1:0] mem_b_rerror;
	wire cpol;
	wire cpha;
	wire txorder;
	wire rxorder;
	wire abort;
	wire csb_syncd;
	wire rst_txfifo_n;
	wire rst_rxfifo_n;
	wire rst_txfifo_reg;
	wire rst_rxfifo_reg;
	wire [1:0] spi_mode;
	wire intr_sram_rxf_full;
	wire intr_fwm_rxerr;
	wire intr_fwm_rxlvl;
	reg rxlvl;
	wire rxlvl_d;
	wire intr_fwm_txlvl;
	reg txlvl;
	wire txlvl_d;
	wire intr_fwm_rxoverflow;
	wire intr_fwm_txunderflow;
	wire rxf_wvalid;
	wire rxf_wready;
	wire [7:0] rxf_wdata;
	wire rxf_overflow;
	wire rxf_rvalid;
	wire rxf_rready;
	wire [7:0] rxf_rdata;
	wire rxf_full_syncd;
	wire txf_rvalid;
	wire txf_rready;
	wire [7:0] txf_rdata;
	wire txf_underflow;
	wire txf_wvalid;
	wire txf_wready;
	wire [7:0] txf_wdata;
	wire txf_empty_syncd;
	wire [7:0] timer_v;
	wire [PtrW - 1:0] sram_rxf_rptr;
	wire [PtrW - 1:0] sram_rxf_wptr;
	wire [PtrW - 1:0] sram_txf_rptr;
	wire [PtrW - 1:0] sram_txf_wptr;
	wire [PtrW - 1:0] sram_rxf_depth;
	wire [PtrW - 1:0] sram_txf_depth;
	wire [SramAw - 1:0] sram_rxf_bindex;
	wire [SramAw - 1:0] sram_txf_bindex;
	wire [SramAw - 1:0] sram_rxf_lindex;
	wire [SramAw - 1:0] sram_txf_lindex;
	wire [1:0] fwm_sram_req;
	wire [((SramAw - 1) >= 0 ? (2 * SramAw) + -1 : (2 * (2 - SramAw)) + ((SramAw - 1) - 1)):((SramAw - 1) >= 0 ? 0 : SramAw - 1)] fwm_sram_addr;
	wire [0:1] fwm_sram_write;
	wire [((SramDw - 1) >= 0 ? (2 * SramDw) + -1 : (2 * (2 - SramDw)) + ((SramDw - 1) - 1)):((SramDw - 1) >= 0 ? 0 : SramDw - 1)] fwm_sram_wdata;
	wire [1:0] fwm_sram_gnt;
	wire [1:0] fwm_sram_rvalid;
	wire [((SramDw - 1) >= 0 ? (2 * SramDw) + -1 : (2 * (2 - SramDw)) + ((SramDw - 1) - 1)):((SramDw - 1) >= 0 ? 0 : SramDw - 1)] fwm_sram_rdata;
	wire [3:0] fwm_sram_error;
	wire [AsFifoDepthW - 1:0] as_txfifo_depth;
	wire [AsFifoDepthW - 1:0] as_rxfifo_depth;
	assign cpol = reg2hw[139];
	assign cpha = reg2hw[138];
	assign txorder = reg2hw[137];
	assign rxorder = reg2hw[136];
	assign rst_txfifo_reg = reg2hw[141];
	assign rst_rxfifo_reg = reg2hw[140];
	assign timer_v = reg2hw[135-:8];
	assign sram_rxf_bindex = reg2hw[32 + (16 + SDW)+:SramAw];
	assign sram_rxf_lindex = reg2hw[32 + SDW+:SramAw];
	assign sram_txf_bindex = reg2hw[16 + SDW+:SramAw];
	assign sram_txf_lindex = reg2hw[SDW+:SramAw];
	assign sram_rxf_rptr = reg2hw[80 + (PtrW - 1):80];
	assign hw2reg[33-:16] = {{16 - PtrW {1'b0}}, sram_rxf_wptr};
	assign hw2reg[17] = 1'b1;
	assign sram_txf_wptr = reg2hw[64 + (PtrW - 1):64];
	assign hw2reg[16-:16] = {{16 - PtrW {1'b0}}, sram_txf_rptr};
	assign hw2reg[0] = 1'b1;
	assign abort = reg2hw[144];
	assign hw2reg[35] = 1'b1;
	assign hw2reg[38] = ~rxf_rvalid;
	assign hw2reg[37] = ~txf_wready;
	assign hw2reg[39] = rxf_full_syncd;
	assign hw2reg[36] = txf_empty_syncd;
	assign hw2reg[34] = csb_syncd;
	prim_flop_2sync #(.Width(1)) u_sync_csb(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.d(cio_csb_i),
		.q(csb_syncd)
	);
	reg rxf_full_q;
	reg txf_empty_q;
	always @(posedge clk_spi_in or negedge rst_ni)
		if (!rst_ni)
			rxf_full_q <= 1'b0;
		else
			rxf_full_q <= ~rxf_wready;
	always @(posedge clk_spi_out or negedge rst_ni)
		if (!rst_ni)
			txf_empty_q <= 1'b1;
		else
			txf_empty_q <= ~txf_rvalid;
	prim_flop_2sync #(.Width(1)) u_sync_rxf(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.d(rxf_full_q),
		.q(rxf_full_syncd)
	);
	prim_flop_2sync #(
		.Width(1),
		.ResetValue(1'b1)
	) u_sync_txe(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.d(txf_empty_q),
		.q(txf_empty_syncd)
	);
	assign spi_mode = sv2v_cast_2(reg2hw[143-:2]);
	assign hw2reg[47-:8] = {{8 - AsFifoDepthW {1'b0}}, as_txfifo_depth};
	assign hw2reg[55-:8] = {{8 - AsFifoDepthW {1'b0}}, as_rxfifo_depth};
	reg sram_rxf_full_q;
	reg fwm_rxerr_q;
	wire sram_rxf_full;
	wire fwm_rxerr;
	assign fwm_rxerr = 1'b0;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			sram_rxf_full_q <= 1'b0;
			fwm_rxerr_q <= 1'b0;
		end
		else begin
			sram_rxf_full_q <= sram_rxf_full;
			fwm_rxerr_q <= fwm_rxerr;
		end
	assign intr_sram_rxf_full = ~sram_rxf_full_q & sram_rxf_full;
	assign intr_fwm_rxerr = ~fwm_rxerr_q & fwm_rxerr;
	assign rxlvl_d = sram_rxf_depth >= reg2hw[96 + (16 + (PtrW - 1)):112];
	assign txlvl_d = sram_txf_depth < reg2hw[96 + (PtrW - 1):96];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			rxlvl <= 1'b0;
			txlvl <= 1'b0;
		end
		else begin
			rxlvl <= rxlvl_d;
			txlvl <= txlvl_d;
		end
	assign intr_fwm_rxlvl = ~rxlvl && rxlvl_d;
	assign intr_fwm_txlvl = ~txlvl && txlvl_d;
	prim_pulse_sync u_rxf_overflow(
		.clk_src_i(clk_spi_in),
		.rst_src_ni(rst_ni),
		.src_pulse_i(rxf_overflow),
		.clk_dst_i(clk_i),
		.rst_dst_ni(rst_ni),
		.dst_pulse_o(intr_fwm_rxoverflow)
	);
	prim_pulse_sync u_txf_underflow(
		.clk_src_i(clk_spi_out),
		.rst_src_ni(rst_ni),
		.src_pulse_i(txf_underflow),
		.clk_dst_i(clk_i),
		.rst_dst_ni(rst_ni),
		.dst_pulse_o(intr_fwm_txunderflow)
	);
	assign intr_rxlvl_o = reg2hw[161] & reg2hw[167];
	assign intr_txlvl_o = reg2hw[160] & reg2hw[166];
	assign intr_rxf_o = reg2hw[162] & reg2hw[168];
	assign intr_rxerr_o = reg2hw[159] & reg2hw[165];
	assign intr_rxoverflow_o = reg2hw[158] & reg2hw[164];
	assign intr_txunderflow_o = reg2hw[157] & reg2hw[163];
	assign hw2reg[67] = 1'b1;
	assign hw2reg[66] = intr_sram_rxf_full | (reg2hw[155] & reg2hw[156]);
	assign hw2reg[61] = 1'b1;
	assign hw2reg[60] = intr_fwm_rxerr | (reg2hw[149] & reg2hw[150]);
	assign hw2reg[65] = 1'b1;
	assign hw2reg[64] = intr_fwm_rxlvl | (reg2hw[153] & reg2hw[154]);
	assign hw2reg[63] = 1'b1;
	assign hw2reg[62] = intr_fwm_txlvl | (reg2hw[151] & reg2hw[152]);
	assign hw2reg[59] = 1'b1;
	assign hw2reg[58] = intr_fwm_rxoverflow | (reg2hw[147] & reg2hw[148]);
	assign hw2reg[57] = 1'b1;
	assign hw2reg[56] = intr_fwm_txunderflow | (reg2hw[145] & reg2hw[146]);
	wire sck_n;
	wire rst_spi_n;
	prim_clock_inverter u_clk_spi(
		.clk_i(cio_sck_i),
		.clk_no(sck_n),
		.scanmode_i(scanmode_i)
	);
	assign clk_spi_in = (cpha ^ cpol ? sck_n : cio_sck_i);
	assign clk_spi_out = (cpha ^ cpol ? cio_sck_i : sck_n);
	assign rst_spi_n = (scanmode_i ? rst_ni : rst_ni & ~cio_csb_i);
	assign rst_txfifo_n = (scanmode_i ? rst_ni : rst_ni & ~rst_txfifo_reg);
	assign rst_rxfifo_n = (scanmode_i ? rst_ni : rst_ni & ~rst_rxfifo_reg);
	spi_fwmode u_fwmode(
		.clk_in_i(clk_spi_in),
		.rst_in_ni(rst_spi_n),
		.clk_out_i(clk_spi_out),
		.rst_out_ni(rst_spi_n),
		.cpha_i(cpha),
		.cfg_rxorder_i(rxorder),
		.cfg_txorder_i(txorder),
		.mode_i(spi_mode),
		.rx_wvalid_o(rxf_wvalid),
		.rx_wready_i(rxf_wready),
		.rx_data_o(rxf_wdata),
		.tx_rvalid_i(txf_rvalid),
		.tx_rready_o(txf_rready),
		.tx_data_i(txf_rdata),
		.rx_overflow_o(rxf_overflow),
		.tx_underflow_o(txf_underflow),
		.csb_i(cio_csb_i),
		.mosi(cio_mosi_i),
		.miso(cio_miso_o),
		.miso_oe(cio_miso_en_o)
	);
	prim_fifo_async #(
		.Width(FifoWidth),
		.Depth(FifoDepth)
	) u_rx_fifo(
		.clk_wr_i(clk_spi_in),
		.rst_wr_ni(rst_rxfifo_n),
		.clk_rd_i(clk_i),
		.rst_rd_ni(rst_rxfifo_n),
		.wvalid(rxf_wvalid),
		.wready(rxf_wready),
		.wdata(rxf_wdata),
		.rvalid(rxf_rvalid),
		.rready(rxf_rready),
		.rdata(rxf_rdata),
		.wdepth(),
		.rdepth(as_rxfifo_depth)
	);
	prim_fifo_async #(
		.Width(FifoWidth),
		.Depth(FifoDepth)
	) u_tx_fifo(
		.clk_wr_i(clk_i),
		.rst_wr_ni(rst_txfifo_n),
		.clk_rd_i(clk_spi_out),
		.rst_rd_ni(rst_txfifo_n),
		.wvalid(txf_wvalid),
		.wready(txf_wready),
		.wdata(txf_wdata),
		.rvalid(txf_rvalid),
		.rready(txf_rready),
		.rdata(txf_rdata),
		.wdepth(as_txfifo_depth),
		.rdepth()
	);
	spi_fwm_rxf_ctrl #(
		.FifoDw(FifoWidth),
		.SramAw(SramAw),
		.SramDw(SramDw)
	) u_rxf_ctrl(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.base_index_i(sram_rxf_bindex),
		.limit_index_i(sram_rxf_lindex),
		.timer_v(timer_v),
		.rptr(sram_rxf_rptr),
		.wptr(sram_rxf_wptr),
		.depth(sram_rxf_depth),
		.full(sram_rxf_full),
		.fifo_valid(rxf_rvalid),
		.fifo_ready(rxf_rready),
		.fifo_rdata(rxf_rdata),
		.sram_req(fwm_sram_req[FwModeRxFifo]),
		.sram_write(fwm_sram_write[FwModeRxFifo]),
		.sram_addr(fwm_sram_addr[((SramAw - 1) >= 0 ? 0 : SramAw - 1) + ((1 - FwModeRxFifo) * ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw))+:((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)]),
		.sram_wdata(fwm_sram_wdata[((SramDw - 1) >= 0 ? 0 : SramDw - 1) + ((1 - FwModeRxFifo) * ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw))+:((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)]),
		.sram_gnt(fwm_sram_gnt[FwModeRxFifo]),
		.sram_rvalid(fwm_sram_rvalid[FwModeRxFifo]),
		.sram_rdata(fwm_sram_rdata[((SramDw - 1) >= 0 ? 0 : SramDw - 1) + ((1 - FwModeRxFifo) * ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw))+:((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)]),
		.sram_error(fwm_sram_error[(1 - FwModeRxFifo) * 2+:2])
	);
	spi_fwm_txf_ctrl #(
		.FifoDw(FifoWidth),
		.SramAw(SramAw),
		.SramDw(SramDw)
	) u_txf_ctrl(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.base_index_i(sram_txf_bindex),
		.limit_index_i(sram_txf_lindex),
		.abort(abort),
		.rptr(sram_txf_rptr),
		.wptr(sram_txf_wptr),
		.depth(sram_txf_depth),
		.fifo_valid(txf_wvalid),
		.fifo_ready(txf_wready),
		.fifo_wdata(txf_wdata),
		.sram_req(fwm_sram_req[FwModeTxFifo]),
		.sram_write(fwm_sram_write[FwModeTxFifo]),
		.sram_addr(fwm_sram_addr[((SramAw - 1) >= 0 ? 0 : SramAw - 1) + ((1 - FwModeTxFifo) * ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw))+:((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)]),
		.sram_wdata(fwm_sram_wdata[((SramDw - 1) >= 0 ? 0 : SramDw - 1) + ((1 - FwModeTxFifo) * ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw))+:((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)]),
		.sram_gnt(fwm_sram_gnt[FwModeTxFifo]),
		.sram_rvalid(fwm_sram_rvalid[FwModeTxFifo]),
		.sram_rdata(fwm_sram_rdata[((SramDw - 1) >= 0 ? 0 : SramDw - 1) + ((1 - FwModeTxFifo) * ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw))+:((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)]),
		.sram_error(fwm_sram_error[(1 - FwModeTxFifo) * 2+:2])
	);
	prim_sram_arbiter #(
		.N(2),
		.SramDw(SramDw),
		.SramAw(SramAw)
	) u_fwmode_arb(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.req(fwm_sram_req),
		.req_addr(fwm_sram_addr),
		.req_write(fwm_sram_write),
		.req_wdata(fwm_sram_wdata),
		.gnt(fwm_sram_gnt),
		.rsp_rvalid(fwm_sram_rvalid),
		.rsp_rdata(fwm_sram_rdata),
		.rsp_error(fwm_sram_error),
		.sram_req(mem_b_req),
		.sram_addr(mem_b_addr),
		.sram_write(mem_b_write),
		.sram_wdata(mem_b_wdata),
		.sram_rvalid(mem_b_rvalid),
		.sram_rdata(mem_b_rdata),
		.sram_rerror(mem_b_rerror)
	);
	tlul_adapter_sram #(
		.SramAw(SramAw),
		.SramDw(SramDw),
		.Outstanding(1),
		.ByteAccess(0)
	) u_tlul2sram(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_i(tl_sram_h2d[((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1)+:((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17))]),
		.tl_o(tl_sram_d2h[((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1)+:((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2))]),
		.req_o(mem_a_req),
		.gnt_i(mem_a_req),
		.we_o(mem_a_write),
		.addr_o(mem_a_addr),
		.wdata_o(mem_a_wdata),
		.wmask_o(),
		.rdata_i(mem_a_rdata),
		.rvalid_i(mem_a_rvalid),
		.rerror_i(mem_a_rerror)
	);
	prim_ram_2p_adv #(
		.Depth(512),
		.Width(SramDw),
		.CfgW(8),
		.EnableECC(1),
		.EnableParity(0),
		.EnableInputPipeline(0),
		.EnableOutputPipeline(0),
		.MemT("SRAM")
	) u_memory_2p(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.a_req_i(mem_a_req),
		.a_write_i(mem_a_write),
		.a_addr_i(mem_a_addr),
		.a_wdata_i(mem_a_wdata),
		.a_rvalid_o(mem_a_rvalid),
		.a_rdata_o(mem_a_rdata),
		.a_rerror_o(mem_a_rerror),
		.b_req_i(mem_b_req),
		.b_write_i(mem_b_write),
		.b_addr_i(mem_b_addr),
		.b_wdata_i(mem_b_wdata),
		.b_rvalid_o(mem_b_rvalid),
		.b_rdata_o(mem_b_rdata),
		.b_rerror_o(mem_b_rerror),
		.cfg_i(1'sb0)
	);
	spi_device_reg_top u_reg(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_i(tl_i),
		.tl_o(tl_o),
		.tl_win_o(tl_sram_h2d),
		.tl_win_i(tl_sram_d2h),
		.reg2hw(reg2hw),
		.hw2reg(hw2reg),
		.devmode_i(1'b1)
	);
	function automatic [1:0] sv2v_cast_2;
		input reg [1:0] inp;
		sv2v_cast_2 = inp;
	endfunction
endmodule
