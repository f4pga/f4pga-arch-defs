module spi_fwmode (
	clk_in_i,
	rst_in_ni,
	clk_out_i,
	rst_out_ni,
	cpha_i,
	cfg_rxorder_i,
	cfg_txorder_i,
	mode_i,
	rx_wvalid_o,
	rx_wready_i,
	rx_data_o,
	tx_rvalid_i,
	tx_rready_o,
	tx_data_i,
	rx_overflow_o,
	tx_underflow_o,
	csb_i,
	mosi,
	miso,
	miso_oe
);
	localparam [0:0] TxIdle = 0;
	localparam [0:0] TxActive = 1;
	input clk_in_i;
	input rst_in_ni;
	input clk_out_i;
	input rst_out_ni;
	input cpha_i;
	input cfg_rxorder_i;
	input cfg_txorder_i;
	input wire [1:0] mode_i;
	output wire rx_wvalid_o;
	input rx_wready_i;
	output wire [7:0] rx_data_o;
	input tx_rvalid_i;
	output wire tx_rready_o;
	input wire [7:0] tx_data_i;
	output wire rx_overflow_o;
	output wire tx_underflow_o;
	input csb_i;
	input mosi;
	output wire miso;
	output wire miso_oe;
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
	localparam [31:0] BITS = 8;
	localparam [31:0] BITWIDTH = 3;
	reg [BITWIDTH - 1:0] rx_bitcount;
	reg [0:0] tx_state;
	reg [7:0] rx_data_d;
	reg [7:0] rx_data_q;
	always @(*)
		if (cfg_rxorder_i)
			rx_data_d = {mosi, rx_data_q[BITS - 1:1]};
		else
			rx_data_d = {rx_data_q[BITS - 2:0], mosi};
	always @(posedge clk_in_i) rx_data_q <= rx_data_d;
	assign rx_data_o = rx_data_d;
	always @(posedge clk_in_i or negedge rst_in_ni)
		if (!rst_in_ni)
			rx_bitcount <= sv2v_cast_3(BITS - 1);
		else if (rx_bitcount == 1'sb0)
			rx_bitcount <= sv2v_cast_3(BITS - 1);
		else
			rx_bitcount <= rx_bitcount - 1;
	assign rx_wvalid_o = rx_bitcount == 1'sb0;
	reg [BITWIDTH - 1:0] tx_bitcount;
	wire first_bit;
	wire last_bit;
	reg [7:0] miso_shift;
	assign first_bit = (tx_bitcount == sv2v_cast_3(BITS - 1) ? 1'b1 : 1'b0);
	assign last_bit = (tx_bitcount == 1'sb0 ? 1'b1 : 1'b0);
	assign tx_rready_o = tx_bitcount == sv2v_cast_1E8D3(1);
	always @(posedge clk_out_i or negedge rst_out_ni)
		if (!rst_out_ni)
			tx_bitcount <= sv2v_cast_3(BITS - 1);
		else if (last_bit)
			tx_bitcount <= sv2v_cast_3(BITS - 1);
		else if ((tx_state != TxIdle) || (cpha_i == 1'b0))
			tx_bitcount <= tx_bitcount - 1'b1;
	always @(posedge clk_out_i or negedge rst_out_ni)
		if (!rst_out_ni)
			tx_state <= TxIdle;
		else
			tx_state <= TxActive;
	assign miso = (cfg_txorder_i ? (~first_bit ? miso_shift[0] : tx_data_i[0]) : (~first_bit ? miso_shift[7] : tx_data_i[7]));
	assign miso_oe = ~csb_i;
	always @(posedge clk_out_i)
		if (cfg_txorder_i) begin
			if (first_bit)
				miso_shift <= {1'b0, tx_data_i[7:1]};
			else
				miso_shift <= {1'b0, miso_shift[7:1]};
		end
		else if (first_bit)
			miso_shift <= {tx_data_i[6:0], 1'b0};
		else
			miso_shift <= {miso_shift[6:0], 1'b0};
	assign rx_overflow_o = rx_wvalid_o & ~rx_wready_i;
	assign tx_underflow_o = tx_rready_o & ~tx_rvalid_i;
	function automatic [$clog2(8) - 1:0] sv2v_cast_1E8D3;
		input reg [$clog2(8) - 1:0] inp;
		sv2v_cast_1E8D3 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_3;
		input reg [2:0] inp;
		sv2v_cast_3 = inp;
	endfunction
endmodule
