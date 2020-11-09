/*******************************************************************
 *
 *    FILE:         f_compute.v 
 *   
 *    DESCRIPTION:  f processing
 *
 *    HIERARCHY:   
 *
 *    AUTHOR:	    Anand A Wadke
 *
 *    HISTORY:
 *			        - 04/27/2018	Initial coding.
 *			
 *
 * Copyright (C) 2018, Licensed Customers of QuickLogic may copy and modify this
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
 * Date: April 27, 2018
 * Engineer: Anand Wadke
 * Revision: 1.0
 * 
 * 1. Initial Coding
 * 2. Input 1024 Data is considered to be real
 *******************************************************************/
`timescale 1ns/10ps
//`define SYNC_KOGG_STONE
//`define KOGG_STONE_M_1

module f_compute (
                                 f_clk_i,
								 f_reset_i,
								 f_ena_i,
								 
								 f_start_i,//From I2S block
								 
								 WBs_CLK_i,
								 WBs_RST_i,
								 
								 //f Data Ram interface-Real
								 f_real_dat_addr_o,								 								 
								 f_realindata_wr_en_o,								 								 
								 f_realindata_rd_en_o,								 							 
								 f_realdata_i,								 
								 f_realdata_o,
								 
								 //Coeff Ram Interface
								 wb_CosSin_RAM_aDDR_i,
								 wb_CosSin_RAM_Wen_i,
								 wb_CosSin_RAM_Data_i,	
								 wb_CosSin_RAM_Data_o,	
								 wb_CosSin_RAM_rd_access_ctrl_i,
								 
								 wb_L_f_Img_RAM_aDDR_i,	 
								 wb_L_f_Img_RAM_Data_o,	 
								 wb_L_f_Img_RAM_Wen_i,	 
								 wb_f_RAM_wr_rd_Mast_sel_i,
								 
							 
								 f_calc_done_o
								 
								 
								
								);
parameter                ADDRWIDTH                   =   9           ;
parameter                DATAWIDTH                   =  32           ;
	
parameter                STAGE_CNT_MAX 				 = 10;	
parameter                STAGE_CNT_MAX_M_1 			 = 9;	
								
input   		f_clk_i; 
input   		f_reset_i;
input   		f_ena_i;

input   		f_start_i;

input           WBs_CLK_i           ; // Fabric Clock               from Fabric
input           WBs_RST_i           ; // Fabric Reset               to   Fabric

output  [9:0] 	f_real_dat_addr_o; 
output  		f_realindata_wr_en_o;
output   		f_realindata_rd_en_o; 
input   [15:0]	f_realdata_i; 
output  [15:0]	f_realdata_o; 

input   [9:0]   wb_CosSin_RAM_aDDR_i;		
input 			wb_CosSin_RAM_Wen_i;
input   [31:0]  wb_CosSin_RAM_Data_i;
output  [31:0]  wb_CosSin_RAM_Data_o;
input 			wb_CosSin_RAM_rd_access_ctrl_i;

input  [9:0] 	wb_L_f_Img_RAM_aDDR_i;
output [15:0]   wb_L_f_Img_RAM_Data_o;
input 			wb_L_f_Img_RAM_Wen_i;
input			wb_f_RAM_wr_rd_Mast_sel_i;

output 			f_calc_done_o;

//1024*16 Imaginary Data Memory								
reg     [9:0] 	f_img_dat_addr_r;
reg  		    f_imgindata_wr_en_r;
//reg   		    f_imgindata_rd_en_r;	
reg     [15:0]	f_imgdata_i_r;
wire    [15:0]	f_img_data_o_w;	

//I2S RAM access section
reg     [9:0] 	f_real_dat_addr_r; 
reg  			f_realindata_wr_en_r;
reg   			f_realindata_rd_en_r; 
reg  	[15:0]	f_realdata_o_r;


wire    [15:0]	f_cos_rd_data_w;	
wire    [15:0]	f_sin_rd_data_w;	

reg    [15:0]	f_cos_rd_data_r;	
reg    [15:0]	f_sin_rd_data_r;	
					
reg     [8:0]	f_cos_addr_ptr;  
reg     [8:0]	f_sin_addr_ptr;  

wire    [8:0]   cos_ram_rd_addr_ptr;
wire    [8:0]   sin_ram_rd_addr_ptr;


reg 	   		f_done;
wire 	   		f_reset;


wire 	[1:0]	wen_cos;
wire 			wd_sel_cos;
wire 	[1:0]	wen_sin;
wire 			wd_sel_sin;
								
