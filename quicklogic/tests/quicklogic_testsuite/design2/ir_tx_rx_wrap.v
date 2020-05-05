//**********************************************************
//Title:    ir_tx_rx_wrap
//Design:   ir_tx_rx_wrap.v
//Author:  	MT
//Function: IrDA Remote Tx/Rx wrapper
//Company:  QuickLogic Corp.
//Date:     Aug xx, 2014
//
//**********************************************************

`timescale 1ns/10ps
//`include "../rtl/compile_param.vh"
//`define DEBUG
`define WISHBONE
module ir_tx_rx_wrap 
#(
	parameter	MEM_ADR_WIDTH = 11,	 
	parameter	MEM_DAT_WIDTH = 8	
 )	
	(
`ifdef DEBUG
	output [2:0]	rState_o,
	output			rCRR_RISE_o,
	output			rRXD_o,
	output			wMEM_WE_o,
	output			wRX_CRR_CYC_CNT_SET1_o,
	output			wRX_CRR_CYC_CNT_EN_o,	
`endif		
	input 			RST_i,			// active-high reset
	input			CLK_i,			// clock (~12MHz?)

	output 			TXD_o,			// Tx Data
	input 			RXD_i,			// Rx Data
	output			RX_GPIO_o,		// Rx GPIO Output
`ifdef WISHBONE

	input                        WBs_CLK_i           , // Fabric Clock               from Fabric
	input                        WBs_RST_i           , // Fabric Reset               to   Fabric
	input   [7:0]  				 WBs_ADR_i           , // Address Bus                to   Fabric
	
	input                        WBs_CYC_i       , // Cycle Chip Select          to   Fabric
	
	input             [3:0]      WBs_BYTE_STB_i      , // Byte Enable Strobes        to   Fabric
	input                   	 WBs_WE_i            , // Write Enable               to   Fabric
	input                   	 WBs_STB_i           , // Strobe Signal              to   Fabric
	input   [MEM_DAT_WIDTH-1:0]  WBs_DAT_i           , // Write Data Bus             to   Fabric
	output  [MEM_DAT_WIDTH-1:0]  WBs_DAT_o ,
	output                   	 WBs_ACK_o           , // Transfer Cycle Acknowledge from Fabric
		

	
`else
	input			SPI_SCLK_i,		// SPI clock (~1MHz?)	
	input [6:0]		REG_ADR_i,		// Register Address by Host
	input [7:0]		REG_WD_i,		// Register Write Data by Host
	input			REG_WE_i,		// Register Write Enable by Host
	output [7:0]	REG_RD_o,		// Register Read Data by Host
`endif	
//	input			REG_RD_ACK_i,	// Register Read Data Acknowledge by Host
	output			PSB_CLK_EN_o,	// PSB Clock Enable (active high)
	output			INT_o,			// Interrupt Flag (active high)
	output  [7:0]               rx_debug_o
);

//parameter	MEM_ADR_WIDTH = 11;	// 2048 x 8 bits
//parameter	MEM_DAT_WIDTH = 8;	// 2048 x 8 bits

reg 						rMEM_SEL;

wire						rSW_RST, wRST;
wire						rMODE, rSTART, rSTOP, rBUSY, rINT_EN, rRX_GPIO_EN, rRX_POL_INV;
wire [15:0]					rTX_DUTY_RX_LIMIT, rTX_CRR_CYC_LEN, rRX_CRR_CYC_LEN;
wire [7:0]					rTX_RPT_LEN_RX_CTRL;

wire [MEM_ADR_WIDTH-1:0]	rCODE_BGN_ADR, rTX_CODE_END_ADR, rRX_CODE_END_ADR;
wire						rSTART_CLR, rSTOP_CLR, rINT_CLR;

wire [15:0]					rTX_CRR_DUTY_LEN = rTX_DUTY_RX_LIMIT;
wire [MEM_ADR_WIDTH-1:0]	rRX_CODE_LIMIT_ADR = rTX_DUTY_RX_LIMIT[MEM_ADR_WIDTH-1:0];
wire [7:0]					rTX_RPT_LEN = rTX_RPT_LEN_RX_CTRL;
wire [1:0]					rRX_CRR_OFFSET_LEN = rTX_RPT_LEN_RX_CTRL[1:0];
wire [1:0]					rRX_CRR_SAMPLE_LEN = rTX_RPT_LEN_RX_CTRL[3:2];
wire [3:0]					rRX_OFF_TIMEOUT_LEN = rTX_RPT_LEN_RX_CTRL[7:4];

wire						rHOST_MEM_WE, rHOST_MEM_RE, wIR_MEM_WE, wIR_MEM_RE, wIR_MEM_RCS;
wire [MEM_ADR_WIDTH-1:0]	rHOST_MEM_ADR, rIR_MEM_ADR;
wire [7:0]					rHOST_MEM_WD, wIR_MEM_WD, wMEM_RD, mMEM0_RD, mMEM1_RD;

