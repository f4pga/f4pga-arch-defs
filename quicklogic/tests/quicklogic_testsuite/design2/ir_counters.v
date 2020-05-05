//**********************************************************
//Title:    ir_counters
//Design:   ir_counters.v
//Author:  	MT
//Function: Counters tobe shared with Tx & Rx controller
//Company:  QuickLogic Corp.
//Date:     Aug xx, 2014
//
//**********************************************************

`timescale 1ns/10ps
//`include "../rtl/compile_param.vh"

module ir_counters
	#(parameter	MEM_ADR_WIDTH = 10)
(
	input			 			RST_i,					// active-high reset
	input						CLK_i,					// clock (~12MHz?)
	input						TX_START_i,				// TX start flag
	input						RX_START_i,				// RX start flag
	input 						TX_CLK_CNT_EN_i,		// TX Clock Count Enable
	input 						RX_CLK_CNT_EN_i,		// RX Clock Count Enable
	input 						TX_CLK_CNT_SET1_i,		// TX Clock Count Set to 1
	input 						RX_CLK_CNT_SET1_i,		// RX Clock Count Set to 1
	output [15:0]				CLK_CNT_o,				// Clock Count
	input 						TX_CRR_CYC_CNT_EN_i,	// TX Carrier Cycle Count Enable
	input 						RX_CRR_CYC_CNT_EN_i,	// RX Carrier Cycle Count Enable
	input 						TX_CRR_CYC_CNT_SET1_i,	// TX Carrier Cycle Count Set to 1
	input 						RX_CRR_CYC_CNT_SET1_i,	// RX Carrier Cycle Count Set to 1
	output [15:0]				CRR_CYC_CNT_o,			// Carrier Cycle Count
	input						TX_RPT_CNT_EN_i,		// TX Code Repeat Count Enable
	input						RX_RISE_CNT_SET1_i,		// RX Carrier Rise Count Set to 1
	input						RX_RISE_CNT_EN_i,		// RX Carrier Rise Count Enable
	output [6:0]				RPT_RISE_CNT_o,			// TX Code Repeat Count / Rx Carrier Rise Count
	input						TX_MEM_RE_i,			// TX Memory Read Enable
	input						RX_MEM_WE_i,			// RX Memory Write Enable
	input						MEM_ADR_RST_i,			// Memory Address Reset
	input [MEM_ADR_WIDTH-1:0]	CODE_BGN_ADR_i,			// Code Begin Address
	output [MEM_ADR_WIDTH-1:0]	MEM_ADR_o				// Memory Address
);


reg [15:0]				rCLK_CNT, rCRR_CYC_CNT;
reg [6:0]				rRPT_RISE_CNT;
reg [MEM_ADR_WIDTH-1:0]	rMEM_ADR;

assign 	CLK_CNT_o = rCLK_CNT;
assign 	CRR_CYC_CNT_o = rCRR_CYC_CNT;
assign	RPT_RISE_CNT_o = rRPT_RISE_CNT;
assign	MEM_ADR_o = rMEM_ADR;

wire	wCNT_RST = RST_i | TX_START_i | RX_START_i;

///// Carrer Cycle Counter ///////////////////////////////////

always @(posedge CLK_i or posedge wCNT_RST) begin
	if (wCNT_RST) begin
		rCLK_CNT <= 0;
	end
	else if (TX_CLK_CNT_SET1_i | RX_CLK_CNT_SET1_i) begin
		rCLK_CNT <= 16'd1;
	end
	else if (TX_CLK_CNT_EN_i | RX_CLK_CNT_EN_i) begin
		rCLK_CNT <= rCLK_CNT + 1;
	end
//	else begin
//		rCLK_CNT <= rCLK_CNT;
//	end
end


///// IR ON/OFF Counter /////////////////////////////////////

always @(posedge CLK_i or posedge wCNT_RST) begin
	if (wCNT_RST) begin
		rCRR_CYC_CNT <= 0;
	end
	else if (TX_CRR_CYC_CNT_SET1_i | RX_CRR_CYC_CNT_SET1_i) begin
		rCRR_CYC_CNT <= 16'd1;
	end
	else if (TX_CRR_CYC_CNT_EN_i | RX_CRR_CYC_CNT_EN_i) begin
		rCRR_CYC_CNT <= rCRR_CYC_CNT + 1;
	end
//	else begin
//		rCRR_CYC_CNT <= rCRR_CYC_CNT;
//	end
end


///// Tx Code Repeat / Rx Carrier Rise Counter //////////////

always @(posedge CLK_i or posedge wCNT_RST) begin
	if (wCNT_RST) begin
		rRPT_RISE_CNT <= 0;
	end
	else if (RX_RISE_CNT_SET1_i) begin
		rRPT_RISE_CNT <= 7'd1;
	end
	else if (TX_RPT_CNT_EN_i | RX_RISE_CNT_EN_i) begin
		rRPT_RISE_CNT <= rRPT_RISE_CNT + 1;
	end
//	else begin
//		rRPT_RISE_CNT <= rRPT_RISE_CNT;
//	end
end


///// Memory Address Counter ////////////////////////////////

always @(posedge CLK_i or posedge wCNT_RST) begin
	if (wCNT_RST) begin
		rMEM_ADR <= CODE_BGN_ADR_i;
	end
	else if (MEM_ADR_RST_i) begin
		rMEM_ADR <= CODE_BGN_ADR_i;
	end
	else if (TX_MEM_RE_i | RX_MEM_WE_i) begin
		rMEM_ADR <= rMEM_ADR + 1;
	end
//	else begin
//		rMEM_ADR <= rMEM_ADR;
//	end
end

endmodule
