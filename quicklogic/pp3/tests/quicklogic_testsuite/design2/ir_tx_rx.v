//**********************************************************
//Title:    ir_tx_rx
//Design:   ir_tx_rx.v
//Author:  	MT
//Function: IrDA Remote TX/RX
//Company:  QuickLogic Corp.
//Date:     Aug xx, 2014
//
//**********************************************************

`timescale 1ns/10ps
//`include "../rtl/compile_param.vh"
//`define DEBUG
module ir_tx_rx
	#(parameter	MEM_ADR_WIDTH = 10)
(
`ifdef DEBUG
	output [2:0]				rState_o,
	output						rCRR_RISE_o,
	output						rRXD_o,
	output						wRX_CRR_CYC_CNT_SET1_o,
	output						wRX_CRR_CYC_CNT_EN_o,
`endif			
	input 						RST_i,					// Active-High Reset
	input						CLK_i,					// Clock (~12MHz?)
	input						MODE_i,					// 0: TX, 1: RX
	input						START_i,				// Tx/Rx Start flag
	output						START_CLR_o,			// Tx/Rx Start Clear flag
	input						STOP_i,					// Tx/Rx Stop flag
	output						STOP_CLR_o,				// Tx/Rx Stop Clear flag
	output						BUSY_o,					// TX/Rx Busy flag
	input						INT_EN_i,				// TX/Rx Interrupt Enable
	input						RX_GPIO_EN_i,			// Rx GPIO Enable
	input						RX_POL_INV_i,			// Rx Signal Polarity Inversion
	output 						TXD_o,					// Tx Data
	input [15:0]				TX_CRR_DUTY_LEN_i,		// Tx Carrier Duty Length
	input [15:0]				TX_CRR_CYC_LEN_i,		// Tx Carrier Cycle Length
	input [7:0]					TX_RPT_LEN_i,			// Tx IR Repeat Length
	input [MEM_ADR_WIDTH-1:0]	CODE_BGN_ADR_i,			// Tx/Rx Code Begin Address
	input [MEM_ADR_WIDTH-1:0]	TX_CODE_END_ADR_i,		// Tx Code End Address
	input [1:0]					RX_CRR_OFFSET_LEN_i,	// Rx Carrier Cycle Offset before seeking Average (value x 4)
	input [1:0]					RX_CRR_SAMPLE_LEN_i,	// Rx Carrier Cycle Sample Length to calculate Average (2**(value+3))
	input [3:0]					RX_OFF_TIMEOUT_LEN_i,	// Rx OFF Code Timeout (0x1000*value), 0 not allowed
	output [15:0]				RX_CRR_CYC_LEN_o,		// Rx Carrier Cycle Length
	input [MEM_ADR_WIDTH-1:0]	RX_CODE_LIMIT_ADR_i,	// Rx Code Limit Address
	output [MEM_ADR_WIDTH-1:0]	RX_CODE_END_ADR_o,		// Rx Code End Address
	input 						RXD_i,					// Rx Data
	output						RX_GPIO_o,				// Rx GPIO Output
	output						INT_o,					// Interrupt Flag
	input						INT_CLR_i,				// Interrupt Clear Flag
	output						MEM_WE_o,				// Memory Write Enable
	output						MEM_RCS_o,				// Memory Read Chip Select
	output						MEM_RE_o,				// Memory Read Enable
	output [MEM_ADR_WIDTH-1:0]	MEM_ADR_o,				// Memory Address
	output [7:0]				MEM_WD_o,				// Memory Write Data
	input [7:0]					MEM_RD_i,				// Memory Read Data
	output [7:0]					rx_debug_o			
);

wire						rTXD, wRXD;
wire						wTX_START, wTX_STOP;
wire						rTX_START_CLR, rTX_STOP_CLR;
wire						rTX_ON;
wire 						rTX_CLK_CNT_EN, wTX_CLK_CNT_SET1;
wire						wTX_CRR_CYC_CNT_EN, wTX_CRR_CYC_CNT_SET1;
wire						rTX_RPT_CNT_EN;
wire						rTX_INT;
wire						wTX_MEM_RE;
wire						rMEM_ADR_RST;
wire [MEM_ADR_WIDTH-1:0]	rIR_MEM_ADR;

