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
//`define DEBUG
module ir_rx_ctrl
	#(parameter	MEM_ADR_WIDTH = 10)
(
`ifdef DEBUG
	output [2:0]				rState_o,
	output						rCRR_RISE_o,
	output						rRXD_o,
`endif	
	input 						RST_i,				// active-high reset
	input						CLK_i,				// clock (~12MHz?)
	input						START_i,			// Rx Detection Start flag
	output						START_CLR_o,		// RX Detection Start Clear flag
	input						STOP_i,				// Rx Detection Stop flag
	output						STOP_CLR_o,			// RX Detection Stop Clear flag
	output						RX_ON_o,			// Rx Transaction ON flag
	input [1:0]					CRR_OFFSET_LEN_i,	// Rx Carrier Cycle Offset before seeking Average (value x 4)
	input [1:0]					CRR_SAMPLE_LEN_i,	// Rx Carrier Cycle Sample Length to calculate Average (2**(value+3))
	input [3:0]					OFF_TIMEOUT_LEN_i,	// Rx Code Timeout Length (0x1000*value), 0x0800 is used for 0
	input 						RXD_i,				// Rx Data
	output 						CLK_CNT_EN_o,		// Clock Count Enable
	output 						CLK_CNT_SET1_o,		// Clock Count Set to 1
	input [15:0]				CLK_CNT_i,			// Clock Count
	output [15:0]				CRR_CYC_LEN_o,		// RXD Carrier Cycle Length
	output 						CRR_CYC_CNT_EN_o,	// RXD Carrier Cycle Count Enable
	output 						CRR_CYC_CNT_SET1_o,	// RXD Carrier Cycle Count Set to 1
	input [15:0]				CRR_CYC_CNT_i,		// RXD Carrier Cycle Count
	output						RISE_CNT_SET1_o,	// RXD Carrier Rise Count Set to 1
	output						RISE_CNT_EN_o,		// RXD Carrier Rise Count Enable
	input [6:0]					RISE_CNT_i,			// RXD Carrier Rise Count
	input [MEM_ADR_WIDTH-1:0]	CODE_LIMIT_ADR_i,	// RXD Code Limit Address
	output [MEM_ADR_WIDTH-1:0]	CODE_END_ADR_o,		// RXD Code End Address
	output						MEM_WE_o,			// Memory Write Enable
	input [MEM_ADR_WIDTH-1:0]	MEM_ADR_i,			// Memory Address
	output [7:0]				MEM_WD_o,			// Memory Write Data
	output						INT_o,				// Interrupt Flag
	input						INT_CLR_i,			// Interrupt Clear Flag,
	
	output  [7:0]               rx_debug_o
);

//parameter	SAMPLE_MAX	= 6;	//2**6 = 64, max size of samples for average calculation
parameter	SAMPLE_MAX	= 5;	//2**5 = 32, max size of samples for average calculation

parameter [2:0]	S_WAIT			= 3'd0,
				S_IR_ON_CRR_CNT	= 3'd1,
				S_IR_ON			= 3'd2,
				S_IR_OFF_TEMP	= 3'd3,
				S_IR_OFF 		= 3'd4,
				S_IR_OFF_INC_OK	= 3'd5;

reg						rRX_ON;
reg						rRXD, rRXD_p1, rRXD_p2;
reg						rCRR_RISE;
//reg [SAMPLE_MAX:0]		rCRR_RISE_CNT;
reg						rCLK_CNT_EN;
reg [15+SAMPLE_MAX:0]	rCLK_CNT_SUM;	// can cover up to 32 samples		
reg [15:0] 				wCRR_CYC_AVG;
wire [15:0]				wOFF_CNT_ADJ;
reg [7:0]				rWD_MSB;
wire					wADJ;
reg [MEM_ADR_WIDTH-1:0]	rCODE_END_ADR;
wire					wMEM_WE, wMEM_WE_1ST;
reg						rMEM_WE_1ST_d;
reg [7:0]				wMEM_WD;
reg						rMSB_SEL;
reg						rINT;
reg						rINT_CLR_p, rINT_CLR;

