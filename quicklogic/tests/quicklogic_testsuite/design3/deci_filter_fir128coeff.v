/*******************************************************************
 *
 *    FILE:         deci_filter_fir121coeff.sv 
 *   
 *    DESCRIPTION:  FIR Decimation filter for 48 Khz to 16 khz.
 *
 *    HIERARCHY:   
 *
 *    AUTHOR:	    Anand A Wadke
 *
 *    HISTORY:
 *			        - 06/26/2016	Initial coding.
 *			
 *
 * Copyright (C) 2016, Licensed Customers of QuickLogic may copy and modify this
 * file for use in designing QuickLogic devices only.
 *
 * IMPORTANT NOTICE: DISCLAIMER OF WARRANTY
 * This design is provided without warranty of any kind.
 * QuickLogic Corporation does not warrant, guarantee or make any representations
 * regarding the use, or the results of the use, of this design. QuickLogic
 * disclaims all implied warranties, including but not limited to implied
 * warranties of merchantability and fitness for a particular purpose. In addition
 * and without limiting the generality of the foregoing, QuickLogic does not make
 * any warranty of any kind that any item developed based on this design, or any
 * portion of it, will not infringe any copyright, patent, trade secret or other
 * intellectual property right of any person or entity in any country. It is the
 * responsibility of the user of the design to seek licenses for such intellectual
 * property rights where applicable. QuickLogic shall not be liable for any
 * damages arising out of or in connection with the use of the design including
 * liability for lost profit, business interruption, or any other damages whatsoever.
 *
 * ------------------------------------------------------------
 * Date: June 26, 2017
 * Engineer: Anand Wadke
 * Revision: 0.1
 * Change:
 * 1. Initial Coding
 * 2. Modified the RAM Address generation for coefficient access to reduce the system clock frequency by 3.
      e.g. First y(0) is computed then y(3) instead of y(2). Earlier implementation used to compute y(0), y(1), y(2), y(3) ...
 *******************************************************************/
`timescale 1ns/10ps
//`define FIR_INDATA_RAM_INTERFACE
//`define SIM
//`define SIVA_MOD
//`define ANAND_MOD
//`define ADD_STATE_FOR_MUL_LATCH
module deci_filter_fir128coeff (
                                 fir_clk_i,
								 fir_reset_i,
								 fir_deci_ena_i,
								 fir_filter_run_i,
								 //fir_data_avl_i,
								 
								 WBs_CLK_i,
								 WBs_RST_i,
							 
								 //From I2S block
								 I2S_last_ram_write_i,
								 I2S_last_ram_addr_i,
								 I2S_ram_write_ena_i,
								 I2S_clk_i,
								 
								 //FIR Data Ram interface.
								 fir_dat_addr_o,
								 fir_indata_rd_en_o,
								 fir_data_i,
								 
								 //Coeff Ram Interface
								 wb_Coeff_RAM_aDDR_i,
								 wb_Coeff_RAM_Wen_i,
								 wb_Coeff_RAM_Data_i,	
								 wb_Coeff_RAM_Data_o,	
								 wb_Coeff_RAM_rd_access_ctrl_i,
								 
								 //16*16 mult
                                 fir_dat_mul_o,
                                 fir_coef_mul_o,
								 fir_mul_valid_o,
								 fir_cmult_i,
							 
								 fir_deci_data_o,
								 fir_deci_data_push_o,
								 
								 fir_deci_done_o
								 
								 
								 //WBs_ADR_i,
								 //WBs_CYC_i,
								 //WBs_BYTE_STB_i,
								 //WBs_WE_i,
								 //WBs_STB_i,
								 //WBs_DAT_i,
								 //WBs_DAT_o,
								 //WBs_ACK_o,								 
								 
								
								);
parameter                ADDRWIDTH                   =   9           ;
parameter                DATAWIDTH                   =  32           ;
								
								
input   		fir_clk_i; 
input   		fir_reset_i;
input   		fir_deci_ena_i;
input   		fir_filter_run_i;

input                    WBs_CLK_i           ; // Fabric Clock               from Fabric
input                    WBs_RST_i           ; // Fabric Reset               to   Fabric
// Wishbone Bus Signals
//
//input   [ADDRWIDTH-1:0]  WBs_ADR_i           ; // Address Bus                to   Fabric
//input                    WBs_CYC_i   ; 			// Cycle Chip Select          to   Fabric
//input             [3:0]  WBs_BYTE_STB_i      ; // Byte Enable Strobes        to   Fabric
//input                    WBs_WE_i            ; // Write Enable               to   Fabric
//input                    WBs_STB_i           ; // Strobe Signal              to   Fabric
//input   [DATAWIDTH-1:0]  WBs_DAT_i           ; // Write Data Bus             to   Fabric
//output  [DATAWIDTH-1:0]  WBs_DAT_o ;
//output                   WBs_ACK_o           ; // Transfer Cycle Acknowledge from Fabric


input                    I2S_last_ram_write_i;
input   [ADDRWIDTH-1:0]  I2S_last_ram_addr_i;
input                    I2S_ram_write_ena_i;
input 					 I2S_clk_i;

 
output  [8:0] 	fir_dat_addr_o; 
output   		fir_indata_rd_en_o; 
input   [15:0]	fir_data_i; 
//input 			fir_data_fifo_empty_i;

input 			  [8:0]  wb_Coeff_RAM_aDDR_i;		
input 					 wb_Coeff_RAM_Wen_i;
input            [15:0]  wb_Coeff_RAM_Data_i;
output           [15:0]  wb_Coeff_RAM_Data_o;
input 					 wb_Coeff_RAM_rd_access_ctrl_i;