wire						wRX_START, wRX_STOP;
wire						rRX_START_CLR, rRX_STOP_CLR;
wire						rRX_ON;
wire 						rRX_CLK_CNT_EN, wRX_CLK_CNT_SET1;
wire						wRX_CRR_CYC_CNT_EN, wRX_CRR_CYC_CNT_SET1;
wire						wRX_RISE_CNT_EN, wRX_RISE_CNT_SET1;
wire [15:0]					rCLK_CNT, rCRR_CYC_CNT;
wire [6:0]					rRPT_RISE_CNT;
wire						rRX_INT;
wire						wRX_MEM_WE;
wire [7:0]					wRX_MEM_WD;

//assign	TXD_o = IR_POL_INV_i ? (~rTXD) : rTXD;
assign	TXD_o = rTXD;	// No Polarity Inversion for Tx !!!!!
assign	wRXD = RX_POL_INV_i ? (~RXD_i) : RXD_i;
assign	RX_GPIO_o = RX_GPIO_EN_i ? rRX_ON : 1'b0;

assign	wTX_START = ~MODE_i & START_i;
assign	wTX_STOP = ~MODE_i & STOP_i;
assign	wRX_START = MODE_i & START_i;
assign	wRX_STOP = MODE_i & STOP_i;

assign	START_CLR_o = rTX_START_CLR | rRX_START_CLR;
assign	STOP_CLR_o = rTX_STOP_CLR | rRX_STOP_CLR;
assign	BUSY_o = rTX_ON | rRX_ON;
assign	INT_o = INT_EN_i & (rTX_INT | rRX_INT);
assign	MEM_WE_o = wRX_MEM_WE;
assign	MEM_RE_o = wTX_MEM_RE;
assign	MEM_ADR_o = rIR_MEM_ADR;
assign	MEM_WD_o = wRX_MEM_WD;
`ifdef DEBUG
	assign wRX_CRR_CYC_CNT_SET1_o = wRX_CRR_CYC_CNT_SET1;
	assign wRX_CRR_CYC_CNT_EN_o = wRX_CRR_CYC_CNT_EN;
`endif

ir_tx_ctrl  #(
	.MEM_ADR_WIDTH		(MEM_ADR_WIDTH)
)
tx_ctrl (
	.RST_i				(RST_i),
	.CLK_i				(CLK_i),
	.START_i			(wTX_START),
	.START_CLR_o		(rTX_START_CLR),
	.STOP_i				(wTX_STOP),
	.STOP_CLR_o			(rTX_STOP_CLR),
	.CRR_DUTY_LEN_i		(TX_CRR_DUTY_LEN_i),
	.CRR_CYC_LEN_i		(TX_CRR_CYC_LEN_i),
	.RPT_LEN_i			(TX_RPT_LEN_i),
	.CODE_END_ADR_i		(TX_CODE_END_ADR_i),
	.TX_ON_o			(rTX_ON),
	.TXD_o				(rTXD),
	.CLK_CNT_EN_o		(rTX_CLK_CNT_EN),
	.CLK_CNT_SET1_o		(wTX_CLK_CNT_SET1),
	.CLK_CNT_i			(rCLK_CNT),
	.CRR_CYC_CNT_EN_o	(wTX_CRR_CYC_CNT_EN),
	.CRR_CYC_CNT_SET1_o	(wTX_CRR_CYC_CNT_SET1),
	.CRR_CYC_CNT_i		(rCRR_CYC_CNT),
	.RPT_CNT_EN_o		(rTX_RPT_CNT_EN),
	.RPT_CNT_i			(rRPT_RISE_CNT),
	.MEM_RCS_o			(MEM_RCS_o),
	.MEM_RE_o			(wTX_MEM_RE),
	.MEM_ADR_i			(rIR_MEM_ADR),
	.MEM_RD_i			(MEM_RD_i),
	.MEM_ADR_RST_o		(rMEM_ADR_RST),
	.INT_o				(rTX_INT),
	.INT_CLR_i			(INT_CLR_i)
);

