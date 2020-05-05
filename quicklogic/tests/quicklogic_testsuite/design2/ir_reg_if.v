//**********************************************************
//Title:    ir_reg_if
//Design:   ir_reg_if.v
//Author:  	MT
//Function: IrDA Remote TX/RX controller Register I/F to SPI
//Company:  QuickLogic Corp.
//Date:     Aug xx, 2014
//
//**********************************************************
parameter	ADR_PSB_REP_DEL_LSB =		7'h40;
parameter	ADR_PSB_REP_DEL_MSB =		7'h41;
parameter	ADR_PSB_REP_DEL_LSB_1 =		7'h42;
parameter	ADR_PSB_ID_LSB =			7'h50;
parameter	ADR_PSB_ID_MSB =			7'h51;
parameter	ADR_PSB_VER_LSB =			7'h52;
parameter	ADR_PSB_VER_MSB =			7'h53;
parameter	ADR_COMMAND =				7'h54;
parameter	ADR_STAT_CTRL =				7'h55;
parameter	ADR_CRR_CYC_LEN_LSB =		7'h56;
parameter	ADR_CRR_CYC_LEN_MSB =		7'h57;
parameter	ADR_TX_DUTY_RX_LIMIT_LSB =	7'h58;
parameter	ADR_TX_DUTY_RX_LIMIT_MSB =	7'h59;
parameter	ADR_CODE_BGN_LSB =			7'h5A;
parameter	ADR_CODE_BGN_MSB =			7'h5B;
parameter	ADR_CODE_END_LSB =			7'h5C;
parameter	ADR_CODE_END_MSB =			7'h5D;
parameter	ADR_TX_RPT_LEN_RX_CTRL =	7'h5E;
parameter	ADR_CODE_ADR_IDX =			7'h5F;

// 7'h60 - 7'h7F : Code Address Space

parameter	PSB_ID_LSB = 	8'h02;	// tentative
parameter	PSB_ID_MSB = 	8'h10;	// tentative
parameter	PSB_VER_LSB = 	8'h01;	// tentative
parameter	PSB_VER_MSB = 	8'h00;	// tentative

`timescale 1ns/10ps
`define WISHBONE
module ir_reg_if
	#(
	parameter	MEM_ADR_WIDTH        = 11)
