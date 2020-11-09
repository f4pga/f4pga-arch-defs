//**********************************************************
//Title:    ir_rx_ctrl
//Design:   ir_rx_ctrl.v
//Author:  	MT
//Function: IrDA Remote RX controller
//Company:  QuickLogic Corp.
//Date:     Aug xx, 2014
//
//**********************************************************

`timescale 1ns/10ps
//`include "../rtl/compile_param.vh"

module ir_tx_ctrl
	#(parameter	MEM_ADR_WIDTH = 10)
(	
	input 						RST_i,				// active-high reset
	input						CLK_i,				// clock (~12MHz?)
	input						START_i,			// Tx Tansaction start flag
	output						START_CLR_o,		// Tx Tansaction start clear flag
	input						STOP_i,				// Tx Transaction stop flag
	output						STOP_CLR_o,			// Tx Tansaction stop clear flag
	input [15:0]				CRR_DUTY_LEN_i,		// Carrier Duty Length
	input [15:0]				CRR_CYC_LEN_i,		// Carrier Cycle Length
	input [7:0]					RPT_LEN_i,			// TXD Code Repeat Length, Bit[7] denotes infinite repeat
	input [MEM_ADR_WIDTH-1:0]	CODE_END_ADR_i,		// TXD Code End Address
	output						TX_ON_o,			// Tx Treansaction ON flag
	output 						TXD_o,				// Tx Data
	output 						CLK_CNT_EN_o,		// Clock Count Enable
	output 						CLK_CNT_SET1_o,		// Clock Count Set to 1
	input [15:0]				CLK_CNT_i,			// Clock Count
	output 						CRR_CYC_CNT_EN_o,	// TX Carrier Cycle Count Enable
	output 						CRR_CYC_CNT_SET1_o,	// TX Carrier Cycle Count Set to 1
	input [15:0]				CRR_CYC_CNT_i,		// TX Carrier Cycle Count
//	output						RPT_CNT_CLR_o,		// TX Code Repeat Count Clear	
	output						RPT_CNT_EN_o,		// TX Code Repeat Count Enable	
	input [6:0]					RPT_CNT_i,			// TX Code Repeat Count	
	output						MEM_RCS_o,			// Memory Read Chip Select
	output						MEM_RE_o,			// Memory Read Enable
	input [MEM_ADR_WIDTH-1:0]	MEM_ADR_i,			// Memory Address
	input [7:0]					MEM_RD_i,			// Memory Read Data
	output						MEM_ADR_RST_o,		// Memory address Reset
	output						INT_o,				// Interrupt Flag
	input						INT_CLR_i			// Interrupt Clear Flag
);

parameter	S_WAIT			= 2'd0,
			S_IR_ON			= 2'd1,
			S_IR_OFF 		= 2'd2;


reg			rTX_ON;
reg			rTXD_CRR_BGN, rTXD_CRR_BGN_p;
//reg [6:0]	rRPT_CNT;
reg			rCLK_CNT_EN;
reg			rMEM_RE_d;
reg [7:0]	rMEM_RD_LSB;
reg			rTXD;
reg			rLAST_CODE;
reg			rINT;
reg			rINT_CLR_p, rINT_CLR;

reg [1:0]	rState, wN_State;
reg			rCRR_CYC_CNT_SET1, wN_CRR_CYC_CNT_SET1, rRPT_CNT_INC, wN_RPT_CNT_INC;
reg			rMEM_RE, wN_MEM_RE, rTX_END, wN_TX_END;

wire		wMEM_RE = rMEM_RE | rMEM_RE_d;
wire		INF_RPT_i = RPT_LEN_i[7];
wire		wCRR_DUTY_CNT_FULL = (CLK_CNT_i == CRR_DUTY_LEN_i);
wire		wCLK_CNT_FULL = (CLK_CNT_i == CRR_CYC_LEN_i);
wire		wCRR_CYC_CNT_FULL = (CRR_CYC_CNT_i == {MEM_RD_i, rMEM_RD_LSB});
//wire		wRPT_DONE = ~INF_RPT_i & (rRPT_CNT == RPT_LEN_i[6:0]);
wire		wRPT_DONE = ~INF_RPT_i & (RPT_CNT_i == RPT_LEN_i[6:0]);

assign	START_CLR_o = rTX_ON;
assign	STOP_CLR_o = ~rTX_ON;
assign	TX_ON_o = rTX_ON;
assign 	CLK_CNT_EN_o = rCLK_CNT_EN;
assign 	CLK_CNT_SET1_o = wCLK_CNT_FULL;
assign 	CRR_CYC_CNT_EN_o = ((rState == S_IR_ON) | (rState == S_IR_OFF)) & wCLK_CNT_FULL;
assign 	CRR_CYC_CNT_SET1_o = rCRR_CYC_CNT_SET1;
assign	RPT_CNT_EN_o = rRPT_CNT_INC;
assign	MEM_RCS_o = rTX_ON;
assign	MEM_RE_o = wMEM_RE & rTX_ON;
assign	MEM_ADR_RST_o = rLAST_CODE & wCLK_CNT_FULL & wCRR_CYC_CNT_FULL;
assign	TXD_o = rTXD;
assign	INT_o = rINT;


///// Tx Transaction Indicator /////////////////

always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rTX_ON <= 0;
	end
	else if (START_i) begin
		rTX_ON <= 1;
	end
	else if (rTX_END) begin
		rTX_ON <= 0;
	end
end

///// Memory Access ////////////////////////////

always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rMEM_RE_d <= 0;
	end
	else begin
		rMEM_RE_d <= rMEM_RE;
	end
end

always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rMEM_RD_LSB <= 0;
	end
	else if (rMEM_RE_d) begin
		rMEM_RD_LSB <= MEM_RD_i;
	end