ir_rx_ctrl  #(
	.MEM_ADR_WIDTH			(MEM_ADR_WIDTH)
)
rx_ctrl (
`ifdef DEBUG
	.rState_o			(rState_o),
	.rCRR_RISE_o		(rCRR_RISE_o),
	.rRXD_o				(rRXD_o),
`endif		
	.RST_i				(RST_i),
	.CLK_i				(CLK_i),
	.START_i			(wRX_START),
	.START_CLR_o		(rRX_START_CLR),
	.STOP_i				(wRX_STOP),
	.STOP_CLR_o			(rRX_STOP_CLR),
	.RX_ON_o			(rRX_ON),
	.CRR_OFFSET_LEN_i	(RX_CRR_OFFSET_LEN_i),
	.CRR_SAMPLE_LEN_i	(RX_CRR_SAMPLE_LEN_i),
	.OFF_TIMEOUT_LEN_i	(RX_OFF_TIMEOUT_LEN_i),
	.RXD_i				(wRXD),
	.CLK_CNT_EN_o		(rRX_CLK_CNT_EN),
	.CLK_CNT_SET1_o		(wRX_CLK_CNT_SET1),
	.CLK_CNT_i			(rCLK_CNT),
	.CRR_CYC_LEN_o		(RX_CRR_CYC_LEN_o),
	.CRR_CYC_CNT_EN_o	(wRX_CRR_CYC_CNT_EN),
	.CRR_CYC_CNT_SET1_o	(wRX_CRR_CYC_CNT_SET1),
	.CRR_CYC_CNT_i		(rCRR_CYC_CNT),
	.RISE_CNT_SET1_o	(wRX_RISE_CNT_SET1),
	.RISE_CNT_EN_o		(wRX_RISE_CNT_EN),
	.RISE_CNT_i			(rRPT_RISE_CNT),
	.CODE_LIMIT_ADR_i	(RX_CODE_LIMIT_ADR_i),
	.CODE_END_ADR_o		(RX_CODE_END_ADR_o),
	.MEM_WE_o			(wRX_MEM_WE),
	.MEM_ADR_i			(rIR_MEM_ADR),
	.MEM_WD_o			(wRX_MEM_WD),
	.INT_o				(rRX_INT),
	.INT_CLR_i			(INT_CLR_i),
	.rx_debug_o         (rx_debug_o)
);

ir_counters  #(
	.MEM_ADR_WIDTH			(MEM_ADR_WIDTH)
)
counters (
	.RST_i					(RST_i),
	.CLK_i					(CLK_i),
	.TX_START_i				(wTX_START & (~rTX_START_CLR)),
	.RX_START_i				(wRX_START & (~rRX_START_CLR)),
	.TX_CLK_CNT_EN_i		(rTX_CLK_CNT_EN),
	.RX_CLK_CNT_EN_i		(rRX_CLK_CNT_EN),
	.TX_CLK_CNT_SET1_i		(wTX_CLK_CNT_SET1),
	.RX_CLK_CNT_SET1_i		(wRX_CLK_CNT_SET1),
	.CLK_CNT_o				(rCLK_CNT),
	.TX_CRR_CYC_CNT_EN_i	(wTX_CRR_CYC_CNT_EN),
	.RX_CRR_CYC_CNT_EN_i	(wRX_CRR_CYC_CNT_EN),
	.TX_CRR_CYC_CNT_SET1_i	(wTX_CRR_CYC_CNT_SET1),
	.RX_CRR_CYC_CNT_SET1_i	(wRX_CRR_CYC_CNT_SET1),
	.CRR_CYC_CNT_o			(rCRR_CYC_CNT),
	.TX_RPT_CNT_EN_i		(rTX_RPT_CNT_EN),
	.RX_RISE_CNT_SET1_i		(wRX_RISE_CNT_SET1),
	.RX_RISE_CNT_EN_i		(wRX_RISE_CNT_EN),
	.RPT_RISE_CNT_o			(rRPT_RISE_CNT),
	.TX_MEM_RE_i			(wTX_MEM_RE),
	.RX_MEM_WE_i			(wRX_MEM_WE),
	.MEM_ADR_RST_i			(rMEM_ADR_RST),
	.CODE_BGN_ADR_i			(CODE_BGN_ADR_i),
	.MEM_ADR_o				(rIR_MEM_ADR)
);
/*
ir_mem_ctrl mem_ctrl (
//	.RST_i			(RST_i),
	.CLK_i			(CLK_i),
	.HOST_WE_i		(HOST_MEM_WE_i),
	.HOST_RE_i		(HOST_MEM_RE_i),
	.HOST_ADR_i		(HOST_MEM_ADR_i),
	.HOST_WD_i		(HOST_MEM_WD_i),
	.RD_o			(mMEM_RD),
	.TX_ON_i		(rTX_ON),
	.TX_RE_i		(wTX_MEM_RE),
	.RX_ON_i		(rRX_ON),
	.RX_WE_i		(wRX_MEM_WE),
	.RX_WD_i		(wRX_MEM_WD),
	.IR_ADR_i		(rIR_MEM_ADR)
);
*/

endmodule