`ifdef ANAND_MOD
output  signed [15:0]	fir_dat_mul_o; 
output  signed [15:0]	fir_coef_mul_o; 
input   signed [31:0]	fir_cmult_i;
`else
output  [15:0]	fir_dat_mul_o; 
output  [15:0]	fir_coef_mul_o; 
input   [31:0]	fir_cmult_i;
`endif
output  [1:0]	fir_mul_valid_o; 

output   		fir_deci_data_push_o;  
output  [15:0]	fir_deci_data_o; 

output 			fir_deci_done_o;

//parameter       TAP_CNT = 122;
parameter       TAP_CNT = 128;
								

//Fir FSM
reg 	[3:0]   fir_deci_fsm;

parameter	sFIR_DECI_IDLE	 		= 4'b0000;
parameter   sFIR_CHK_THRES_STS		= 4'b0001;
parameter   sFIR_LOAD_COEFF_DATA	= 4'b0010;
parameter	sFIR_FINAL_SUM	   	    = 4'b0011;   
parameter	sFIR_WT_I2S_3RDSAMP     = 4'b0100;   

reg [6:0]   coeff_mult_count;	//Not Used

//Multiple section							
`ifdef SIVA_MOD
reg  [31:0]	fir_deci_data_sum_sig;	
wire [15:0]	fir_deci_data_sum_sig_type_convert;
`elsif ANAND_MOD
reg  signed [32:0]	fir_deci_data_sum_sig;	
wire signed [15:0]	fir_deci_data_sum_sig_type_convert;
`else
reg  [30:0]	fir_deci_data_sum_sig;	
wire [30:0]	fir_deci_data_sum_sig_type_convert_31;	
wire [15:0]	fir_deci_data_sum_sig_type_convert;	
reg [15:0]	fir_deci_data_sum_sig_type_convert_reg;	
`endif						
							
reg  [30:0]	sim_fir_deci_data_sum_sig;								
								
//wire [15:0]	fir_deci_data_pos_sat;								
wire [15:0]	fir_deci_data_pos_neg_sat;								
//wire [15:0]	fir_deci_data_neg_sat;								
reg  		fir_deci_data_push_sig;	
							
reg  [15:0]	fir_dat_sig;								
reg  [15:0]	fir_coef_sig;								
reg  [1:0]	fir_mul_ena_sig;
wire [15:0]	fir_coeff_rd_data_sig;	

reg  [9:0]	fir_dat_addr_sig;	//1K Dept							
wire [9:0]	fir_dat_addr_sig_mi_1;	//1K Dept							
reg  [6:0]	fir_coef_addr_sig;  //1K Dept
wire  [8:0]	coef_ram_rd_addr_ptr;  
reg  [11:0]	fir_dat_addr_sig_index;//not used
//reg  [6:0]	sum_cnt_sig_index;
reg  [9:0]	sum_cnt_sig_index;

//Ram/fifo section
//reg 		fir_indata_pop_sig;
reg 		fir_indata_rd_en_sig;
reg 		fir_coeffdata_rd_en_sig;
reg         fir_indata_rd_en_sig1;

reg  [1:0]		dat_load_seq_ctrl;
//reg  [1:0]		decimation_sel_cnt;

//ADDress and Other Pointers 
reg  [9:0] 	sample_cnt;
reg  [7:0]	tap_cnt_index;

reg 		fir_sum_done;

//reg  [30:0]  intermediate_adder;

//reg 		WBs_ACK_coeff_adr;


reg 		i2s_wr_toggle;
reg 		I2S_ram_write_ena_sync_firclk0;
reg 		I2S_ram_write_ena_sync_firclk1;
reg 		I2S_ram_write_ena_sync_firclk2;
wire 		I2S_ram_write_ena_sync_firclk;
wire 		fir_ram_rd_ena;

reg [3:0] 	I2S_ram_data_cntr;
//wire [3:0] 	I2S_ram_data_cntr_mi_3;

reg 		I2S_last_ram_write_sync_firclk;

reg [7:0]  	decimator_last_dat_cnt;
reg 	   	deci_done;

wire 	   	fir_filter_reset;

reg 		deci_done_r1;
wire 		deci_done_pulse;
assign 		deci_done_pulse = deci_done_r1 & ~deci_done;

reg         odd_even_16_bit_write_marker; //1-Lower Byte written 0- Upper byte written

wire 		dummy_deci_data_push; 
reg 		dummy_deci_data_push_r1; 
reg 		dummy_deci_data_push_r2; 

reg 		laddr_thres_xed;
reg 		prev_fir_adr_msb;

wire        saturation_detect;

wire		fir_rst;


reg [31:0]  fir_cmult_sig_nedge;

//reg       I2S_last_ram_write_latched;


//assign coef_ram_rd_addr_ptr = {2'b00,fir_coef_addr_sig};
assign coef_ram_rd_addr_ptr = (wb_Coeff_RAM_rd_access_ctrl_i==1'b1)? wb_Coeff_RAM_aDDR_i : {2'b00,fir_coef_addr_sig};
assign wb_Coeff_RAM_Data_o  = fir_coeff_rd_data_sig;
		
                                
//assign intermediate_adder = intermediate_adder + {{1{fir_cmult_i[29]}}, fir_cmult_i[29:0};

`ifdef SIVA_MOD
//assign fir_deci_data_pos_sat = (saturation_detect==1'b1)? ((fir_deci_data_sum_sig[31] == 1'b0) ? 16'h7FFF : 16'h8001) 
assign saturation_detect 					= fir_deci_data_sum_sig[31] ^ fir_deci_data_sum_sig[30];
assign fir_deci_data_pos_neg_sat 			= ((fir_deci_data_sum_sig[31] == 1'b0) ? 16'h7FFF : 16'h8001); 
//assign fir_deci_data_sum_sig_type_convert 	= (saturation_detect==1'b1)? ( fir_deci_data_pos_neg_sat ) : ((fir_deci_data_sum_sig)>>>15);
assign fir_deci_data_sum_sig_type_convert 	= (saturation_detect==1'b1)? ( fir_deci_data_pos_neg_sat ) : ((fir_deci_data_sum_sig[30:15]));
`elsif ANAND_MOD
assign fir_deci_data_sum_sig_type_convert   = fir_deci_data_sum_sig[15:0];//(fir_deci_data_sum_sig[31:0] + {fir_deci_data_sum_sig[16], {15{~fir_deci_data_sum_sig[15]}}})>>>15;
`else
assign fir_deci_data_sum_sig_type_convert   = (fir_deci_data_sum_sig[30:0] + {fir_deci_data_sum_sig[15], {14{~fir_deci_data_sum_sig[15]}}})>>>15;
//assign fir_deci_data_sum_sig_type_convert_31   = (fir_deci_data_sum_sig[30:0] + {fir_deci_data_sum_sig[15], {14{~fir_deci_data_sum_sig[15]}}});
//assign fir_deci_data_sum_sig_type_convert      = fir_deci_data_sum_sig_type_convert_31[30:15];
`endif
//assign fir_deci_data_sum_sig_type_convert = (fir_deci_data_sum_sig[30:0])>>>15;


////assign  fir_deci_data_o 	 = 	fir_deci_data_sum_sig;	
//assign  fir_deci_data_o 	 = 	fir_deci_data_sum_sig_type_convert;	//Non Registered version Commented for testing 
assign  fir_deci_data_o 	 = 	fir_deci_data_sum_sig_type_convert_reg;	//Commented for testing 
//assign  fir_deci_data_o 	 = 	sim_fir_deci_data_sum_sig;	
assign  fir_deci_data_push_o = 	fir_deci_data_push_sig | dummy_deci_data_push;	

//assign  fir_dat_mul_o   	=   fir_dat_sig;
//assign  fir_coef_mul_o  	=   fir_coef_sig;							
//assign  fir_dat_mul_o   	=   (I2S_last_ram_write_sync_firclk == 1'b1 && (fir_dat_addr_sig[9:0] > I2S_last_ram_addr_i)) ? 0 : fir_data_i;						
assign  fir_dat_mul_o   	=   (I2S_last_ram_write_sync_firclk == 1'b1 && (fir_dat_addr_sig[9:0] > I2S_last_ram_addr_i) && (laddr_thres_xed==1'b0)) ? 0 : fir_data_i;						
assign  fir_coef_mul_o  	=   fir_coeff_rd_data_sig;	


					
assign  fir_mul_valid_o 	=   fir_mul_ena_sig;		

assign fir_dat_addr_o 		= 	fir_dat_addr_sig[8:0];
assign fir_indata_rd_en_o 	= 	fir_indata_rd_en_sig;

//assign I2S_ram_data_cntr_mi_3  = I2S_ram_data_cntr - 3;
assign fir_dat_addr_sig_mi_1 = fir_dat_addr_sig - 1;

//assign fir_filter_reset  = deci_done | fir_reset_i;
assign fir_filter_reset  = deci_done_pulse | fir_reset_i;

//assign fir_deci_done_o   = deci_done;
assign fir_deci_done_o   = deci_done_pulse;

always @(posedge fir_clk_i or posedge fir_filter_reset)	 
begin
	if (fir_filter_reset == 1'b1)
	begin
       fir_deci_data_sum_sig_type_convert_reg <= 0;
	end
    else
    begin
	   if (fir_sum_done)
	   begin
	     fir_deci_data_sum_sig_type_convert_reg  <= (fir_deci_data_sum_sig[30:0] + {fir_deci_data_sum_sig[15], {14{~fir_deci_data_sum_sig[15]}}})>>>15;
	   end	 
    end	
end

								
//always @(posedge fir_clk_i or posedge fir_reset_i)			
always @(posedge fir_clk_i or posedge fir_filter_reset)			
begin
	if (fir_filter_reset == 1'b1)
	begin
`ifdef SIVA_MOD
		fir_deci_data_sum_sig 	  <= 32'h4000;
`elsif ANAND_MOD		
		fir_deci_data_sum_sig 	  <= 0;
`else	
		fir_deci_data_sum_sig 	  <= 31'h0000;
`endif		
`ifdef SIM		
		sim_fir_deci_data_sum_sig <= 0;		
`endif		
		
		fir_deci_data_push_sig 	<= 1'b0;
		fir_dat_sig 			<= 16'h0000;//nu
		fir_coef_sig 			<= 16'h0000;
		fir_dat_addr_sig		<= 0;
		fir_coef_addr_sig   	<= 7'h00;		
		sum_cnt_sig_index  		<= 10'h00;		
		sample_cnt 				<= 10'h000;
		tap_cnt_index 			<= 8'h00;
		fir_mul_ena_sig 		<= 2'b00;
		fir_indata_rd_en_sig    <= 1'b0;
		fir_coeffdata_rd_en_sig <= 1'b0;
		coeff_mult_count        <= 0;
		prev_fir_adr_msb        <= 0;
		
		dat_load_seq_ctrl		<= 2'b00;
		//decimation_sel_cnt		<= 2'b00;
		fir_sum_done            <= 0;
		
		odd_even_16_bit_write_marker <= 1'b0;
		
		laddr_thres_xed    <= 1'b0;
		
		fir_deci_fsm            <= sFIR_DECI_IDLE;
	end
	else
	begin
		case (fir_deci_fsm)
			sFIR_DECI_IDLE : begin
								if (fir_deci_ena_i)
								begin
                                    //if ((I2S_ram_data_cntr_mi_3==0 || I2S_ram_data_cntr_mi_3[2]==1'b1 ) && (I2S_ram_data_cntr_mi_3[3] == 1'b0))
                                    if (I2S_ram_data_cntr==3)
									begin
										fir_deci_fsm            <= sFIR_CHK_THRES_STS;
									end
                                    else
                                    begin
									    fir_deci_fsm            <= fir_deci_fsm;
                                    end									
								end
								else
								begin
					    		    fir_deci_fsm            <= sFIR_DECI_IDLE;
								end
								
`ifdef SIVA_MOD
								fir_deci_data_sum_sig 	  <= 32'h4000;
`elsif ANAND_MOD								
								fir_deci_data_sum_sig 	  <= 0;
`else	
								fir_deci_data_sum_sig 	  <= 31'h0000;
`endif									
								//fir_deci_data_sum_sig 		<= 31'h0000;
`ifdef SIM		
								sim_fir_deci_data_sum_sig   <= 0;		
`endif	
								
								
								fir_deci_data_push_sig 		<= 1'b0;	
								
										
								fir_dat_sig 				<= 16'h0000;	
								fir_coef_sig 				<= 16'h0000;	
								fir_mul_ena_sig 			<= 2'b00;	
									
								//fir_indata_pop_sig      <= 1'b0;	
								fir_indata_rd_en_sig    	<= 1'b0;	
								fir_coeffdata_rd_en_sig 	<= 1'b0;
									
								fir_dat_addr_sig			<= 0;
								fir_coef_addr_sig   		<= 7'h00;
								sum_cnt_sig_index       	<= 10'h00;
																	
								sample_cnt 					<= 10'h000;
								tap_cnt_index 				<= 8'h00;
																		
								coeff_mult_count        	<= 0;	
								dat_load_seq_ctrl       	<= 0;

                                fir_sum_done                <= 0;								
								
								odd_even_16_bit_write_marker <= 1'b0;
								
								laddr_thres_xed    			<= 1'b0;
								prev_fir_adr_msb            <= 0;
									
								//decimation_sel_cnt		    <= 2'b00;

							 end
							 
		sFIR_CHK_THRES_STS : begin
								//if (fir_filter_run_i)
								//begin
									fir_deci_fsm  			   <=  sFIR_LOAD_COEFF_DATA;								
								//end
								//else
								//begin
								//	fir_deci_fsm  			   <=  fir_deci_fsm;								
								//end
`ifdef SIVA_MOD
								fir_deci_data_sum_sig 	  <= 32'h4000;
`elsif ANAND_MOD							
								fir_deci_data_sum_sig 	  <= 0;
`else	
								fir_deci_data_sum_sig 	  <= 31'h0000;
`endif
								
								//fir_deci_data_sum_sig 		<= 31'h0000;	
`ifdef SIM		
								sim_fir_deci_data_sum_sig   <= 0;		
`endif									
								fir_deci_data_push_sig 		<= 1'b0;	
										
								fir_dat_sig 				<= 16'h0000;	
								fir_coef_sig 				<= 16'h0000;	
								fir_mul_ena_sig 			<= 2'b00;	
									
								//fir_indata_pop_sig      <= 1'b0;	
								fir_indata_rd_en_sig    	<= 1'b0;	
								fir_coeffdata_rd_en_sig 	<= 1'b0;
									
								fir_dat_addr_sig			<= 0;
								fir_coef_addr_sig   		<= 7'h00;
								sum_cnt_sig_index       	<= sum_cnt_sig_index;
																	
								sample_cnt 					<= 10'h000;
								tap_cnt_index 				<= 8'h00;
																		
								coeff_mult_count        	<= 0;	
								dat_load_seq_ctrl       	<= 0;	
								
								 fir_sum_done                <= 0;	
								
								odd_even_16_bit_write_marker <= odd_even_16_bit_write_marker;
							
							 end

							 
							 
		sFIR_LOAD_COEFF_DATA : begin
									if (tap_cnt_index==TAP_CNT)
									begin
										//fir_deci_data_sum_sig 	<= fir_deci_data_sum_sig[30:0] + {{1{fir_cmult_i[29]}}, fir_cmult_i[29:0]}; 
										fir_deci_data_sum_sig   <= fir_deci_data_sum_sig;
`ifdef SIM		
										sim_fir_deci_data_sum_sig <= sim_fir_deci_data_sum_sig;		
`endif											
										
										
										sum_cnt_sig_index 		<= sum_cnt_sig_index + 3;//calculate for every 3rd sample.
										tap_cnt_index 			<= 8'h00;
										
										fir_dat_addr_sig		<= fir_dat_addr_sig		;
										fir_coef_addr_sig   	<= fir_coef_addr_sig   	;
										
										fir_indata_rd_en_sig    <= 1'b0;//1'b1;	
										fir_coeffdata_rd_en_sig <= 1'b0;//1'b1;
										
										fir_mul_ena_sig 		<= 2'b00;
										dat_load_seq_ctrl  		<= 0;
										fir_deci_data_push_sig  <= 1'b0;
										 fir_sum_done                <= 1;	
										
										fir_deci_fsm  			<=  sFIR_FINAL_SUM;
									
									end
									else
									begin
									//Read Data from Memory
										
										case (dat_load_seq_ctrl)
										2'b00 :  begin
										
													fir_dat_addr_sig		<= sum_cnt_sig_index;	
													
													prev_fir_adr_msb        <= sum_cnt_sig_index[9];
													
													fir_coef_addr_sig   	<= tap_cnt_index; 
													
													fir_indata_rd_en_sig    <= 1'b1;	
										            fir_coeffdata_rd_en_sig <= 1'b1;		

													fir_mul_ena_sig 		<= 2'b00;
																																			
										            fir_dat_sig        <= 0;//fir_dat_sig;
													fir_coef_sig       <= 0;//fir_coef_sig;

                                                    laddr_thres_xed    <= 1'b0; 													
												
													dat_load_seq_ctrl  		<= dat_load_seq_ctrl + 1;
													fir_deci_fsm       		<= fir_deci_fsm;
												end
												
										2'b01 :  begin //Multiply Data * Coeff 
										
													if (tap_cnt_index == 0)
													begin
`ifdef SIVA_MOD
														fir_deci_data_sum_sig 	  <= 32'h4000;
`elsif ANAND_MOD														
														fir_deci_data_sum_sig 	  <= 0;
`else	
														fir_deci_data_sum_sig 	  <= 31'h0000;
`endif													
													
`ifdef SIM		
													    sim_fir_deci_data_sum_sig <= 0;		
`endif														
														
													end	
												
											
													
													fir_dat_addr_sig		<= fir_dat_addr_sig;	
													fir_coef_addr_sig   	<= tap_cnt_index;

                                                    //tap_cnt_index         <= tap_cnt_index;
                                                    tap_cnt_index           <= tap_cnt_index + 1;	//March 16,2018												
										
													fir_indata_rd_en_sig    <= 1'b0;//1'b1;	
										            fir_coeffdata_rd_en_sig <= 1'b1;
													
													fir_mul_ena_sig 		<= 2'b11;
													
													fir_coef_sig       <= fir_coeff_rd_data_sig;//fir_coef_sig;	
													
													dat_load_seq_ctrl  <= dat_load_seq_ctrl + 1;	
	
													fir_deci_fsm       <= fir_deci_fsm;			
												end		
												
										2'b10 :  begin
										
// Data Compute Section	/////////////									            
`ifdef SIVA_MOD
														fir_deci_data_sum_sig 	<= fir_deci_data_sum_sig + fir_cmult_i; 
`elsif ANAND_MOD
														fir_deci_data_sum_sig 	<= fir_deci_data_sum_sig + $signed({{2{fir_cmult_i[30]}}, fir_cmult_i[30:0]});//fir_cmult_i;
`else	
														fir_deci_data_sum_sig 	<= fir_deci_data_sum_sig[30:0] + {{1{fir_cmult_i[29]}}, fir_cmult_i[29:0]}; 
														//fir_deci_data_sum_sig 	<= fir_deci_data_sum_sig[30:0] + {{1{fir_cmult_sig_nedge[29]}}, fir_cmult_sig_nedge[29:0]}; 
`endif														

`ifdef SIM		
													sim_fir_deci_data_sum_sig <= sim_fir_deci_data_sum_sig + fir_cmult_i[30:0];		
`endif
/////////////////////////////////////
                                                    if ((fir_dat_addr_sig_mi_1[9:0] <= I2S_last_ram_addr_i) && (prev_fir_adr_msb==1'b1) || (fir_dat_addr_sig_mi_1[9]==1'b1 && (prev_fir_adr_msb==1'b0)))//Feb12
													begin
                                                         laddr_thres_xed <= 1'b1;

                                                    end													

`ifndef ADD_STATE_FOR_MUL_LATCH														
												    fir_dat_addr_sig		<= fir_dat_addr_sig_mi_1;//fir_dat_addr_sig - 1;
													//fir_coef_addr_sig   	<= fir_coef_addr_sig; //March16, 2018
													fir_coef_addr_sig   	<= tap_cnt_index; 
																				
													fir_indata_rd_en_sig    <= 1'b1;	
										            fir_coeffdata_rd_en_sig <= 1'b1;
													
										            fir_coef_sig       <= fir_coeff_rd_data_sig;//fir_coef_sig;
													//tap_cnt_index 		<= tap_cnt_index + 1;
													tap_cnt_index 		<= tap_cnt_index;//March 16
													if (I2S_last_ram_write_sync_firclk)//Maintain the condition of Overflow bit set as input zero data padding is done based on this at the end.
													begin
														sum_cnt_sig_index 	<= sum_cnt_sig_index;
													end
													else
													begin
														sum_cnt_sig_index 	<= {1'b0,sum_cnt_sig_index[8:0]};	
													end	
 
                                                    dat_load_seq_ctrl       <= 2'b01; 												
													
`else
												    fir_dat_addr_sig		<= fir_dat_addr_sig;//fir_dat_addr_sig - 1;
													fir_coef_addr_sig   	<= fir_coef_addr_sig; 
																				
													fir_indata_rd_en_sig    <= 1'b0;	
										            fir_coeffdata_rd_en_sig <= 1'b0;
													
										            fir_coef_sig            <= fir_coef_sig;
													tap_cnt_index 		    <= tap_cnt_index;
                                                    dat_load_seq_ctrl       <= dat_load_seq_ctrl + 1;	 													

`endif													
													fir_mul_ena_sig 		<= 2'b00;
													fir_deci_fsm            <= fir_deci_fsm;			
												end	
												
										2'b11 :  begin
												    fir_dat_addr_sig		<= fir_dat_addr_sig_mi_1;//fir_dat_addr_sig - 1;
													fir_coef_addr_sig   	<= fir_coef_addr_sig+1; 
																				
													fir_indata_rd_en_sig    <= 1'b1;	
										            fir_coeffdata_rd_en_sig <= 1'b1;
													
										            fir_coef_sig            <= fir_coeff_rd_data_sig;//fir_coef_sig;
													tap_cnt_index 		    <= tap_cnt_index + 1;
													if (I2S_last_ram_write_sync_firclk)//Maintain the condition of Overflow bit set as input zero data padding is done based on this at the end.
													begin
														sum_cnt_sig_index 	<= sum_cnt_sig_index;
													end
													else
													begin
														sum_cnt_sig_index 	<= {1'b0,sum_cnt_sig_index[8:0]};	
													end	
 
                                                    dat_load_seq_ctrl       <= 2'b01; 	
													
													fir_mul_ena_sig 		<= 2'b00;
													fir_deci_fsm            <= fir_deci_fsm;											

                                                 end										

	
										default :begin
                                                	//fir_deci_data_sum_sig 	<= 0; 
`ifdef SIVA_MOD
													fir_deci_data_sum_sig 	  <= 32'h4000;
`elsif ANAND_MOD												
													fir_deci_data_sum_sig 	  <= 0;
`else	
													fir_deci_data_sum_sig 	  <= 31'h0000;
`endif													
													
                                                    fir_dat_addr_sig		<= 0;	
                                                    fir_coef_addr_sig   	<= 0; 
                                                    
                                                    fir_indata_rd_en_sig    <= 1'b0;	
                                                    fir_coeffdata_rd_en_sig <= 1'b0;
                                                    
                                                    fir_mul_ena_sig 		<= 2'b00;
                                                    																				
                                                    fir_dat_sig        <= 0;
                                                    fir_coef_sig       <= 0;	
                                                    
                                                    dat_load_seq_ctrl  <= 0;	
                                                    
                                                    fir_deci_fsm       <= fir_deci_fsm;			

												end 
										endcase									
									end
								end


		sFIR_FINAL_SUM          :   begin
										fir_deci_data_push_sig 			<= 1'b1;
										fir_sum_done                    <= 1'b0;	
										odd_even_16_bit_write_marker 	<= ~odd_even_16_bit_write_marker;
                                        fir_deci_fsm            		<= sFIR_WT_I2S_3RDSAMP; 
                                    end		
								
        sFIR_WT_I2S_3RDSAMP		:   begin
										fir_deci_data_push_sig 	<= 1'b0;
										if (I2S_last_ram_write_sync_firclk)
										begin
										    fir_deci_fsm            <= sFIR_LOAD_COEFF_DATA;
										end
										else
										begin
											//if ((I2S_ram_data_cntr_mi_3==0 || I2S_ram_data_cntr_mi_3[2]==1'b1 ) && (I2S_ram_data_cntr_mi_3[3] == 1'b0))
											if (I2S_ram_data_cntr==3)
											begin
												fir_deci_fsm            <= sFIR_LOAD_COEFF_DATA;
											end
											else
											begin
												fir_deci_fsm            <= fir_deci_fsm;
											end
										end	

								    end

								   	
		endcase
	end				
end

//assign WBs_ACK_o_nxt                = WBs_CYC_i & WBs_STB_i & (~WBs_ACK_o);
//assign WBs_ACK_o					= WBs_ACK_coeff_adr;

//always @( posedge WBs_CLK_i or posedge WBs_RST_i)
//begin
//    if (WBs_RST_i)
//    begin
//	    WBs_ACK_coeff_adr <= 1'b0;
//	end
//	else
//	begin
//	    WBs_ACK_coeff_adr     <=  WBs_ACK_o_nxt;
//	end
//end	

//Coeff data is written to RAM for FIR decimation

r512x16_512x16 u_r512x16_512x16_FIR_COEFF_DATA (
								 .WA	  	( wb_Coeff_RAM_aDDR_i  ) 	,
								 .RA		( coef_ram_rd_addr_ptr )	,
								 .WD		( wb_Coeff_RAM_Data_i  )	,
								 .WD_SEL	( wb_Coeff_RAM_Wen_i  )	,
								 .RD_SEL	( 1'b1 )	,
								 .WClk		( WBs_CLK_i )	,
								 .RClk		( fir_clk_i )	,
								 .WClk_En	( 1'b1  )	,
								 .RClk_En	( 1'b1  )	,
								 .WEN		( {wb_Coeff_RAM_Wen_i,wb_Coeff_RAM_Wen_i}  )	,
								 .RD		( fir_coeff_rd_data_sig  )	,
								 .LS		( 1'b0  )	,
								 .DS		( 1'b0  )	,
								 .SD		( 1'b0  )	,
								 .LS_RB1	( 1'b0  )	,
								 .DS_RB1	( 1'b0  )	,
								 .SD_RB1    ( 1'b0  )
		

								);
			
								
//
//Fifo counter 


always @(posedge I2S_clk_i or posedge fir_reset_i)
begin
     if (fir_reset_i)
	 begin
	     i2s_wr_toggle <= 1'b0;
	 end
	 else
	 begin
	     if (I2S_ram_write_ena_i)//This signal's width should be I2S_clk_i period.
		 begin
			i2s_wr_toggle <= ~i2s_wr_toggle;
		 end
	 end
end

always @( posedge fir_clk_i or posedge fir_reset_i)
begin
     if (fir_reset_i)
	 begin
	     I2S_ram_write_ena_sync_firclk0 <= 1'b0;
	     I2S_ram_write_ena_sync_firclk1 <= 1'b0;
	     I2S_ram_write_ena_sync_firclk2 <= 1'b0;
	 
	 end
	 else
	 begin
		I2S_ram_write_ena_sync_firclk0  <= i2s_wr_toggle;	
		I2S_ram_write_ena_sync_firclk1  <= I2S_ram_write_ena_sync_firclk0;	
		I2S_ram_write_ena_sync_firclk2  <= I2S_ram_write_ena_sync_firclk1;	

     end
end

assign I2S_ram_write_ena_sync_firclk = (I2S_ram_write_ena_sync_firclk1 && ~I2S_ram_write_ena_sync_firclk2) || (~I2S_ram_write_ena_sync_firclk1 && I2S_ram_write_ena_sync_firclk2);
	
//assign fir_ram_rd_ena = ~fir_indata_rd_en_sig1 & fir_indata_rd_en_sig; 
//assign fir_ram_rd_ena = fir_deci_data_push_sig; 
assign fir_ram_rd_ena = fir_sum_done; 

assign fir_rst = fir_reset_i | deci_done ;
	
always @( posedge fir_clk_i or posedge fir_rst)
begin
     if (fir_rst)
	 begin
	    //I2S_ram_data_cntr  <= {3{1'b0}};
	    I2S_ram_data_cntr  <= 3'b010;//Start with 2 as the first calculation is done as soon as first sample is available. 
	 end
	 else
	 begin
	    if (I2S_ram_write_ena_sync_firclk==1'b1 && fir_ram_rd_ena ==1'b1)
		begin
			I2S_ram_data_cntr  <= I2S_ram_data_cntr;
		end	
		else if (I2S_ram_write_ena_sync_firclk==1'b1)
		begin
			I2S_ram_data_cntr  <= I2S_ram_data_cntr + 1;
		end
		else if (fir_ram_rd_ena==1'b1)
		begin
		    I2S_ram_data_cntr  <= I2S_ram_data_cntr - 3;//Decrement by 3 as the calculation is done for every third sample being written.
	    end
		else
		begin
			I2S_ram_data_cntr  <= I2S_ram_data_cntr;
	    end
	 end
end		


always @( posedge fir_clk_i or posedge fir_reset_i)
begin
     if (fir_reset_i)
	 begin
         fir_indata_rd_en_sig1 <= 1'b0;	 
     end
     else
	 begin
	     fir_indata_rd_en_sig1 <= fir_indata_rd_en_sig;
	 end
end



always @( posedge fir_clk_i or posedge fir_reset_i)
begin
     if (fir_reset_i)
	 begin
         I2S_last_ram_write_sync_firclk <= 1'b0;	 
     end
     else
	 begin
	     //if (I2S_last_ram_write_i==1'b1)
	     if (I2S_last_ram_write_i==1'b1 && & fir_deci_ena_i==1'b1)
		 begin
			I2S_last_ram_write_sync_firclk <= 1'b1;
		 end
         else if (deci_done)
         begin
			I2S_last_ram_write_sync_firclk <= 1'b0;
         end		 
	 end
end



//Stop the decimator after I2S data stops based on I2S_last_ram_write_i signal
always @( posedge fir_clk_i or posedge fir_reset_i)
begin
     if (fir_reset_i)
	 begin
         decimator_last_dat_cnt <= 0;
		 deci_done              <= 1'b0;
     end
     else
	 begin
         if (I2S_last_ram_write_sync_firclk)	
         begin
			 if (fir_deci_data_push_sig)
			 begin
				 decimator_last_dat_cnt <= decimator_last_dat_cnt + 1;	
			 end
         end
		 else
		 begin
				decimator_last_dat_cnt <= 0;
		 end

        if(decimator_last_dat_cnt==128)
		begin
			deci_done <= 1'b1; 
		end
		else
		begin
			deci_done <= 1'b0; 
		end  
     end
end



always @( posedge fir_clk_i or posedge fir_reset_i)
begin
     if (fir_reset_i)
	 begin
	    deci_done_r1 <= 1'b0;
	 
	 end
	 else
	 begin
		deci_done_r1 <= deci_done;
	 
     end
end

assign dummy_deci_data_push = dummy_deci_data_push_r1 & ~dummy_deci_data_push_r2;

always @( posedge fir_clk_i or posedge fir_reset_i)
begin
     if (fir_reset_i)
	 begin
	    dummy_deci_data_push_r1 <= 1'b0;
	    dummy_deci_data_push_r2 <= 1'b0;
	 
	 end
	 else
	 begin
	    if (odd_even_16_bit_write_marker & deci_done)//Only lower byte Pushed
		begin
			dummy_deci_data_push_r1 <= 1'b1;
			dummy_deci_data_push_r2 <= dummy_deci_data_push_r1;
		end
        else
        begin
			dummy_deci_data_push_r1 <= 1'b0;
			dummy_deci_data_push_r2 <= 1'b0;
        end		
	 
     end
end



always @( negedge fir_clk_i or posedge fir_reset_i)
begin
     if (fir_reset_i)
	 begin
	    fir_cmult_sig_nedge <= 0;

	 end
	 else
	 begin 
	     if (fir_mul_ena_sig)
			fir_cmult_sig_nedge <= fir_cmult_i;
     end
end




endmodule




  //Data to be Loaded in Coefficient memory.
  // parameter signed [15:0] coeff1 = 16'b0000000000000001; //sfix16_En15
  // parameter signed [15:0] coeff2 = 16'b1111111111111111; //sfix16_En15
  // parameter signed [15:0] coeff3 = 16'b1111111111111100; //sfix16_En15
  // parameter signed [15:0] coeff4 = 16'b1111111111111110; //sfix16_En15
  // parameter signed [15:0] coeff5 = 16'b0000000000000011; //sfix16_En15
  // parameter signed [15:0] coeff6 = 16'b0000000000000111; //sfix16_En15
  // parameter signed [15:0] coeff7 = 16'b0000000000000100; //sfix16_En15
  // parameter signed [15:0] coeff8 = 16'b1111111111111011; //sfix16_En15
  // parameter signed [15:0] coeff9 = 16'b1111111111110100; //sfix16_En15
  // parameter signed [15:0] coeff10 = 16'b1111111111111001; //sfix16_En15
  // parameter signed [15:0] coeff11 = 16'b0000000000001000; //sfix16_En15
  // parameter signed [15:0] coeff12 = 16'b0000000000010011; //sfix16_En15
  // parameter signed [15:0] coeff13 = 16'b0000000000001011; //sfix16_En15
  // parameter signed [15:0] coeff14 = 16'b1111111111110011; //sfix16_En15
  // parameter signed [15:0] coeff15 = 16'b1111111111100011; //sfix16_En15
  // parameter signed [15:0] coeff16 = 16'b1111111111101111; //sfix16_En15
  // parameter signed [15:0] coeff17 = 16'b0000000000010011; //sfix16_En15
  // parameter signed [15:0] coeff18 = 16'b0000000000101011; //sfix16_En15
  // parameter signed [15:0] coeff19 = 16'b0000000000011000; //sfix16_En15
  // parameter signed [15:0] coeff20 = 16'b1111111111100101; //sfix16_En15
  // parameter signed [15:0] coeff21 = 16'b1111111111000100; //sfix16_En15
  // parameter signed [15:0] coeff22 = 16'b1111111111011111; //sfix16_En15
  // parameter signed [15:0] coeff23 = 16'b0000000000100101; //sfix16_En15
  // parameter signed [15:0] coeff24 = 16'b0000000001010001; //sfix16_En15
  // parameter signed [15:0] coeff25 = 16'b0000000000101101; //sfix16_En15
  // parameter signed [15:0] coeff26 = 16'b1111111111001110; //sfix16_En15
  // parameter signed [15:0] coeff27 = 16'b1111111110010011; //sfix16_En15
  // parameter signed [15:0] coeff28 = 16'b1111111111000100; //sfix16_En15
  // parameter signed [15:0] coeff29 = 16'b0000000001000001; //sfix16_En15
  // parameter signed [15:0] coeff30 = 16'b0000000010001111; //sfix16_En15
  // parameter signed [15:0] coeff31 = 16'b0000000001001110; //sfix16_En15
  // parameter signed [15:0] coeff32 = 16'b1111111110101011; //sfix16_En15
  // parameter signed [15:0] coeff33 = 16'b1111111101000110; //sfix16_En15
  // parameter signed [15:0] coeff34 = 16'b1111111110011011; //sfix16_En15
  // parameter signed [15:0] coeff35 = 16'b0000000001101110; //sfix16_En15
  // parameter signed [15:0] coeff36 = 16'b0000000011101111; //sfix16_En15
  // parameter signed [15:0] coeff37 = 16'b0000000010000010; //sfix16_En15
  // parameter signed [15:0] coeff38 = 16'b1111111101110011; //sfix16_En15
  // parameter signed [15:0] coeff39 = 16'b1111111011001101; //sfix16_En15
  // parameter signed [15:0] coeff40 = 16'b1111111101011001; //sfix16_En15
  // parameter signed [15:0] coeff41 = 16'b0000000010110101; //sfix16_En15
  // parameter signed [15:0] coeff42 = 16'b0000000110001001; //sfix16_En15
  // parameter signed [15:0] coeff43 = 16'b0000000011010110; //sfix16_En15
  // parameter signed [15:0] coeff44 = 16'b1111111100010111; //sfix16_En15
  // parameter signed [15:0] coeff45 = 16'b1111111000000100; //sfix16_En15
  // parameter signed [15:0] coeff46 = 16'b1111111011101010; //sfix16_En15
  // parameter signed [15:0] coeff47 = 16'b0000000100110000; //sfix16_En15
  // parameter signed [15:0] coeff48 = 16'b0000001010011100; //sfix16_En15
  // parameter signed [15:0] coeff49 = 16'b0000000101110000; //sfix16_En15
  // parameter signed [15:0] coeff50 = 16'b1111111001101000; //sfix16_En15
  // parameter signed [15:0] coeff51 = 16'b1111110001110010; //sfix16_En15
  // parameter signed [15:0] coeff52 = 16'b1111111000000001; //sfix16_En15
  // parameter signed [15:0] coeff53 = 16'b0000001001000011; //sfix16_En15
  // parameter signed [15:0] coeff54 = 16'b0000010100110010; //sfix16_En15
  // parameter signed [15:0] coeff55 = 16'b0000001100001000; //sfix16_En15
  // parameter signed [15:0] coeff56 = 16'b1111110001100010; //sfix16_En15
  // parameter signed [15:0] coeff57 = 16'b1111011100010111; //sfix16_En15
  // parameter signed [15:0] coeff58 = 16'b1111101000111100; //sfix16_En15
  // parameter signed [15:0] coeff59 = 16'b0000100000011100; //sfix16_En15
  // parameter signed [15:0] coeff60 = 16'b0001101100011110; //sfix16_En15
  // parameter signed [15:0] coeff61 = 16'b0010100010111101; //sfix16_En15
  // parameter signed [15:0] coeff62 = 16'b0010100010111101; //sfix16_En15
  // parameter signed [15:0] coeff63 = 16'b0001101100011110; //sfix16_En15
  // parameter signed [15:0] coeff64 = 16'b0000100000011100; //sfix16_En15
  // parameter signed [15:0] coeff65 = 16'b1111101000111100; //sfix16_En15
  // parameter signed [15:0] coeff66 = 16'b1111011100010111; //sfix16_En15
  // parameter signed [15:0] coeff67 = 16'b1111110001100010; //sfix16_En15
  // parameter signed [15:0] coeff68 = 16'b0000001100001000; //sfix16_En15
  // parameter signed [15:0] coeff69 = 16'b0000010100110010; //sfix16_En15
  // parameter signed [15:0] coeff70 = 16'b0000001001000011; //sfix16_En15
  // parameter signed [15:0] coeff71 = 16'b1111111000000001; //sfix16_En15
  // parameter signed [15:0] coeff72 = 16'b1111110001110010; //sfix16_En15
  // parameter signed [15:0] coeff73 = 16'b1111111001101000; //sfix16_En15
  // parameter signed [15:0] coeff74 = 16'b0000000101110000; //sfix16_En15
  // parameter signed [15:0] coeff75 = 16'b0000001010011100; //sfix16_En15
  // parameter signed [15:0] coeff76 = 16'b0000000100110000; //sfix16_En15
  // parameter signed [15:0] coeff77 = 16'b1111111011101010; //sfix16_En15
  // parameter signed [15:0] coeff78 = 16'b1111111000000100; //sfix16_En15
  // parameter signed [15:0] coeff79 = 16'b1111111100010111; //sfix16_En15
  // parameter signed [15:0] coeff80 = 16'b0000000011010110; //sfix16_En15
  // parameter signed [15:0] coeff81 = 16'b0000000110001001; //sfix16_En15
  // parameter signed [15:0] coeff82 = 16'b0000000010110101; //sfix16_En15
  // parameter signed [15:0] coeff83 = 16'b1111111101011001; //sfix16_En15
  // parameter signed [15:0] coeff84 = 16'b1111111011001101; //sfix16_En15
  // parameter signed [15:0] coeff85 = 16'b1111111101110011; //sfix16_En15
  // parameter signed [15:0] coeff86 = 16'b0000000010000010; //sfix16_En15
  // parameter signed [15:0] coeff87 = 16'b0000000011101111; //sfix16_En15
  // parameter signed [15:0] coeff88 = 16'b0000000001101110; //sfix16_En15
  // parameter signed [15:0] coeff89 = 16'b1111111110011011; //sfix16_En15
  // parameter signed [15:0] coeff90 = 16'b1111111101000110; //sfix16_En15
  // parameter signed [15:0] coeff91 = 16'b1111111110101011; //sfix16_En15
  // parameter signed [15:0] coeff92 = 16'b0000000001001110; //sfix16_En15
  // parameter signed [15:0] coeff93 = 16'b0000000010001111; //sfix16_En15
  // parameter signed [15:0] coeff94 = 16'b0000000001000001; //sfix16_En15
  // parameter signed [15:0] coeff95 = 16'b1111111111000100; //sfix16_En15
  // parameter signed [15:0] coeff96 = 16'b1111111110010011; //sfix16_En15
  // parameter signed [15:0] coeff97 = 16'b1111111111001110; //sfix16_En15
  // parameter signed [15:0] coeff98 = 16'b0000000000101101; //sfix16_En15
  // parameter signed [15:0] coeff99 = 16'b0000000001010001; //sfix16_En15
  // parameter signed [15:0] coeff100 = 16'b0000000000100101; //sfix16_En15
  // parameter signed [15:0] coeff101 = 16'b1111111111011111; //sfix16_En15
  // parameter signed [15:0] coeff102 = 16'b1111111111000100; //sfix16_En15
  // parameter signed [15:0] coeff103 = 16'b1111111111100101; //sfix16_En15
  // parameter signed [15:0] coeff104 = 16'b0000000000011000; //sfix16_En15
  // parameter signed [15:0] coeff105 = 16'b0000000000101011; //sfix16_En15
  // parameter signed [15:0] coeff106 = 16'b0000000000010011; //sfix16_En15
  // parameter signed [15:0] coeff107 = 16'b1111111111101111; //sfix16_En15
  // parameter signed [15:0] coeff108 = 16'b1111111111100011; //sfix16_En15
  // parameter signed [15:0] coeff109 = 16'b1111111111110011; //sfix16_En15
  // parameter signed [15:0] coeff110 = 16'b0000000000001011; //sfix16_En15
  // parameter signed [15:0] coeff111 = 16'b0000000000010011; //sfix16_En15
  // parameter signed [15:0] coeff112 = 16'b0000000000001000; //sfix16_En15
  // parameter signed [15:0] coeff113 = 16'b1111111111111001; //sfix16_En15
  // parameter signed [15:0] coeff114 = 16'b1111111111110100; //sfix16_En15
  // parameter signed [15:0] coeff115 = 16'b1111111111111011; //sfix16_En15
  // parameter signed [15:0] coeff116 = 16'b0000000000000100; //sfix16_En15
  // parameter signed [15:0] coeff117 = 16'b0000000000000111; //sfix16_En15
  // parameter signed [15:0] coeff118 = 16'b0000000000000011; //sfix16_En15
  // parameter signed [15:0] coeff119 = 16'b1111111111111110; //sfix16_En15
  // parameter signed [15:0] coeff120 = 16'b1111111111111100; //sfix16_En15
  // parameter signed [15:0] coeff121 = 16'b1111111111111111; //sfix16_En15
  // parameter signed [15:0] coeff122 = 16'b0000000000000001; //sfix16_En15
  // parameter signed [15:0] coeff123 = 16'b0; //sfix16_En15
  // parameter signed [15:0] coeff124 = 16'b0; //sfix16_En15
  // parameter signed [15:0] coeff125 = 16'b0; //sfix16_En15
  // parameter signed [15:0] coeff126 = 16'b0; //sfix16_En15
  // parameter signed [15:0] coeff127 = 16'b0000000000000000; //sfix16_En15
  // parameter signed [15:0] coeff128 = 16'b0000000000000000; //sfix16_En15
  
  //Coeff data is written to RAM for FIR decimation-Old directly from Wishbone
//r512x16_512x16 u_r512x16_512x16_FIR_COEFF_DATA (
//								 .WA	  	( WBs_ADR_i[8:0]  ) 	,
//								 //.RA		( fir_coef_addr_sig )	,
//								 .RA		( coef_ram_rd_addr_ptr )	,
//								 .WD		( WBs_DAT_i[15:0]  )	,
//								 .WD_SEL	( WBs_WE_i  )	,
//								 .RD_SEL	( 1'b1 )	,
//								 .WClk		( WBs_CLK_i )	,
//								 .RClk		( fir_clk_i )	,
//								 .WClk_En	( 1'b1  )	,
//								 .RClk_En	( 1'b1  )	,
//								 .WEN		( WBs_WE_i  )	,
//								 .RD		( fir_coeff_rd_data_sig  )	,
//								 .LS		( 1'b0  )	,
//								 .DS		( 1'b0  )	,
//								 .SD		( 1'b0  )	,
//								 .LS_RB1	( 1'b0  )	,
//								 .DS_RB1	( 1'b0  )	,
//								 .SD_RB1    ( 1'b0  )
//		
//
//								);