(	
	input 						RST_i,					// active-high reset
	input						CLK_i,					// clock (~12MHz?)
`ifdef WISHBONE
	input        				wb_clk_i,     // master clock input
	input        				wb_rst_i,     // synchronous active high reset
	input        				arst_i,       // asynchronous reset
	input  [7:0] 				wb_adr_i,     // lower address bits
	input  [7:0] 				wb_dat_i,    // databus input
	output reg 	[7:0] 		    wb_dat_o,     // databus output
	input        				wb_we_i,     // write enable input
	input        				wb_stb_i,     // stobe/core select signal
	input        				wb_cyc_i,    // valid bus cycle input
	output       				wb_ack_o,    // bus cycle acknowledge output


`else	
	
	input						REG_CLK_i,				// Register Clock (~1.5MHz?)
	input [6:0]					REG_ADR_i,				// Register Address
	input [7:0]					REG_WD_i,				// Register Write Data
	input 						REG_WE_i,				// Register Write Enable
	output [7:0]				REG_RD_o,				// Register Read Data
`endif
//	input 						REG_RD_ACK_i,			// Register Read Data Acknowledge
	
	output						SW_RST_o,				// SW Reset, active high
	output						CLK_EN_o,				// PSB Clock Enable
	output 						MODE_o,					// IrDA Mode 0: Tx, 1: Rx
	output 						START_o,				// IrDA Transaction Start Flag
	input 						START_CLR_i,			// IrDA Transaction Start Clear Flag
	output 						STOP_o,					// IrDA Transaction Stop Flag
	input 						STOP_CLR_i,				// IrDA Transaction Stop Clear Flag
	input 						BUSY_i,					// IrDA Transaction Busy Flag
	output						INT_EN_o,				// Interrupt Enable
	output						RX_GPIO_EN_o,			// GPIO Enable for Rx Transaction
	output						RX_POL_INV_o,			// Rx Signal Polarity Inversion Flag
	output [15:0]				TX_CRR_CYC_LEN_o,		// Tx Carrier Cycle Length
	output [15:0]				TX_DUTY_RX_LIMIT_o,		// Tx Carrier Duty Length / Rx Limit Address
	output [7:0]				TX_RPT_LEN_RX_CTRL_o,	// Tx Repeat Length / Rx Control
	output [MEM_ADR_WIDTH-1:0]	CODE_BGN_ADR_o,			// Tx/Rx Code Begin Address
	output [MEM_ADR_WIDTH-1:0]	TX_CODE_END_ADR_o,		// Tx Code End Address
	input [15:0]				RX_CRR_CYC_LEN_i,		// Rx Carrier Cycle Length
	input [MEM_ADR_WIDTH-1:0]	RX_CODE_END_ADR_i,		// Rx Code End Address

	input						INT_i,					// Tx/Rx Interrupt
	output						INT_CLR_o,				// Tx/Rx Interrupt Clear

	output						MEM_WE_o,				// Memory Write Enable
	output						MEM_RE_o,				// Memory Read Enable
	output [MEM_ADR_WIDTH-1:0]	MEM_ADR_o,				// Memory Address
	output [7:0]				MEM_WD_o,				// Memory Write Data
	input [7:0]					MEM_RD_i				// Memory Read Data
);

//`include "../rtl/compile_param.vh"
//`include "../../../IR/IP/Ir_rtl/compile_param.vh"
//`include "compile_param.vh"
/*
parameter	PSB_ID_LSB = 0;
parameter	PSB_ID_MSB = 0;
parameter	PSB_VER_LSB = 0;
parameter	PSB_VER_MSB = 0;
*/
reg						rSW_RST;
reg						rMODE_s1, rMODE_s2, rSTART_s1, rSTART_s2, rSTOP_s1, rSTOP_s2;
reg						rCLK_EN, rMODE, rSTART, rSTOP, rINT_CLR;
reg 					rREPEAT,rREPEAT_s1,rREPEAT_s2;
reg 					rREPEATSTOP,rREPEATSTOP_s1,rREPEATSTOP_s2;
reg						rINT_EN, rRX_GPIO_EN, rRX_POL_INV;
reg [15:0]				rTX_CRR_CYC_LEN, rTX_DUTY_RX_LIMIT;
reg [23:0]				rTX_RPT_DEL_LEN;
reg [23:0]              rTX_RPT_DEL_LEN_ctr;
reg [7:0]				rTX_RPT_LEN_RX_CTRL;
reg						gen_rpt_strt;

reg 		[3:0]		rpt_cntr_state;
parameter   			st_IDLE_CHK_RPT_STRT  = 3'b000;
parameter   			st_CHK_RPT       	  = 3'b001;
parameter   			st_RUN_DELAYCTR         = 3'b010;
parameter   			st_WAIT_TX_INTR         = 3'b011;
parameter   			st_WAIT_BUSY0         = 3'b100;
parameter   			st_WAIT_BUSY1         = 3'b101;


reg [MEM_ADR_WIDTH-1:0]	rCODE_BGN_ADR, rTX_CODE_END_ADR;
//reg [1:0]				rRX_CRR_OFFSET_LEN, rRX_CRR_SAMPLE_LEN;
//reg [3:0]				rRX_OFF_TIMEOUT_LEN;
reg [5:0]				rMEM_ADR_IDX;
reg [7:0]				wREG_RD;
reg						rREG_WE_s1, rREG_WE_s2, rREG_WE_s3;
wire					wREG_WE = rREG_WE_s2 & (~rREG_WE_s3);

reg BUSY_r1,BUSY_r2;


assign	SW_RST_o = rSW_RST;
assign 	CLK_EN_o = rCLK_EN;
assign 	MODE_o = rMODE_s2;
//assign 	START_o = rSTART_s2;
assign 	START_o = rSTART_s2 | gen_rpt_strt;
assign 	STOP_o = rSTOP_s2;
assign 	INT_EN_o = rINT_EN;
assign 	RX_GPIO_EN_o = rRX_GPIO_EN;
assign 	RX_POL_INV_o = rRX_POL_INV;
assign 	INT_CLR_o = rINT_CLR;
assign 	TX_CRR_CYC_LEN_o = rTX_CRR_CYC_LEN;
assign 	TX_DUTY_RX_LIMIT_o = rTX_DUTY_RX_LIMIT;
assign 	TX_RPT_LEN_RX_CTRL_o = rTX_RPT_LEN_RX_CTRL;
assign 	CODE_BGN_ADR_o = rCODE_BGN_ADR;
assign 	TX_CODE_END_ADR_o = rTX_CODE_END_ADR;
assign	REG_RD_o = wREG_RD;

assign	MEM_RE_o = 1'b1;




`ifdef WISHBONE
//wire rREPEAT_CLR =  RST_i | rSTOP;
wire rREPEAT_CLR =  RST_i | rREPEATSTOP;
always @(posedge wb_clk_i or posedge rREPEAT_CLR)
begin
	if (rREPEAT_CLR)	
    begin	
		BUSY_r1 <= 1'b0;
		BUSY_r2 <= 1'b0;
	end
	else
	begin
		BUSY_r1 <= BUSY_i;
		BUSY_r2 <= BUSY_r1;	
	
    end
end
//Repeat Start generation counter

always @(posedge wb_clk_i or posedge rREPEAT_CLR)
begin
	if (rREPEAT_CLR)	
    begin	
		//rTX_RPT_DEL_LEN_ctr <= 24'h00;
		rTX_RPT_DEL_LEN_ctr <= 24'h0000;
		rpt_cntr_state 		<= st_IDLE_CHK_RPT_STRT;
		gen_rpt_strt 		<= 1'b0;
	end	
	else
	begin
	
	    case (rpt_cntr_state)
		
			st_IDLE_CHK_RPT_STRT 	: 	begin
											rTX_RPT_DEL_LEN_ctr <= 16'h00;
											gen_rpt_strt 		<= 1'b0;
										
											if (rREPEAT & rSTART)
												//rpt_cntr_state <= st_RUN_DELAYCTR;	
												//rpt_cntr_state <= st_WAIT_TX_INTR;	
												rpt_cntr_state <= st_WAIT_BUSY0;	
											else
												rpt_cntr_state <= rpt_cntr_state;
			
										end
									 
									
			//st_WAIT_TX_INTR         :   begin
            //
            //                                 if (INT_i==1)
			//									rpt_cntr_state 		<= st_RUN_DELAYCTR;
			//							end
			
			st_WAIT_BUSY0         :     begin
											 rTX_RPT_DEL_LEN_ctr 	<= 24'h000000;
			                                 if (BUSY_r2==0)
												rpt_cntr_state 		<= rpt_cntr_state;
											 else
												rpt_cntr_state 		<= st_WAIT_BUSY1;
												
											if (START_CLR_i)
													gen_rpt_strt 	<= 1'b0;	
												
										end
										
										
			st_WAIT_BUSY1         :     begin
											 rTX_RPT_DEL_LEN_ctr 	<= 24'h000000;
			                                 if (BUSY_r2==1)
											 begin
												rpt_cntr_state 		<= rpt_cntr_state;
												//gen_rpt_strt 		<= 1'b0;
											 end	
											 else
												rpt_cntr_state 		<= st_RUN_DELAYCTR;

											if (START_CLR_i)
													gen_rpt_strt 	<= 1'b0;												
												
												
										end										
			
									
			st_RUN_DELAYCTR 		: 	begin
											rTX_RPT_DEL_LEN_ctr <= rTX_RPT_DEL_LEN_ctr+1;
										
											if (rTX_RPT_DEL_LEN_ctr == rTX_RPT_DEL_LEN)
											begin
												rpt_cntr_state 	<= st_CHK_RPT;	
												gen_rpt_strt 	<= 1'b1;
											
											end	
											else
											begin
												rpt_cntr_state <= rpt_cntr_state;

												
											end	
			
										end									
									
									
			st_CHK_RPT 				: 	begin
											rTX_RPT_DEL_LEN_ctr 	<= 24'h000000;
											//gen_rpt_strt 			<= 1'b0;
											gen_rpt_strt 			<= gen_rpt_strt;
											if (rREPEAT)			
											begin
												//rpt_cntr_state 			<= st_RUN_DELAYCTR;
												//rpt_cntr_state 			<= st_WAIT_TX_INTR;
												 if (BUSY_r2==0)
													rpt_cntr_state 			<= st_WAIT_BUSY0;
												 else
													rpt_cntr_state 			<= st_WAIT_BUSY1;
											end
											else
											begin
												rpt_cntr_state 			<= st_IDLE_CHK_RPT_STRT;
											end


										end
		
		
		
		
		
		
		endcase
		

	end
		


end


reg wb_ack_i;
assign wb_ack_o = wb_ack_i;
wire rst_i = arst_i;
// generate wishbone write access
wire wb_wacc = wb_we_i & wb_ack_i;

wire [4:0]				wMEM_ADR_LSB 	= (&wb_adr_i[6:5]) ? wb_adr_i[4:0] : 0;
assign					MEM_WE_o 		= wb_wacc & wb_adr_i[6:5];
assign					MEM_WD_o 		= wb_dat_i;
assign					MEM_ADR_o 		= {rMEM_ADR_IDX, wMEM_ADR_LSB};

	
	// generate acknowledge output signal
	always @(posedge wb_clk_i or posedge rst_i)
	  if (rst_i)
	    wb_ack_i <= 1'b0;
	  else if (wb_rst_i)
	    wb_ack_i <= 1'b0;
	  else
	    wb_ack_i <= #1 wb_cyc_i & wb_stb_i & ~wb_ack_i; // because timing is always honored

		
	// assign DAT_O
	always @(posedge wb_clk_i)
	begin
	  //casex ({rMODE,wb_adr_i}) // synopsys parallel_case
	  casex ({rMODE,wb_adr_i[6:0]}) // synopsys parallel_case
	    {1'bx, ADR_PSB_REP_DEL_LSB} : 		wb_dat_o = rTX_RPT_DEL_LEN[7:0];
	    {1'bx, ADR_PSB_REP_DEL_MSB} : 		wb_dat_o = rTX_RPT_DEL_LEN[15:8];	  
	    {1'bx, ADR_PSB_REP_DEL_LSB_1} : 	wb_dat_o = rTX_RPT_DEL_LEN[23:16];	  
		{1'bx, ADR_PSB_ID_LSB} : 			wb_dat_o = PSB_ID_LSB;
		{1'bx, ADR_PSB_ID_MSB} : 			wb_dat_o = PSB_ID_MSB;
		{1'bx, ADR_PSB_VER_LSB} : 			wb_dat_o = PSB_VER_LSB;
		{1'bx, ADR_PSB_VER_MSB} : 			wb_dat_o = PSB_VER_MSB;
		//{1'bx, ADR_COMMAND} : 				wb_dat_o = {rSW_RST, 2'd0, rMODE, rSTOP, 2'd0, rSTART};
		//{1'bx, ADR_COMMAND} : 				wb_dat_o = {rSW_RST, 2'd0, rMODE, rSTOP, 1'b0,rREPEAT, rSTART};
		{1'bx, ADR_COMMAND} : 				wb_dat_o = {rSW_RST, 2'd0, rMODE, rSTOP, rREPEATSTOP,rREPEAT, rSTART};
		{1'bx, ADR_STAT_CTRL} : 			wb_dat_o = {rCLK_EN, rINT_EN, rRX_GPIO_EN, rRX_POL_INV, INT_i, 2'd0, BUSY_i};
		{1'b0, ADR_CRR_CYC_LEN_LSB} :	 	wb_dat_o = rTX_CRR_CYC_LEN[7:0];
		{1'b1, ADR_CRR_CYC_LEN_LSB} : 		wb_dat_o = RX_CRR_CYC_LEN_i[7:0];
		{1'b0, ADR_CRR_CYC_LEN_MSB} :	 	wb_dat_o = rTX_CRR_CYC_LEN[15:8];
		{1'b1, ADR_CRR_CYC_LEN_MSB} : 		wb_dat_o = RX_CRR_CYC_LEN_i[15:8];
		{1'bx, ADR_TX_DUTY_RX_LIMIT_LSB} : 	wb_dat_o = rTX_DUTY_RX_LIMIT[7:0];
		{1'bx, ADR_TX_DUTY_RX_LIMIT_MSB} : 	wb_dat_o = rTX_DUTY_RX_LIMIT[15:8];
		{1'bx, ADR_TX_RPT_LEN_RX_CTRL} : 	wb_dat_o = rTX_RPT_LEN_RX_CTRL;
		{1'bx, ADR_CODE_ADR_IDX} : 			wb_dat_o = {2'd0, rMEM_ADR_IDX};
		{1'bx, ADR_CODE_BGN_LSB} : 			wb_dat_o = rCODE_BGN_ADR[7:0];
		{1'bx, ADR_CODE_BGN_MSB} : 			wb_dat_o = {5'd0, rCODE_BGN_ADR[MEM_ADR_WIDTH-1:8]};
		{1'b0, ADR_CODE_END_LSB} : 			wb_dat_o = rTX_CODE_END_ADR[7:0];
		{1'b1, ADR_CODE_END_LSB} : 			wb_dat_o = RX_CODE_END_ADR_i[7:0];
		{1'b0, ADR_CODE_END_MSB} : 			wb_dat_o = {5'd0, rTX_CODE_END_ADR[MEM_ADR_WIDTH-1:8]};
		{1'b1, ADR_CODE_END_MSB} : 			wb_dat_o = {5'd0, RX_CODE_END_ADR_i[MEM_ADR_WIDTH-1:8]};
		{1'bx, 7'b11x_xxxx} :				wb_dat_o = MEM_RD_i;
		default : 							wb_dat_o = 8'h0;
	  endcase
	end		
	
	
	//Sync
	always @(posedge CLK_i or posedge RST_i) begin
		if (RST_i) begin
			rMODE_s1 <= 0;
			rMODE_s2 <= 0;
			rSTART_s1 <= 0;
			rSTART_s2 <= 0;
			rSTOP_s1 <= 0;
			rSTOP_s2 <= 0;
			rREPEAT_s1 <= 0;
			rREPEAT_s2 <= 0;
		end
		else begin
			rMODE_s1 <= rMODE;
			rMODE_s2 <= rMODE_s1;
			rSTART_s1 <= rSTART;
			rSTART_s2 <= rSTART_s1;
			rSTOP_s1 <= rSTOP;
			rSTOP_s2 <= rSTOP_s1;
			rREPEAT_s1 <= rREPEAT;
			rREPEAT_s2 <= rREPEAT_s1;			
		end
	end	
	
   //Write to register specific cases

	always @(posedge wb_clk_i or posedge RST_i) begin
		if (RST_i) begin
			rSW_RST <= 0;
			rMODE <= 0;
		end
		else if (wb_wacc & (wb_adr_i == ADR_COMMAND)) begin
			rSW_RST <= wb_dat_i[7];
			rMODE <= wb_dat_i[4];
		end
	end

wire	wSTART_RST = RST_i | START_CLR_i;

	always @(posedge wb_clk_i or posedge wSTART_RST) begin
		if (wSTART_RST) begin
			rSTART <= 0;
		end
		else if (wb_wacc & (wb_adr_i == ADR_COMMAND)) begin
			rSTART <= wb_dat_i[0];
		end
	end

wire	wSTOP_RST = RST_i | STOP_CLR_i;

	always @(posedge wb_clk_i or posedge wSTOP_RST) begin
		if (wSTOP_RST) begin
			rSTOP <= 0;
		end
		else if (wb_wacc & (wb_adr_i == ADR_COMMAND)) begin
			rSTOP <= wb_dat_i[3];
		end
	end   

	//New Change
//assign	rREPEAT_CLR =  RST_i | rSTOP;
	always @(posedge wb_clk_i or posedge rREPEAT_CLR) begin
		if (rREPEAT_CLR) begin
			rREPEAT <= 0;
		end
		else if (wb_wacc & (wb_adr_i == ADR_COMMAND)) begin
			rREPEAT <= wb_dat_i[1];
		end
	end 	
	
	always @(posedge wb_clk_i or posedge RST_i) begin
		if (RST_i) begin
			rREPEATSTOP <= 0;
		end
		else 
			if (wb_wacc & (wb_adr_i == ADR_COMMAND)) 
			begin
				rREPEATSTOP <= wb_dat_i[2];
			
			end
			else
				rREPEATSTOP <= 1'b0;
			
	end	
	

	// Write to registers
	always @(posedge wb_clk_i or posedge rst_i)
	  if (rst_i)
	    begin
	
			rCLK_EN 			<= 0;
			rINT_EN 			<= 0;
			rRX_GPIO_EN 		<= 0;
			rRX_POL_INV 		<= 0;
			rINT_CLR 			<= 0;

		    rTX_CRR_CYC_LEN     <= 0;
			rTX_DUTY_RX_LIMIT   <= 0;
			rTX_RPT_LEN_RX_CTRL <= 0;
			rMEM_ADR_IDX        <= 0;
			rCODE_BGN_ADR 		<= 0;
			rTX_CODE_END_ADR 	<= 0;
			
			rTX_RPT_DEL_LEN 	<= 24'h1050BA;
	    end
	  else if (wb_rst_i)
	    begin
			rCLK_EN 			<= 0;
			rINT_EN 			<= 0;
			rRX_GPIO_EN 		<= 0;
			rRX_POL_INV 		<= 0;
			rINT_CLR 			<= 0;

		    rTX_CRR_CYC_LEN     <= 0;
			rTX_DUTY_RX_LIMIT   <= 0;
			rTX_RPT_LEN_RX_CTRL <= 0;
			rMEM_ADR_IDX        <= 0;
			rCODE_BGN_ADR 		<= 0;
			rTX_CODE_END_ADR 	<= 0;		
			
			rTX_RPT_DEL_LEN 	<= 24'h1050BA;			//108 ms for 12 Mhz clock
			
	    end
	  else
	   if (wb_wacc)
	   begin
	      case (wb_adr_i) // synopsys parallel_case
		  
			ADR_PSB_REP_DEL_LSB : 		rTX_RPT_DEL_LEN[7:0]	<= wb_dat_i[7:0];
			ADR_PSB_REP_DEL_MSB : 		rTX_RPT_DEL_LEN[15:8]	<= wb_dat_i[7:0];		  
			ADR_PSB_REP_DEL_LSB_1: 		rTX_RPT_DEL_LEN[23:16]	<= wb_dat_i[7:0];		  

		    ADR_STAT_CTRL               : 	begin
												rCLK_EN 		<= wb_dat_i[7];
												rINT_EN 		<= wb_dat_i[6];
						                        rRX_GPIO_EN 	<= wb_dat_i[5];
			                                    rRX_POL_INV 	<= wb_dat_i[4];
			                                    rINT_CLR 		<= ~wb_dat_i[3];
											end	
		    ADR_CRR_CYC_LEN_LSB  		: rTX_CRR_CYC_LEN[7:0] 		 		     <= wb_dat_i[7:0];
		    ADR_CRR_CYC_LEN_MSB  		: rTX_CRR_CYC_LEN[15:8] 		 		 <= wb_dat_i[7:0];
		    ADR_TX_DUTY_RX_LIMIT_LSB  	: rTX_DUTY_RX_LIMIT[7:0] 		 		 <= wb_dat_i[7:0];
		    ADR_TX_DUTY_RX_LIMIT_MSB  	: rTX_DUTY_RX_LIMIT[15:8]		 		 <= wb_dat_i[7:0];
		    ADR_TX_RPT_LEN_RX_CTRL  	: rTX_RPT_LEN_RX_CTRL 			 		 <= wb_dat_i[7:0];
		    ADR_CODE_ADR_IDX 			: rMEM_ADR_IDX 						 	 <= wb_dat_i[5:0]; 
		    ADR_CODE_BGN_LSB 			: rCODE_BGN_ADR[7:0] 				 	 <= wb_dat_i[7:0];  
			ADR_CODE_BGN_MSB 			: rCODE_BGN_ADR[MEM_ADR_WIDTH-1:8] 	     <= wb_dat_i[7:0]; 
		    ADR_CODE_END_LSB 			: rTX_CODE_END_ADR[7:0] 				 <= wb_dat_i[7:0];
		    ADR_CODE_END_MSB 			: rTX_CODE_END_ADR[MEM_ADR_WIDTH-1:8]    <= wb_dat_i[7:0];
		  
		  

	         default: ;
	      endcase
		end  
		else 
		begin	
			if (rINT_CLR) begin	// self reset
				rINT_CLR <= 0;
		end
		end  

`else

wire [4:0]				wMEM_ADR_LSB = (&REG_ADR_i[6:5]) ? REG_ADR_i[4:0] : 0;
assign					MEM_WE_o = wREG_WE & REG_ADR_i[6:5];
assign					MEM_WD_o = REG_WD_i;
assign					MEM_ADR_o 		= {rMEM_ADR_IDX, wMEM_ADR_LSB};

always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rREG_WE_s1 <= 0;
		rREG_WE_s2 <= 0;
		rREG_WE_s3 <= 0;
	end
	else begin
		rREG_WE_s1 <= REG_WE_i;
		rREG_WE_s2 <= rREG_WE_s1;
		rREG_WE_s3 <= rREG_WE_s2;
	end
end


always @(posedge REG_CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rSW_RST <= 0;
		rMODE <= 0;
	end
	else if (REG_WE_i & (REG_ADR_i == ADR_COMMAND)) begin
		rSW_RST <= REG_WD_i[7];
		rMODE <= REG_WD_i[4];
	end
//	else begin
//		rMODE <= rMODE;
//	end
end

wire	wSTART_RST = RST_i | START_CLR_i;

always @(posedge REG_CLK_i or posedge wSTART_RST) begin
	if (wSTART_RST) begin
		rSTART <= 0;
	end
	else if (REG_WE_i & (REG_ADR_i == ADR_COMMAND)) begin
		rSTART <= REG_WD_i[0];
	end
//	else begin
//		rSTART <= rSTART;
//	end
end

wire	wSTOP_RST = RST_i | STOP_CLR_i;

always @(posedge REG_CLK_i or posedge wSTOP_RST) begin
	if (wSTOP_RST) begin
		rSTOP <= 0;
	end
	else if (REG_WE_i & (REG_ADR_i == ADR_COMMAND)) begin
		rSTOP <= REG_WD_i[3];
	end
//	else begin
//		rSTOP <= rSTOP;
//	end
end

always @(posedge CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rMODE_s1 <= 0;
		rMODE_s2 <= 0;
		rSTART_s1 <= 0;
		rSTART_s2 <= 0;
		rSTOP_s1 <= 0;
		rSTOP_s2 <= 0;
	end
	else begin
		rMODE_s1 <= rMODE;
		rMODE_s2 <= rMODE_s1;
		rSTART_s1 <= rSTART;
		rSTART_s2 <= rSTART_s1;
		rSTOP_s1 <= rSTOP;
		rSTOP_s2 <= rSTOP_s1;
	end
end


always @(posedge REG_CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rCLK_EN <= 0;
		rINT_EN <= 0;
		rRX_GPIO_EN <= 0;
		rRX_POL_INV <= 0;
		rINT_CLR <= 0;
	end
	else if (REG_WE_i & (REG_ADR_i == ADR_STAT_CTRL)) begin
		rCLK_EN <= REG_WD_i[7];
		rINT_EN <= REG_WD_i[6];
		rRX_GPIO_EN <= REG_WD_i[5];
		rRX_POL_INV <= REG_WD_i[4];
		rINT_CLR <= ~REG_WD_i[3];
	end
	else if (rINT_CLR) begin	// self reset
		rINT_CLR <= 0;
	end
//	else begin
//		rCLK_EN <= rCLK_EN;
//		rINT_EN <= rINT_EN;
//		rRX_GPIO_EN <= rRX_GPIO_EN;
//		rRX_POL_INV <= rRX_POL_INV;
//		rINT_CLR <= rINT_CLR;
//	end
end


always @(posedge REG_CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rTX_CRR_CYC_LEN <= 0;
	end
	else if (REG_WE_i & (REG_ADR_i == ADR_CRR_CYC_LEN_LSB)) begin
		rTX_CRR_CYC_LEN[7:0] <= REG_WD_i;
	end
	else if (REG_WE_i & (REG_ADR_i == ADR_CRR_CYC_LEN_MSB)) begin
		rTX_CRR_CYC_LEN[15:8] <= REG_WD_i;
	end
//	else begin
//		rTX_CRR_CYC_LEN <= rTX_CRR_CYC_LEN;
//	end
end

always @(posedge REG_CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rTX_DUTY_RX_LIMIT <= 0;
	end
	else if (REG_WE_i & (REG_ADR_i == ADR_TX_DUTY_RX_LIMIT_LSB)) begin
		rTX_DUTY_RX_LIMIT[7:0] <= REG_WD_i;
	end
	else if (REG_WE_i & (REG_ADR_i == ADR_TX_DUTY_RX_LIMIT_MSB)) begin
		rTX_DUTY_RX_LIMIT[15:8] <= REG_WD_i;
	end
//	else begin
//		rTX_DUTY_RX_LIMIT <= rTX_DUTY_RX_LIMIT;
//	end
end

always @(posedge REG_CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rTX_RPT_LEN_RX_CTRL <= 0;
	end
	else if (REG_WE_i & (REG_ADR_i == ADR_TX_RPT_LEN_RX_CTRL)) begin
		rTX_RPT_LEN_RX_CTRL <= REG_WD_i;
	end
//	else begin
//		rTX_RPT_LEN_RX_CTRL <= rTX_RPT_LEN_RX_CTRL;
//	end
end

always @(posedge REG_CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rMEM_ADR_IDX <= 0;
	end
	else if (REG_WE_i & (REG_ADR_i == ADR_CODE_ADR_IDX)) begin
		rMEM_ADR_IDX <= REG_WD_i[5:0];
	end
//	else if (wREG_WE & (REG_ADR_i == 7'h7F)) begin	// end of lower address edge
//		rMEM_ADR_IDX <= rMEM_ADR_IDX + 1;
//	end
//	else begin
//		rMEM_ADR_IDX <= rMEM_ADR_IDX;
//	end
end

always @(posedge REG_CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rCODE_BGN_ADR <= 0;
	end
	else if (REG_WE_i & (REG_ADR_i == ADR_CODE_BGN_LSB)) begin
		rCODE_BGN_ADR[7:0] <= REG_WD_i;
	end
	else if (REG_WE_i & (REG_ADR_i == ADR_CODE_BGN_MSB)) begin
		rCODE_BGN_ADR[MEM_ADR_WIDTH-1:8] <= REG_WD_i;
	end
//	else begin
//		rCODE_BGN_ADR <= rCODE_BGN_ADR;
//	end
end

always @(posedge REG_CLK_i or posedge RST_i) begin
	if (RST_i) begin
		rTX_CODE_END_ADR <= 0;
	end
	else if (REG_WE_i & (REG_ADR_i == ADR_CODE_END_LSB)) begin
		rTX_CODE_END_ADR[7:0] <= REG_WD_i;
	end
	else if (REG_WE_i & (REG_ADR_i == ADR_CODE_END_MSB)) begin
		rTX_CODE_END_ADR[MEM_ADR_WIDTH-1:8] <= REG_WD_i;
	end
//	else begin
//		rTX_CODE_END_ADR <= rTX_CODE_END_ADR;
//	end
end


///// SPI Register Read /////////////////////////////////////////////////////

always @(*) begin
	casex ({rMODE, REG_ADR_i})

		{1'bx, ADR_PSB_ID_LSB} : 			wREG_RD = PSB_ID_LSB;
		{1'bx, ADR_PSB_ID_MSB} : 			wREG_RD = PSB_ID_MSB;
		{1'bx, ADR_PSB_VER_LSB} : 			wREG_RD = PSB_VER_LSB;
		{1'bx, ADR_PSB_VER_MSB} : 			wREG_RD = PSB_VER_MSB;
		{1'bx, ADR_COMMAND} : 				wREG_RD = {rSW_RST, 2'd0, rMODE, rSTOP, 2'd0, rSTART};
		{1'bx, ADR_STAT_CTRL} : 			wREG_RD = {rCLK_EN, rINT_EN, rRX_GPIO_EN, rRX_POL_INV, INT_i, 2'd0, BUSY_i};
		{1'b0, ADR_CRR_CYC_LEN_LSB} :	 	wREG_RD = rTX_CRR_CYC_LEN[7:0];
		{1'b1, ADR_CRR_CYC_LEN_LSB} : 		wREG_RD = RX_CRR_CYC_LEN_i[7:0];
		{1'b0, ADR_CRR_CYC_LEN_MSB} :	 	wREG_RD = rTX_CRR_CYC_LEN[15:8];
		{1'b1, ADR_CRR_CYC_LEN_MSB} : 		wREG_RD = RX_CRR_CYC_LEN_i[15:8];
		{1'bx, ADR_TX_DUTY_RX_LIMIT_LSB} : 	wREG_RD = rTX_DUTY_RX_LIMIT[7:0];
		{1'bx, ADR_TX_DUTY_RX_LIMIT_MSB} : 	wREG_RD = rTX_DUTY_RX_LIMIT[15:8];
		{1'bx, ADR_TX_RPT_LEN_RX_CTRL} : 	wREG_RD = rTX_RPT_LEN_RX_CTRL;
		{1'bx, ADR_CODE_ADR_IDX} : 			wREG_RD = {2'd0, rMEM_ADR_IDX};
		{1'bx, ADR_CODE_BGN_LSB} : 			wREG_RD = rCODE_BGN_ADR[7:0];
		{1'bx, ADR_CODE_BGN_MSB} : 			wREG_RD = {5'd0, rCODE_BGN_ADR[MEM_ADR_WIDTH-1:8]};
		{1'b0, ADR_CODE_END_LSB} : 			wREG_RD = rTX_CODE_END_ADR[7:0];
		{1'b1, ADR_CODE_END_LSB} : 			wREG_RD = RX_CODE_END_ADR_i[7:0];
		{1'b0, ADR_CODE_END_MSB} : 			wREG_RD = {5'd0, rTX_CODE_END_ADR[MEM_ADR_WIDTH-1:8]};
		{1'b1, ADR_CODE_END_MSB} : 			wREG_RD = {5'd0, RX_CODE_END_ADR_i[MEM_ADR_WIDTH-1:8]};
		{1'bx, 7'b11x_xxxx} :				wREG_RD = MEM_RD_i;
		default : wREG_RD = 8'd0;
	endcase
end
`endif

endmodule