wire						wTX_ON = ~rMODE & rBUSY;
wire						wRX_ON = rMODE & rBUSY;

wire						wMEM_WE = wRX_ON ? wIR_MEM_WE : rHOST_MEM_WE;
wire						wMEM_RE = wTX_ON ? wIR_MEM_RE : rHOST_MEM_RE;
wire						wMEM_RCS = wTX_ON ? wIR_MEM_RCS : rHOST_MEM_RE;
wire [MEM_ADR_WIDTH-1:0]	wMEM_WADR = wRX_ON ? rIR_MEM_ADR : rHOST_MEM_ADR;
wire [MEM_ADR_WIDTH-1:0]	wMEM_RADR = wTX_ON ? rIR_MEM_ADR : rHOST_MEM_ADR;
wire [7:0]					wMEM_WD = wRX_ON ? wIR_MEM_WD : rHOST_MEM_WD;

assign	wRST = RST_i | rSW_RST;

`ifdef DEBUG
	assign wMEM_WE_o = wMEM_WE;
`endif

///// Memory Selection between mem0 & mem1 ///////////////

assign	wMEM_RD = rMEM_SEL ? mMEM1_RD : mMEM0_RD;

always @(posedge CLK_i or posedge wRST) begin
	if (wRST) begin
		rMEM_SEL <= 0;
	end
	else if (wMEM_RE) begin
		rMEM_SEL <= wMEM_RADR[MEM_ADR_WIDTH-1];
	end
//	else begin
//		rMEM_SEL <= wMEM_SEL;
//	end
end

///// Add FF to avoid simulation issue on Memory Read ////

reg [7:0]	rMEM_RD;

always @(posedge CLK_i or posedge wRST) begin
	if (wRST) begin
		rMEM_RD <= 0;
	end
	else begin
		rMEM_RD <= wMEM_RD;
	end
end

//////////////////////////////////////////////////////////