//f FSM
reg 	[3:0]   f_fsm;

parameter sf_IDLE								= 4'b0000;
parameter sf_STG_LOOP_CTRL                    = 4'b0001;
parameter sf_CALL_bfly_LOOP_CTRL_PER_STG = 4'b0010;
parameter sf_CALL_bfly_TOP_LOOP          = 4'b0011; 
parameter sf_CALL_bfly                   = 4'b0100; 

//Sub FSM
reg 	[3:0]   r2_buttfly_call_fsm;

parameter s_r2_INIT_ADDR_IDX_0					= 4'b0000;
parameter s_r2_INIT_ADDR_IDX_1          		= 4'b0001;
parameter s_r2_FETCH_P_Q_DAT_0          		= 4'b0010;
parameter s_r2_FETCH_P_Q_DAT_1          		= 4'b0011;
parameter s_r2_wt_R2BUTTFLY_COMP        		= 4'b0100;
parameter s_r2_STR_R2BUTTFLY_DATA_0     		= 4'b0101;
parameter s_r2_STR_R2BUTTFLY_DATA_1     		= 4'b0110;


//
assign 		f_real_dat_addr_o		=	f_real_dat_addr_r; 
assign 		f_realindata_wr_en_o	= 	f_realindata_wr_en_r;
assign 		f_realindata_rd_en_o	= 	f_realindata_rd_en_r; 
assign 		f_realdata_o			= 	f_realdata_o_r;

assign f_reset         = f_reset_i;

parameter  f_LENGTH = 1024;

//reg    [9:0] buttfly_calc_stride;

reg    [9:0] p_stage_idx;
reg    [9:0] loopcnt;

reg    [9:0] P_ADR_idx;
reg    [9:0] Q_ADR_idx;

reg 		 ena_rad2_butfly_r;

reg    [15:0]	P_real_dat_r	;
reg    [15:0]	P_img_dat_r	    ;
reg    [15:0]	Q_real_dat_r	;
reg    [15:0]	Q_img_dat_r	    ;


wire    [15:0]	P_plus_WnQ_real_w	; 
wire    [15:0]	P_plus_WnQ_img_w	;
wire    [15:0]	P_minus_WnQ_real_w  ;
wire    [15:0]	P_minus_WnQ_img_w	;

//wire    [8:0]   loopcnt_minus_1_w;

reg     [1:0]   loop_ctrl_st_sel;

reg     [9:0]   loopcnt_idx;//i
//reg     [3:0]   rem_stg_idx_cntr;
reg     [3:0]   rem_stg_idx_shfter;
wire    [3:0]   rem_stg_idx_w;
reg     [9:0]   loopcnt_idx_mul_2expk;

reg     [3:0]   stg_cnt_idx;
reg     [3:0]   stg_cnt_shfter;
reg     [1:0]   stg_ctrl_st_sel;

reg     [9:0]   buttfly_stride;

wire            bfly_done_w;

wire [9:0]      f_img_addr_mux_sig;
wire [15:0]     f_img_data_mux_sig;
wire            f_img_wen_mux_sig;

assign  rem_stg_idx_w  = STAGE_CNT_MAX_M_1 - stg_cnt_idx;

assign  f_calc_done_o = f_done;

//assign  loopcnt_minus_1_w = loopcnt - 1;