reg [2:0]				rState, wN_State;
reg						rCRR_CYC_SEEK, wN_CRR_CYC_SEEK;
reg						rON_CODE_RDY, wN_ON_CODE_RDY;
reg						rCODE_END, wN_CODE_END, rINC_DIS, wN_INC_DIS;

reg [3:0]				wOFFSET_LEN;
reg						rOFFSET_DONE;
reg [3:0]				wSAMPLE_LEN;

wire		wCRR_RISE;
//wire		wOFFSET_FULL = ~rOFFSET_DONE & (rCRR_RISE_CNT == {2'd0, wOFFSET_LEN, 2'd0});
//wire		wOFFSET_FULL = ~rOFFSET_DONE & (RISE_CNT_i == {2'd0, wOFFSET_LEN, 2'd0});
wire		wOFFSET_FULL = ~rOFFSET_DONE & (RISE_CNT_i == {3'd0, wOFFSET_LEN});	// 1, 2, 4, or 8 offset
//wire		wCRR_RISE_CNT_FULL = rOFFSET_DONE & (rCRR_RISE_CNT == {wSAMPLE_LEN, 3'd0});	// 8, 16, 32, or 64 samples
//wire		wCRR_RISE_CNT_FULL = rOFFSET_DONE & (RISE_CNT_i == {wSAMPLE_LEN, 3'd0});	// 8, 16, 32, or 64 samples
wire		wCRR_RISE_CNT_FULL = rOFFSET_DONE & (RISE_CNT_i == {1'd0, wSAMPLE_LEN, 2'd0});	// 4, 8, 16, or 32 samples
wire		wCLK_CNT_FULL = (CLK_CNT_i == wCRR_CYC_AVG);
wire [15:0]	wCRR_CNT_TH = {1'd0, wCRR_CYC_AVG[15:1]};	// 1/2 of Average
wire		wIR_OFF_TIMEOUT = (OFF_TIMEOUT_LEN_i == 0) ? CRR_CYC_CNT_i[11] : (CRR_CYC_CNT_i[15:12] == OFF_TIMEOUT_LEN_i);
wire		wMEM_FULL = (MEM_ADR_i == (CODE_LIMIT_ADR_i - 1));


assign rx_debug_o[0] = wMEM_WE;
assign rx_debug_o[1] = rCODE_END;

assign	START_CLR_o = rRX_ON;
assign	STOP_CLR_o = rCODE_END;
assign	RX_ON_o = rRX_ON;
assign 	CLK_CNT_EN_o = rCLK_CNT_EN;
assign 	CLK_CNT_SET1_o = rRX_ON & (wCRR_RISE | (((rState == S_IR_ON) | (rState == S_IR_OFF_INC_OK)) & wCLK_CNT_FULL));
assign 	CRR_CYC_CNT_EN_o = rRX_ON & ((wCRR_RISE & (~rINC_DIS)) | ((rState == S_IR_OFF_INC_OK) & wCLK_CNT_FULL));
assign 	CRR_CYC_CNT_SET1_o = rRX_ON & (wCRR_RISE & ((rState == S_IR_OFF_INC_OK) | (rState == S_IR_OFF)) | rON_CODE_RDY);
assign	CRR_CYC_LEN_o = wCRR_CYC_AVG;
assign	CODE_END_ADR_o = rCODE_END_ADR;
assign	RISE_CNT_SET1_o = rRX_ON & wOFFSET_FULL & wCRR_RISE;
assign	RISE_CNT_EN_o = rRX_ON & wCRR_RISE;
assign	MEM_WE_o = wMEM_WE;
assign	MEM_WD_o = wMEM_WD;
assign	INT_o = rINT;
`ifdef DEBUG
	assign rState_o = rState;
	assign rCRR_RISE_o = rCRR_RISE;
	assign rRXD_o = rRXD;
`endif


always @(*) begin
	case (CRR_OFFSET_LEN_i)
		2'd0 : wOFFSET_LEN = 4'b0001;	// 1
		2'd1 : wOFFSET_LEN = 4'b0010;	// 2
		2'd2 : wOFFSET_LEN = 4'b0100;	// 4
//		2'd3 : wOFFSET_LEN = 4'b1000;	// 8
		default : wOFFSET_LEN = 4'b1000;
	endcase
end

always @(*) begin
	case (CRR_SAMPLE_LEN_i)
		2'd0 : wSAMPLE_LEN = 4'b0001;	//  4
		2'd1 : wSAMPLE_LEN = 4'b0010;	//  8
		2'd2 : wSAMPLE_LEN = 4'b0100;	// 16
//		2'd3 : wSAMPLE_LEN = 4'b1000;	// 32
		default : wSAMPLE_LEN = 4'b1000;
	endcase
end


always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rRX_ON <= 0;
	end
	else if (START_i) begin
		rRX_ON <= 1;
	end
	else if (rCODE_END) begin
		rRX_ON <= 0;
	end
end


always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rRXD_p2 <= 0;
		rRXD_p1 <= 0;
		rRXD <= 0;
	end
	else begin
		rRXD_p2 <= RXD_i;
		rRXD_p1 <= rRXD_p2;
		rRXD <= rRXD_p1;
	end
end

assign	wCRR_RISE = ~rRXD & rRXD_p1;

always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rCRR_RISE <= 0;
	end
	else begin
		rCRR_RISE <= wCRR_RISE;
	end
end

always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rCLK_CNT_EN <= 0;
	end
	else if (rCODE_END) begin
		rCLK_CNT_EN <= 0;
	end
	else if (rRX_ON & wCRR_RISE) begin
		rCLK_CNT_EN <= 1;
	end
//	else begin
//		rCLK_CNT_EN <= rCLK_CNT_EN;
//	end
end


///// Seek Carrier Cycle Count Average /////////////////////////
/*
always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rCRR_RISE_CNT <= 0;
	end
//	else if (~rRX_ON) begin
	else if (START_i) begin
		rCRR_RISE_CNT <= 0;
	end
	else if (wOFFSET_FULL & wCRR_RISE) begin
		rCRR_RISE_CNT <= 1;
	end
	else if (wCRR_RISE) begin
		rCRR_RISE_CNT <= rCRR_RISE_CNT + 1;
	end
end
*/
always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rOFFSET_DONE <= 0;
	end
	else if (~rRX_ON) begin
		rOFFSET_DONE <= 0;
	end
	else if ((CRR_OFFSET_LEN_i == 0) | (wOFFSET_FULL & wCRR_RISE)) begin
		rOFFSET_DONE <= 1;
	end
//	else begin
//		rOFFSET_DONE <= rOFFSET_DONE;
//	end
end


always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rCLK_CNT_SUM <= 0;
	end
	else if (START_i) begin
		case (CRR_SAMPLE_LEN_i)
			2'd0 : rCLK_CNT_SUM <= 2;		// 4/2
			2'd1 : rCLK_CNT_SUM <= 4;		// 8/2
			2'd2 : rCLK_CNT_SUM <= 8;		// 16/2
//			2'd3 : rCLK_CNT_SUM <= 16;		// 32/2
			default : rCLK_CNT_SUM <= 16;	// 32/2
		endcase
	end
	else if (rRX_ON & rCRR_CYC_SEEK & rOFFSET_DONE) begin
		rCLK_CNT_SUM <= rCLK_CNT_SUM + 1;
	end
//	else begin
//		rCLK_CNT_SUM <= rCLK_CNT_SUM;
//	end
end

always @(*) begin
	case (CRR_SAMPLE_LEN_i)
		2'd0 : wCRR_CYC_AVG = rCLK_CNT_SUM[(12+SAMPLE_MAX):(SAMPLE_MAX-3)];		// 4
		2'd1 : wCRR_CYC_AVG = rCLK_CNT_SUM[(13+SAMPLE_MAX):(SAMPLE_MAX-2)];		// 8
		2'd2 : wCRR_CYC_AVG = rCLK_CNT_SUM[(14+SAMPLE_MAX):(SAMPLE_MAX-1)];		// 16
//		2'd3 : wCRR_CYC_AVG = rCLK_CNT_SUM[(15+SAMPLE_MAX):(SAMPLE_MAX-1)];		// 32
		default : wCRR_CYC_AVG = rCLK_CNT_SUM[(15+SAMPLE_MAX):(SAMPLE_MAX)];	// 32
	endcase
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
	else if (rCODE_END) begin
		rINT <= 1;
	end
	else if (rINT_CLR) begin
		rINT <= 0;
	end
end

///// OFF Code count adjustment ///////////////////////////////////////////

assign	wADJ = (rState == S_IR_OFF) & wCRR_RISE;

assign	wOFF_CNT_ADJ = (CRR_CYC_CNT_i - 1);

always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rWD_MSB <= 0;
	end
	else begin
		rWD_MSB <= wADJ ? wOFF_CNT_ADJ[15:8] : CRR_CYC_CNT_i[15:8];
	end
end


///// Memory I/F //////////////////////////////////////////////////////////

assign	wMEM_WE_1ST =  rON_CODE_RDY | (((rState == S_IR_OFF) | (rState == S_IR_OFF_INC_OK)) & (wCRR_RISE | wIR_OFF_TIMEOUT));

always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rMEM_WE_1ST_d <= 0;
	end
	else begin
		rMEM_WE_1ST_d <= wMEM_WE_1ST;
	end
end

assign	wMEM_WE = wMEM_WE_1ST | rMEM_WE_1ST_d;	// create 2 CLK pulse


always @(posedge CLK_i or posedge RST_i) begin	// LSB/MSB Select Signal
	if (RST_i) begin
		rMSB_SEL <= 0;
	end
	else if (~rRX_ON) begin
		rMSB_SEL <= 0;
	end
	else if (wMEM_WE) begin
		rMSB_SEL <= ~rMSB_SEL;
	end
//	else begin
//		rMSB_SEL <= rMSB_SEL;
//	end
end

always @(*) begin
	casex ({wADJ, rMSB_SEL})
		2'bx1 : wMEM_WD = rWD_MSB;
		3'b10 : wMEM_WD = wOFF_CNT_ADJ[7:0];
//		3'b00 : wMEM_WD = CRR_CYC_CNT_i[7:0];
		default : wMEM_WD = CRR_CYC_CNT_i[7:0];
	endcase
end


///// End Address Handling ///////////////////////////////////////////////

always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rCODE_END_ADR <= 0;
	end
	else if (rCODE_END) begin
		rCODE_END_ADR <= MEM_ADR_i;	
	end
//	else begin
//		rCODE_END_ADR <= rCODE_END_ADR;
//	end
end


///// Ir RX Control State Machine ////////////////////////////////////////

always @(*) begin 
	case (rState)
			
		S_WAIT : begin	// reset
					wN_CRR_CYC_SEEK = 0;
					wN_ON_CODE_RDY = 0;
					wN_CODE_END = 0;
					wN_INC_DIS = 0;
					if (rRX_ON & wCRR_RISE) begin
						wN_CRR_CYC_SEEK = 1;
						wN_State = S_IR_ON_CRR_CNT;
					end
					else begin
						wN_CRR_CYC_SEEK = 0;
						wN_State = S_WAIT;
					end
				end

		S_IR_ON_CRR_CNT : begin	// ON Code & Carrier cycle counting
							wN_ON_CODE_RDY = 0;
							wN_INC_DIS = 0;
							if (STOP_i) begin
								wN_CRR_CYC_SEEK = 0;
								wN_CODE_END = 1;
								wN_State = S_WAIT;
							end
							else if (wCRR_RISE_CNT_FULL & wCRR_RISE) begin
								wN_CRR_CYC_SEEK = 0;
								wN_CODE_END = 0;
								wN_State = S_IR_ON;
							end
							else begin
								wN_CRR_CYC_SEEK = 1;
								wN_CODE_END = 0;
								wN_State = S_IR_ON_CRR_CNT;
							end
						end

		S_IR_ON : begin	// Carrier cycle count done, still ON Code
						wN_CRR_CYC_SEEK = 0;
						wN_ON_CODE_RDY = 0;
						wN_INC_DIS = 0;
						if (STOP_i) begin
							wN_CODE_END = 1;
							wN_State = S_WAIT;
						end
						else if (~wCRR_RISE & wCLK_CNT_FULL) begin
							wN_CODE_END = 0;
							wN_State = S_IR_OFF_TEMP;
						end
						else if (rCRR_RISE & wMEM_FULL) begin	// memory write full --- This shouldn't happen!!!
							wN_CODE_END = 1;		// one shot
							wN_State = S_WAIT;
						end
						else begin
							wN_CODE_END = 0;
							wN_State = S_IR_ON;
						end
					end

		S_IR_OFF_TEMP : begin	// ~boundary between ON & OFF Codes 
							wN_CRR_CYC_SEEK = 0;
							wN_INC_DIS = 0;
							if (STOP_i) begin
								wN_ON_CODE_RDY = 0;
								wN_CODE_END = 1;
								wN_State = S_WAIT;
							end
							else if (wCRR_RISE) begin	// still ON Code
								wN_ON_CODE_RDY = 0;
								wN_CODE_END = 0;
								wN_State = S_IR_ON;
							end
							else if (CLK_CNT_i == wCRR_CNT_TH) begin	// OFF Code detection
								wN_ON_CODE_RDY = 1;	// one shot
								wN_CODE_END = 0;
								wN_State = S_IR_OFF_INC_OK;
							end
							else begin
								wN_ON_CODE_RDY = 0;
								wN_CODE_END = 0;
								wN_State = S_IR_OFF_TEMP;
							end
					end

		S_IR_OFF : 	begin	// OFF Code
							wN_CRR_CYC_SEEK = 0;
							wN_ON_CODE_RDY = 0;
							wN_INC_DIS = 1;
							if (STOP_i | wIR_OFF_TIMEOUT | (wCRR_RISE & wMEM_FULL)) begin	// End of Codes
								wN_CODE_END = 1;		// one shot
								wN_INC_DIS = 1;
								wN_State = S_WAIT;
							end
							else if ((CLK_CNT_i == wCRR_CNT_TH) & (~wCRR_RISE)) begin	// 1/2 Cycle reached
								wN_CODE_END = 0;
								wN_INC_DIS = 0;
								wN_State = S_IR_OFF_INC_OK;
							end
							else if (wCRR_RISE) begin	// Next ON Code
								wN_CODE_END = 0;
								wN_INC_DIS = 1;
								wN_State = S_IR_ON;
							end
							else begin
								wN_CODE_END = 0;
								wN_INC_DIS = 1;
								wN_State = S_IR_OFF;
							end
					end

		S_IR_OFF_INC_OK : begin	// Got enough length of OFF Code
								wN_CRR_CYC_SEEK = 0;
								wN_ON_CODE_RDY = 0;
								wN_INC_DIS = 0;
								if (STOP_i | (wCRR_RISE & wMEM_FULL)) begin	// End of Codes
									wN_CODE_END = 1;		// one shot
									wN_State = S_WAIT;
								end
								else if (wCRR_RISE) begin	// Next ON Code
									wN_CODE_END = 0;
									wN_State = S_IR_ON;
								end
								else if (wCLK_CNT_FULL) begin
									wN_CODE_END = 0;
									wN_State = S_IR_OFF;
								end
								else begin
									wN_CODE_END = 0;
									wN_State = S_IR_OFF_INC_OK;
								end
						end

		default : begin
			wN_State = S_WAIT;
			wN_CRR_CYC_SEEK = 0;
			wN_ON_CODE_RDY = 0;
			wN_CODE_END = 0;
			wN_INC_DIS = 0;
		end
	endcase
end

always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rState <= S_WAIT;
		rCRR_CYC_SEEK <= 0;
		rON_CODE_RDY <= 0;
		rCODE_END <= 0;
		rINC_DIS <= 0;
	end
	else begin
		rState <= wN_State;
		rCRR_CYC_SEEK <= wN_CRR_CYC_SEEK;
		rON_CODE_RDY <= wN_ON_CODE_RDY;
		rCODE_END <= wN_CODE_END;
		rINC_DIS <= wN_INC_DIS;
	end
end

endmodule