ir_reg_if #(
	.MEM_ADR_WIDTH			(MEM_ADR_WIDTH)
)
reg_if (
	.RST_i					(RST_i),
	.CLK_i					(CLK_i),
	
`ifdef  WISHBONE

	.wb_clk_i                           ( WBs_CLK_i                       ), 
    .wb_rst_i                           ( 1'b0                            ), 
    .arst_i                             ( WBs_RST_i                       ), 
    .wb_adr_i                           ( WBs_ADR_i                     ), 
    .wb_dat_i                           ( WBs_DAT_i                   ), 
    .wb_dat_o                           ( WBs_DAT_o                   ),
    .wb_we_i                            ( WBs_WE_i                      ), 
    .wb_stb_i                           ( WBs_STB_i                     ), 
    .wb_cyc_i                           ( WBs_CYC_i                    ), 
    .wb_ack_o                           ( WBs_ACK_o                     ), 

`else	
	.REG_CLK_i				(SPI_SCLK_i),
	.REG_ADR_i				(REG_ADR_i),
	.REG_WD_i				(REG_WD_i),
	.REG_WE_i				(REG_WE_i),
	.REG_RD_o				(REG_RD_o),
`endif	
//	.REG_RD_ACK_i			(REG_RD_ACK_i),

	.SW_RST_o				(rSW_RST),
	.CLK_EN_o				(PSB_CLK_EN_o),
	.MODE_o					(rMODE),
	.START_o				(rSTART),
	.START_CLR_i			(rSTART_CLR),
	.STOP_o					(rSTOP),
	.STOP_CLR_i				(rSTOP_CLR),
	.BUSY_i					(rBUSY),
	.INT_EN_o				(rINT_EN),
	.RX_GPIO_EN_o			(rRX_GPIO_EN),
	.RX_POL_INV_o			(rRX_POL_INV),
	.TX_CRR_CYC_LEN_o		(rTX_CRR_CYC_LEN),
	.TX_DUTY_RX_LIMIT_o		(rTX_DUTY_RX_LIMIT),
	.TX_RPT_LEN_RX_CTRL_o	(rTX_RPT_LEN_RX_CTRL),
	.CODE_BGN_ADR_o			(rCODE_BGN_ADR),
	.TX_CODE_END_ADR_o		(rTX_CODE_END_ADR),
	.RX_CRR_CYC_LEN_i		(rRX_CRR_CYC_LEN),
	.RX_CODE_END_ADR_i		(rRX_CODE_END_ADR),

	.INT_i					(INT_o),
	.INT_CLR_o				(rINT_CLR),

	.MEM_WE_o				(rHOST_MEM_WE),
	.MEM_RE_o				(rHOST_MEM_RE),
	.MEM_ADR_o				(rHOST_MEM_ADR),
	.MEM_WD_o				(rHOST_MEM_WD),
	.MEM_RD_i				(rMEM_RD)
);

ir_tx_rx  #(
	.MEM_ADR_WIDTH			(MEM_ADR_WIDTH)
)
tx_rx (
`ifdef DEBUG
	.rState_o				(rState_o),
	.rCRR_RISE_o			(rCRR_RISE_o),
	.rRXD_o					(rRXD_o),
	.wRX_CRR_CYC_CNT_SET1_o	(wRX_CRR_CYC_CNT_SET1_o),
	.wRX_CRR_CYC_CNT_EN_o	(wRX_CRR_CYC_CNT_EN_o),
`endif		
	.RST_i					(wRST),
	.CLK_i					(CLK_i),
	.MODE_i					(rMODE),
	.START_i				(rSTART),
	.START_CLR_o			(rSTART_CLR),
	.STOP_i					(rSTOP),
	.STOP_CLR_o				(rSTOP_CLR),
	.BUSY_o					(rBUSY),
	.INT_EN_i				(rINT_EN),
	.RX_GPIO_EN_i			(rRX_GPIO_EN),
	.RX_POL_INV_i			(rRX_POL_INV),
	.TXD_o					(TXD_o),
	.TX_CRR_DUTY_LEN_i		(rTX_CRR_DUTY_LEN),
	.TX_CRR_CYC_LEN_i		(rTX_CRR_CYC_LEN),
	.TX_RPT_LEN_i			(rTX_RPT_LEN),
	.CODE_BGN_ADR_i			(rCODE_BGN_ADR),
	.TX_CODE_END_ADR_i		(rTX_CODE_END_ADR),
	.RX_CRR_OFFSET_LEN_i	(rRX_CRR_OFFSET_LEN),
	.RX_CRR_SAMPLE_LEN_i	(rRX_CRR_SAMPLE_LEN),
	.RX_OFF_TIMEOUT_LEN_i	(rRX_OFF_TIMEOUT_LEN),
	.RX_CRR_CYC_LEN_o		(rRX_CRR_CYC_LEN),
	.RX_CODE_LIMIT_ADR_i	(rRX_CODE_LIMIT_ADR),
	.RX_CODE_END_ADR_o		(rRX_CODE_END_ADR),
	.RXD_i					(RXD_i),
	.RX_GPIO_o				(RX_GPIO_o),
	.INT_o					(INT_o),
	.INT_CLR_i				(rINT_CLR),
	.MEM_WE_o				(wIR_MEM_WE),
	.MEM_RCS_o				(wIR_MEM_RCS),
	.MEM_RE_o				(wIR_MEM_RE),
	.MEM_ADR_o				(rIR_MEM_ADR),
	.MEM_WD_o				(wIR_MEM_WD),
	.MEM_RD_i				(wMEM_RD),
	.rx_debug_o            (rx_debug_o)
);


r1024x8_1024x8 ir_mem0 (	// lower address
	.WA			(wMEM_WADR[9:0]),
	.RA			(wMEM_RADR[9:0]),
	.WD			(wMEM_WD),
	.WD_SEL		(~wMEM_WADR[10] & wMEM_WE),
	.RD_SEL		(wMEM_RCS),
	.WClk		(CLK_i),
	.RClk		(CLK_i),
	.WClk_En	(wMEM_WE),
	.RClk_En	(wMEM_RE),
	.WEN		(~wMEM_WADR[10] & wMEM_WE),
	.RD			(mMEM0_RD),
    .LS                 ( 1'b0                    ),
	.DS                 ( 1'b0                    ),
	.SD                 ( 1'b0                    ),
	.LS_RB1             ( 1'b0                    ),
	.DS_RB1             ( 1'b0                    ),
	.SD_RB1             ( 1'b0                    )	
	
);

r1024x8_1024x8 ir_mem1 (	// higher address
	.WA			(wMEM_WADR[9:0]),
	.RA			(wMEM_RADR[9:0]),
	.WD			(wMEM_WD),
	.WD_SEL		(wMEM_WADR[10] & wMEM_WE),
	.RD_SEL		(wMEM_RCS),
	.WClk		(CLK_i),
	.RClk		(CLK_i),
	.WClk_En	(wMEM_WE),
	.RClk_En	(wMEM_RE),
	.WEN		(wMEM_WADR[10] & wMEM_WE),
	.RD			(mMEM1_RD),
    .LS                 ( 1'b0                    ),
	.DS                 ( 1'b0                    ),
	.SD                 ( 1'b0                    ),
	.LS_RB1             ( 1'b0                    ),
	.DS_RB1             ( 1'b0                    ),
	.SD_RB1             ( 1'b0                    )		
);


endmodule