//	else begin
//		rMEM_RD_LSB <= rMEM_RD_LSB;
//	end
end


always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rLAST_CODE <= 0;
	end
	else if (rState != S_IR_OFF) begin
		rLAST_CODE <= 0;
	end
	else if (MEM_ADR_i == CODE_END_ADR_i) begin
		rLAST_CODE <= 1;
	end
//	else begin
//		rLAST_CODE <= rLAST_CODE;
//	end
end



///// Repeat Control /////////////////////////////////////////////////////
/*
always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rRPT_CNT <= 0;
	end
	else if (START_i) begin
		rRPT_CNT <= 0;
	end
	else if (rRPT_CNT_INC) begin
		rRPT_CNT <= rRPT_CNT + 1;
	end
//	else begin
//		rRPT_CNT <= rRPT_CNT;
//	end
end
*/

///// TXD Control ////////////////////////////////////////////////////////

always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rCLK_CNT_EN <= 0;
	end
	else if (rTX_END) begin
		rCLK_CNT_EN <= 0;
	end
	else if (rTX_ON & (rState == S_IR_ON)) begin
		rCLK_CNT_EN <= 1;
	end
//	else begin
//		rCLK_CNT_EN <= rCLK_CNT_EN;
//	end
end

always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rTXD_CRR_BGN_p <= 0;
		rTXD_CRR_BGN <= 0;
	end
	else begin
		rTXD_CRR_BGN_p <= START_i & (rState == S_WAIT) & rTX_ON;
		rTXD_CRR_BGN <= rTXD_CRR_BGN_p;
	end
end

always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rTXD <= 0;
	end
	else if (wCRR_DUTY_CNT_FULL) begin
		rTXD <= 0;
	end
	else if (rTXD_CRR_BGN | ((rState == S_IR_ON) & wCLK_CNT_FULL & (~wCRR_CYC_CNT_FULL)) |
			((rState == S_IR_OFF) & wCLK_CNT_FULL & wCRR_CYC_CNT_FULL & ((~rLAST_CODE) | (~wRPT_DONE)))) begin
		rTXD <= 1;
	end
//	else begin
//		rTXD <= rTXD;
//	end
end


///// Interrupt Handling /////////////////////////////////////////////////

always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rINT_CLR_p <= 0;
		rINT_CLR <= 0;
	end
	else begin
		rINT_CLR_p <= INT_CLR_i;
		rINT_CLR <= rINT_CLR_p;
	end
end

always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rINT <= 0;
	end
	else if (rTX_END) begin
		rINT <= 1;
	end
	else if (rINT_CLR) begin
		rINT <= 0;
	end
end


///// Ir TX Control State Machine ////////////////////////////////////////

always @(*) begin 
	case (rState)
			
		S_WAIT : begin	// reset
			wN_RPT_CNT_INC = 0;
			wN_MEM_RE = 0;
			wN_TX_END = 0;
			if (START_i & rTX_ON) begin
				wN_CRR_CYC_CNT_SET1 = 1;
				wN_MEM_RE = 1;
				wN_State = S_IR_ON;
			end
			else begin
				wN_CRR_CYC_CNT_SET1 = 0;
				wN_MEM_RE = 0;
				wN_State = S_WAIT;
			end
		end

		S_IR_ON : begin	// 
			wN_RPT_CNT_INC = 0;
			wN_TX_END = 0;
			if (wCLK_CNT_FULL & wCRR_CYC_CNT_FULL) begin
				wN_CRR_CYC_CNT_SET1 = 1;
				wN_MEM_RE = 1;
				wN_State = S_IR_OFF;
			end
			else begin
				wN_CRR_CYC_CNT_SET1 = 0;
				wN_MEM_RE = 0;
				wN_State = S_IR_ON;
			end
		end

		S_IR_OFF : begin	// 
			if (wCLK_CNT_FULL & wCRR_CYC_CNT_FULL) begin
				if (rLAST_CODE) begin
					if (wRPT_DONE | STOP_i) begin
						wN_CRR_CYC_CNT_SET1 = 0;
						wN_TX_END = 1;
						wN_RPT_CNT_INC = 0;
						wN_MEM_RE = 0;
						wN_State = S_WAIT;
					end
					else begin
						wN_CRR_CYC_CNT_SET1 = 1;
						wN_TX_END = 0;
						wN_RPT_CNT_INC = 1;
						wN_MEM_RE = 1;
						wN_State = S_IR_ON;
					end
				end
				else begin
					wN_CRR_CYC_CNT_SET1 = 1;
					wN_TX_END = 0;
					wN_RPT_CNT_INC = 0;
					wN_MEM_RE = 1;
					wN_State = S_IR_ON;
				end
			end
			else begin
				wN_CRR_CYC_CNT_SET1 = 0;
				wN_TX_END = 0;
				wN_RPT_CNT_INC = 0;
				wN_MEM_RE = 0;
				wN_State = S_IR_OFF;
			end
		end

		default : begin
			wN_State = S_WAIT;
			wN_RPT_CNT_INC = 0;
			wN_MEM_RE = 0;
			wN_TX_END = 0;
			wN_CRR_CYC_CNT_SET1 = 0;
		end
	endcase
end

always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rState <= S_WAIT;
		rCRR_CYC_CNT_SET1 <= 0;
		rRPT_CNT_INC <= 0;
		rMEM_RE <= 0;
		rTX_END <= 0;
	end
	else begin
		rState <= wN_State;
		rCRR_CYC_CNT_SET1 <= wN_CRR_CYC_CNT_SET1;
		rRPT_CNT_INC <= wN_RPT_CNT_INC;
		rMEM_RE <= wN_MEM_RE;
		rTX_END <= wN_TX_END;
	end
end

endmodule