always @(posedge f_clk_i or posedge f_reset)			
begin
	if (f_reset == 1'b1)
	begin
        //buttfly_calc_stride  <= 0; 
		
		r2_buttfly_call_fsm  <= s_r2_INIT_ADDR_IDX_0;
		p_stage_idx          <= 0;
		loopcnt              <= 1;
		P_ADR_idx            <= 0;
		Q_ADR_idx            <= 0;
		ena_rad2_butfly_r    <= 0;
		P_real_dat_r	     <= 0;
		P_img_dat_r	         <= 0;
		Q_real_dat_r	     <= 0;
		Q_img_dat_r	         <= 0;
		f_real_dat_addr_r  <= 0;
		f_img_dat_addr_r   <= 0;
		f_realindata_wr_en_r   <= 0;
		f_imgindata_wr_en_r   <= 0;
		f_realindata_rd_en_r   <= 0;
		f_realdata_o_r        <= 0;
		f_imgdata_i_r         <= 0;
		buttfly_stride          <= 0;
		loop_ctrl_st_sel        <= 0;
		loopcnt_idx     	    <= 0;
		
		//rem_stg_idx_cntr  	    <= 0;
		rem_stg_idx_shfter  	<= 0;
		loopcnt_idx_mul_2expk   <= 0;
		f_cos_rd_data_r       <= 0; 
		f_sin_rd_data_r       <= 0;
		stg_ctrl_st_sel         <= 0;
		stg_cnt_idx           	<= 0;
		stg_cnt_shfter         	<= 0;
		
		f_cos_addr_ptr  		<= 0;
		f_sin_addr_ptr  		<= 0;
		
		f_done         	    <= 0;
		
		f_fsm              <= sf_IDLE;
	end
	else
	begin
		case (f_fsm)
			sf_IDLE : begin
								if (f_ena_i)
								begin
                                    if (f_start_i==1)
									begin
										f_fsm        <= sf_STG_LOOP_CTRL;
									end
                                    else
                                    begin
									    f_fsm        <= f_fsm;
                                    end									
								end
								else
								begin
					    		    f_fsm             <= sf_IDLE;
								end
								
								r2_buttfly_call_fsm     <= s_r2_INIT_ADDR_IDX_0;
								P_ADR_idx            	<= 0;
								Q_ADR_idx            	<= 0;
								p_stage_idx          	<= 0;
								loopcnt           	    <= 1;								
								ena_rad2_butfly_r    	<= 0;
								f_real_dat_addr_r  	<= 0;
                                f_img_dat_addr_r   	<= 0;
								P_real_dat_r 		 	<= 0;
								P_img_dat_r          	<= 0;
								Q_real_dat_r 		 	<= 0;
								Q_img_dat_r          	<= 0;
								f_realindata_wr_en_r  <= 0;
								f_imgindata_wr_en_r  <= 0;
								f_realindata_rd_en_r  <= 0;
								f_realdata_o_r        <= 0;
								f_imgdata_i_r         <= 0;
								buttfly_stride          <= 0;
								loop_ctrl_st_sel         <= 0;
								loopcnt_idx     		 <= 0;
								rem_stg_idx_shfter      <= 0;	
								loopcnt_idx_mul_2expk    <= 0;	
                                f_cos_rd_data_r       <= 0; 								
								f_sin_rd_data_r       <= 0;
								stg_ctrl_st_sel         <= 0;	
								stg_cnt_idx           	<= 0;
								stg_cnt_shfter         	<= 0;
                                f_done         	    <= 0; 
                            	
							 end
							 
			sf_STG_LOOP_CTRL:					 
							 begin
							       if (stg_cnt_idx==STAGE_CNT_MAX)
								   begin
								       f_fsm     <=    sf_IDLE;
									   f_done    <=    1;
								   end
							       else
								   begin
								       case(stg_ctrl_st_sel)
									   
									   2'b00 : begin
													stg_cnt_shfter  <= stg_cnt_idx;
													stg_ctrl_st_sel <= 1;
										            loopcnt         <= 1;
										            buttfly_stride  <= 0;
									   
									           end
									   
									   2'b01 : begin//calculate loop_count from matlab file *_1024.m  
									                //Shift loopcnt_idx based on stage count
													if (stg_cnt_shfter==0)
													begin
														stg_cnt_shfter      	<= stg_cnt_shfter; 
														stg_ctrl_st_sel 		<= 0;
													    loopcnt   				<= loopcnt; 
														buttfly_stride          <= loopcnt << 1;
														
														stg_cnt_idx             <= stg_cnt_idx + 1;
														
														f_fsm                 <= sf_CALL_bfly_LOOP_CTRL_PER_STG;
													end
													else
													begin
														stg_cnt_shfter      	<= stg_cnt_shfter-1;
														stg_ctrl_st_sel 		<= 1;
														loopcnt   				<= loopcnt << 1; //loop_count = 2^stage_count; 
													end	
									           end

							           endcase
							       end
							 end
							 
			sf_CALL_bfly_LOOP_CTRL_PER_STG :		
                             begin
							      //if (loopcnt_idx==loopcnt_minus_1_w)
							      if (loopcnt_idx==loopcnt)
								  begin
								  
								       f_fsm     <=    sf_STG_LOOP_CTRL;
								  end
								  else
								  begin
								  
								      case(loop_ctrl_st_sel)
								  
								      2'b00 : begin //rem_stg_idx_shfter=k
									                rem_stg_idx_shfter       <= rem_stg_idx_w;
													loop_ctrl_st_sel 		 <= 1;
													loopcnt_idx_mul_2expk    <= loopcnt_idx;
											  end
								  
								      2'b01 : begin //calculate j from matlab file *_1024.m  
									                //Shift loopcnt_idx based on remaining stage IDX rem_stg_idx_shfter
													
													if (rem_stg_idx_shfter==0)
													begin
														rem_stg_idx_shfter      <= rem_stg_idx_w; 
														loop_ctrl_st_sel 		<= 2;
													    loopcnt_idx_mul_2expk   <= loopcnt_idx_mul_2expk + 1; //j2 = j + 1;
													end
													else
													begin
														rem_stg_idx_shfter      <= rem_stg_idx_shfter-1;
														loop_ctrl_st_sel 		<= 1;
														loopcnt_idx_mul_2expk   <= loopcnt_idx_mul_2expk << 1; //j = i * 2^k; 
													end	
											  end

								      2'b10 : begin //Generate Cos and Sin Address
														loopcnt_idx_mul_2expk 	<= loopcnt_idx_mul_2expk;
														loop_ctrl_st_sel 		<= 3; 
													
														f_cos_addr_ptr  		<= loopcnt_idx_mul_2expk;
														f_sin_addr_ptr  		<= loopcnt_idx_mul_2expk;
														
											  end	

								      2'b11 : begin //Fetch Cos and Sin Data
														loopcnt_idx_mul_2expk 	<= loopcnt_idx_mul_2expk;
														loop_ctrl_st_sel 		<= 0; 
														
														f_cos_rd_data_r       <= f_cos_rd_data_w;
														f_sin_rd_data_r       <= f_sin_rd_data_w;
														
														loopcnt_idx             <= loopcnt_idx + 1;
														
														f_fsm                 <= sf_CALL_bfly_TOP_LOOP;  
									  
											  end
                                      endcase											  
			                    end
							 end
							
            sf_CALL_bfly_TOP_LOOP : 
							begin
                                                if (p_stage_idx==f_LENGTH-1)
												begin
												    p_stage_idx <= 0;
												    f_fsm     <= sf_CALL_bfly_LOOP_CTRL_PER_STG;  
												end
												else
												begin
			                                        p_stage_idx <=  p_stage_idx; 
							                        f_fsm     <=  sf_CALL_bfly;
											    end 	
							end
			sf_CALL_bfly : begin

										case (r2_buttfly_call_fsm)
										
										s_r2_INIT_ADDR_IDX_0 : begin
										//p_stage_idx          ;
										                            //loopcnt           ;
																	P_ADR_idx            <= p_stage_idx + 1;
																    Q_ADR_idx            <= 0;
																	
																	r2_buttfly_call_fsm  <= s_r2_INIT_ADDR_IDX_1;
										                       end
															   
										s_r2_INIT_ADDR_IDX_1 : begin
																	P_ADR_idx            <= P_ADR_idx;
																    Q_ADR_idx            <= P_ADR_idx + loopcnt;
																	
																	r2_buttfly_call_fsm  <= s_r2_FETCH_P_Q_DAT_0;
										                       end 
															   
										s_r2_FETCH_P_Q_DAT_0   : begin
										                            //Drive Address for Real and img RAM data here-P Data
																	f_real_dat_addr_r  <= P_ADR_idx;
										                            f_img_dat_addr_r   <= P_ADR_idx;
																	
										                            f_realindata_rd_en_r   <= 1'b1;
																	
                                                                    P_real_dat_r 		<= 0;
																	P_img_dat_r         <= 0;
																	Q_real_dat_r 		<= 0;
																	Q_img_dat_r         <= 0;

																	r2_buttfly_call_fsm  <= s_r2_FETCH_P_Q_DAT_1;
															   end
															   
										s_r2_FETCH_P_Q_DAT_1   : begin
										                            //Drive Address for Real and img RAM data. Fetch Real and img RAM data here
																	f_real_dat_addr_r  <= Q_ADR_idx;
										                            f_img_dat_addr_r   <= Q_ADR_idx;																	
																	
																	P_real_dat_r 		<= f_realdata_i;
										                            P_img_dat_r         <= f_img_data_o_w; 
																	Q_real_dat_r 		<= 0;
																	Q_img_dat_r         <= 0;
										
                                                                    ena_rad2_butfly_r    <= 1;
																	r2_buttfly_call_fsm  <= s_r2_wt_R2BUTTFLY_COMP;
															   end															   

																			
			                            s_r2_wt_R2BUTTFLY_COMP    : begin
										
										                               if (bfly_done_w==1'b1)
																	   begin
																	        //Computation done
																	   
																	        ena_rad2_butfly_r    <= 0;
																	        r2_buttfly_call_fsm  <= s_r2_STR_R2BUTTFLY_DATA_0;
																	   end
																	   else
																	   begin
																	       //wait
																			P_real_dat_r 		<= P_real_dat_r;
																			P_img_dat_r         <= P_img_dat_r; 
																			Q_real_dat_r 		<= f_realdata_i;
																			Q_img_dat_r         <= f_img_data_o_w; 
																			
																			f_realindata_rd_en_r   <= 1'b0;
																			
																			ena_rad2_butfly_r   <= 1;
																	
										                                  r2_buttfly_call_fsm  <= r2_buttfly_call_fsm;
										                               end
																	end
																	
										s_r2_STR_R2BUTTFLY_DATA_0    : begin
																		    f_real_dat_addr_r  <= Q_ADR_idx;	
										                                    f_img_dat_addr_r   <= Q_ADR_idx;
																			
																			f_realdata_o_r     <= P_minus_WnQ_real_w;
																			f_imgdata_i_r      <= P_minus_WnQ_img_w;
										
										                                    f_realindata_wr_en_r   <= 1;
										                                    f_imgindata_wr_en_r    <= 1;
								                                            r2_buttfly_call_fsm  <= s_r2_STR_R2BUTTFLY_DATA_1;

                                                                     end	

										s_r2_STR_R2BUTTFLY_DATA_1    : begin 
																		    f_real_dat_addr_r  <= P_ADR_idx;	
										                                    f_img_dat_addr_r   <= P_ADR_idx;
																			
																			f_realdata_o_r     <= P_plus_WnQ_real_w;
																			f_imgdata_i_r      <= P_plus_WnQ_img_w;
										
										                                    f_realindata_wr_en_r   <= 1;
										                                    f_imgindata_wr_en_r   <= 1;
								                                            r2_buttfly_call_fsm  <= s_r2_INIT_ADDR_IDX_0;
																			
																			p_stage_idx          <=  p_stage_idx + buttfly_stride; 
																			
																			f_fsm              <= sf_CALL_bfly_TOP_LOOP;//Change FSM state here;

                                                                     end
																	 
			
   							 
							 
							           endcase 
                                 end							 


								   	
		endcase
	end				
end

//Instantiate r2 bfly compute block
r2_bfly r2_bfly_inst0 (
                            .clk_i		( f_clk_i		),
							.rst_i		( f_reset_i	),
							
							.ena_rad2_butfly_i	(  ena_rad2_butfly_r),
							
							.P_real_i	( P_real_dat_r	),							 
                            .P_img_i	( P_img_dat_r	),							 
                            .Q_real_i	( Q_real_dat_r	),							 
                            .Q_img_i	( Q_img_dat_r	),
                            
							.cos_i		( f_cos_rd_data_r	),
							.sin_i		( f_sin_rd_data_r	),
							
							.P_plus_WnQ_real_o	( P_plus_WnQ_real_w		),
							.P_plus_WnQ_img_o	( P_plus_WnQ_img_w		),
							.P_minus_WnQ_real_o	( P_minus_WnQ_real_w		),
							.P_minus_WnQ_img_o	( P_minus_WnQ_img_w		),
							
							.bfly_done_o (bfly_done_w)
							
	
						 );




//assign  wb_CosSin_RAM_Data_o  = (wb_CosSin_RAM_aDDR_i[9]) ? f_sin_rd_data_w : f_cos_rd_data_w;
assign  wb_CosSin_RAM_Data_o  =  {f_cos_rd_data_w,f_sin_rd_data_w};

assign cos_ram_rd_addr_ptr 	= (wb_CosSin_RAM_rd_access_ctrl_i==1'b1)? wb_CosSin_RAM_aDDR_i : f_cos_addr_ptr;
assign sin_ram_rd_addr_ptr 	= (wb_CosSin_RAM_rd_access_ctrl_i==1'b1)? wb_CosSin_RAM_aDDR_i : f_sin_addr_ptr;
assign wd_sel_cos 			= wb_CosSin_RAM_Wen_i; //& ~wb_CosSin_RAM_aDDR_i[9];
assign wd_sel_sin 			= wb_CosSin_RAM_Wen_i; //& wb_CosSin_RAM_aDDR_i[9];

assign wen_cos 				= {wb_CosSin_RAM_Wen_i,wb_CosSin_RAM_Wen_i} ;//& {~wb_CosSin_RAM_aDDR_i[9],~wb_CosSin_RAM_aDDR_i[9]};
assign wen_sin 				= {wb_CosSin_RAM_Wen_i,wb_CosSin_RAM_Wen_i} ;//& {wb_CosSin_RAM_aDDR_i[9],wb_CosSin_RAM_aDDR_i[9]};
//COS/SIN data is written to RAM for f bfly computations
r512x16_512x16 u_r512x16_512x16_f_COS_DATA (
								 .WA	  	( wb_CosSin_RAM_aDDR_i[8:0]  ) 	,
								 .RA		( cos_ram_rd_addr_ptr )	,
								 .WD		( wb_CosSin_RAM_Data_i[31:16]  )	,
								 .WD_SEL	( wd_sel_cos ), 
								 .RD_SEL	( 1'b1 )	,
								 .WClk		( WBs_CLK_i )	,
								 .RClk		( f_clk_i )	,
								 .WClk_En	( 1'b1  )	,
								 .RClk_En	( 1'b1  )	,
								 .WEN		( wen_cos ),
								 .RD		( f_cos_rd_data_w  )	,
								 .LS		( 1'b0  )	,
								 .DS		( 1'b0  )	,
								 .SD		( 1'b0  )	,
								 .LS_RB1	( 1'b0  )	,
								 .DS_RB1	( 1'b0  )	,
								 .SD_RB1    ( 1'b0  )
		

								);

r512x16_512x16 u_r512x16_512x16_f_SIN_DATA (
								 .WA	  	( wb_CosSin_RAM_aDDR_i[8:0]  ) 	,
								 .RA		( sin_ram_rd_addr_ptr )	,
								 .WD		( wb_CosSin_RAM_Data_i[15:0]  )	,
								 .WD_SEL	( wd_sel_sin ), 
								 .RD_SEL	( 1'b1 )	,
								 .WClk		( WBs_CLK_i )	,
								 .RClk		( f_clk_i )	,
								 .WClk_En	( 1'b1  )	,
								 .RClk_En	( 1'b1  )	,
								 .WEN		( wen_sin ),
								 .RD		( f_sin_rd_data_w  )	,
								 .LS		( 1'b0  )	,
								 .DS		( 1'b0  )	,
								 .SD		( 1'b0  )	,
								 .LS_RB1	( 1'b0  )	,
								 .DS_RB1	( 1'b0  )	,
								 .SD_RB1    ( 1'b0  )
		

								);


assign wb_L_f_Img_RAM_Data_o = f_img_data_o_w;							
							
assign f_img_addr_mux_sig 	= (wb_f_RAM_wr_rd_Mast_sel_i) ? wb_L_f_Img_RAM_aDDR_i : f_img_dat_addr_r ;
assign f_img_data_mux_sig 	= (wb_f_RAM_wr_rd_Mast_sel_i) ? 15'h00 				  : f_imgdata_i_r;
assign f_img_wen_mux_sig 	    = (wb_f_RAM_wr_rd_Mast_sel_i) ? wb_L_f_Img_RAM_Wen_i  : f_imgindata_wr_en_r ;

								
//Img_Data_storage
r1024x16_1024x16 u_r1024x16_1024x16_I2S_FIR_URAM_DATA (
								 .WA	  	( f_img_addr_mux_sig ),//(f_img_dat_addr_r), 
								 .RA		( f_img_addr_mux_sig ),//(f_img_dat_addr_r ),
								 
								 .WD		( f_img_data_mux_sig ),//( f_imgdata_i_r ), 
								 .WD_SEL	( f_img_wen_mux_sig ),//( f_imgindata_wr_en_r ),
								 .RD_SEL	( 1'b1 ),//f_imgindata_rd_en_r
								 .WClk		( WBs_CLK_i),
								 .RClk		( WBs_CLK_i ),
								 .WClk_En	( 1'b1  )	,
								 .RClk_En	( 1'b1  )	,
								 .WEN		( {f_img_wen_mux_sig,f_img_wen_mux_sig} ),//( {f_imgindata_wr_en_r,f_imgindata_wr_en_r} ),
								 .RD		( f_img_data_o_w  ),
								 .LS		( 1'b0  )	,
								 .DS		( 1'b0  )	,
								 .SD		( 1'b0  )	,
								 .LS_RB1	( 1'b0  )	,
								 .DS_RB1	( 1'b0  )	,
								 .SD_RB1    ( 1'b0  )

								);									



endmodule




 