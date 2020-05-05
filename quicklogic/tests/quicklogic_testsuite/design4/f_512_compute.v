/*******************************************************************
 *
 *    FILE:         f_1024_compute.v 
 *   
 *    DESCRIPTION:  512 Tap f processing
 *
 *    HIERARCHY:   
 *
 *    AUTHOR:	    Anand A Wadke
 *
 *    HISTORY:
 *			        - 12/30/2018	Initial coding.
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
 * Date: December 30, 2018
 * Engineer: Anand Wadke
 * Revision: 1.0
 * 
 * 1. Initial Coding
 * 2. Input 512 Data is considered to be real
 *******************************************************************/
`timescale 1ns/10ps
//`define SIM

module f_512_compute (
                                 f_clk_i,
								 f_reset_i,
								 f_ena_i,
								 
								 f_start_i,
								 
								 WBs_CLK_i,
								// WBs_RST_i,
								 
								 stage_cnt_i,
								 f_point_i,
								 ena_perstgscale_i,
								 
								 ena_bit_rev_i,
								 
				 
								 //Coeff Ram Interface
								 wb_CosSin_RAM_aDDR_i,
								 wb_CosSin_RAM_Wen_i,
								 wb_CosSin_RAM_Data_i,	
								 wb_CosSin_RAM_Data_o,	
								 //wb_CosSin_RAM_rd_access_ctrl,
								 
								 wb_f_realImg_RAM_aDDR_i,	 
								 wb_f_realImg_RAM_Data_o,	 
								 wb_f_real_RAM_Data_i,	 
								 wb_f_realImg_RAM_Wen_i,	 
								 //wb_f_RAM_wr_rd_Mast_sel,
								 wb_f_realimgbar_ram_rd_switch_i,
								 
								 f_calc_done_o,
								 f_busy_o
								 
								 
								
								);
parameter                f_MEM_ADDRWIDTH           =   9           ;
parameter                f_MEM_DATAWIDTH           =  32           ;
parameter                f_COEFWIDTH                   =  16           ;
	
parameter                STAGE_CNT_MAX 				 = 10;	
parameter                STAGE_CNT_MAX_M_1 			 = 9;	
								
input   		f_clk_i; 
input   		f_reset_i;
input   		f_ena_i;

input   		f_start_i;

input           WBs_CLK_i           ; // Fabric Clock               from Fabric
//input           WBs_RST_i           ; // Fabric Reset               to   Fabric

input	[3:0]		  stage_cnt_i;
input   [9:0]         f_point_i;
input			      ena_perstgscale_i;
input			      ena_bit_rev_i;

input   [f_MEM_ADDRWIDTH-1:0]   	wb_CosSin_RAM_aDDR_i;		
input 								wb_CosSin_RAM_Wen_i;
input   [f_MEM_DATAWIDTH-1:0] 	wb_CosSin_RAM_Data_i;
output  [f_MEM_DATAWIDTH-1:0]  	wb_CosSin_RAM_Data_o;
//input 								wb_CosSin_RAM_rd_access_ctrl;


input  [f_MEM_ADDRWIDTH-1:0] 	    wb_f_realImg_RAM_aDDR_i;
output [f_MEM_DATAWIDTH-1:0]      wb_f_realImg_RAM_Data_o;
input  [f_MEM_DATAWIDTH-1:0]      wb_f_real_RAM_Data_i;
input 								wb_f_realImg_RAM_Wen_i;
//input								wb_f_RAM_wr_rd_Mast_sel;
input								wb_f_realimgbar_ram_rd_switch_i;

output 								f_calc_done_o;
output 								f_busy_o;


//Multiplier
wire 		[f_MEM_DATAWIDTH-1:0]		f_mul1_a_sig		;	
wire 		[f_MEM_DATAWIDTH-1:0]		f_mul1_b_sig	    ;
wire 		[f_MEM_DATAWIDTH*2-1:0]	f_mul1_c_sig      ;
wire 							     	f_mul1_ena_sig    ;
wire 		[f_MEM_DATAWIDTH-1:0]	    f_mul2_a_sig	    ;
wire 		[f_MEM_DATAWIDTH-1:0]    	f_mul2_b_sig	    ;
wire 		[f_MEM_DATAWIDTH*2-1:0]  	f_mul2_c_sig      ;
wire 							     	f_mul2_ena_sig    ;

wire 		[f_MEM_DATAWIDTH-1:0]		mul1_a_sig		;	
wire 		[f_MEM_DATAWIDTH-1:0]		mul1_b_sig	    ;
wire 		[f_MEM_DATAWIDTH*2-1:0]	mul1_c_sig      ;
wire 							     	mul1_ena_sig    ;

reg     	[9:0]   loopcnt_idx;
reg     	[8:0]   tworaise2k;

wire       [15:0]						f_cos_rd_data_w;	
wire       [15:0]						f_sin_rd_data_w;	

wire 									wb_CosSin_RAM_rd_access_ctrl;
wire 									wb_f_RAM_wr_rd_Mast_sel;
//reg    [15:0]	f_cos_rd_data_r;	
//reg    [15:0]	f_sin_rd_data_r;	
					
 

wire    [8:0]   cos_ram_rd_addr_ptr;
wire    [8:0]   sin_ram_rd_addr_ptr;	
wire    [1:0] 	wen_cos;
wire    [1:0] 	wen_sin;


wire [f_MEM_DATAWIDTH-1:0]     f_real_data_mux_sig;
wire [f_MEM_DATAWIDTH-1:0]     f_img_data_mux_sig;
wire [f_MEM_ADDRWIDTH-1:0]     f_realimg_waddr_mux_sig;
wire [f_MEM_ADDRWIDTH-1:0]     f_realimg_raddr_mux_sig;
wire            				 f_realimg_wen_mux_sig;


wire [f_MEM_DATAWIDTH-1:0] 		fram_real_rdata;   		
wire [f_MEM_DATAWIDTH-1:0] 		fram_img_rdata;      		
wire [f_MEM_DATAWIDTH-1:0] 		fram_real_wdata;     		
wire [f_MEM_DATAWIDTH-1:0] 		fram_img_wdata;      		
wire [f_MEM_ADDRWIDTH-1:0] 		fram_realimg_raddr;		
wire [f_MEM_ADDRWIDTH-1:0] 		fram_realimg_waddr;		
wire 								fram_realimg_wr;  

reg 	   				f_done;
reg 	   				f_busy;
//reg 	   				f_start;
//reg    [8:0]    		p_stage_idx;
wire   [9:0]    		p_stage_idx_w;
wire   [9:0]    		p_stage_idx_bfcalc_o;
reg    [9:0] 			loopcnt;
//reg    [9:0] 			loopcnt_pls_1;
reg 		 			ena_rad2_butfly_r;
reg     [9:0]   		buttfly_stride;
reg     [1:0]   		loop_ctrl_st_sel;
//reg     [9:0]   		loopcnt_idx;
//reg     [3:0]   		rem_stg_idx_shfter;
wire    [3:0]   		rem_stg_idx_w;
reg     [9:0]   		loopcnt_idx_x_tworaise2k;
//reg     [1:0]   		stg_ctrl_st_sel;
reg     [3:0]   		stg_cnt_idx;
//reg     [3:0]   		stg_cnt_shfter;
wire    [8:0]	        f_cos_addr_ptr;  
wire    [8:0]	        f_sin_addr_ptr; 

//reg     [8:0]           rem_stg_idx;

wire    [3:0]           stage_cnt_m1;   

//wire            		bfly_done_w;

//f FSM
reg 	[3:0]   f_fsm;
wire     [2:0]   bf_pipleline_tracker; 
//wire 			bfly_busy;

wire	wd_sel_cos;
wire	wd_sel_sin;  
wire	scale_last_stg_i;
wire	last_stg_i;

parameter 		sf_IDLE							  = 4'b0000;
parameter 		sf_STG_LOOP_CTRL                    = 4'b0001;
parameter 		sf_CALL_BFLY_PER_STG 				  = 4'b0010;
parameter 		sf_CALL_bfly_TOP_LOOP          = 4'b0011; 
parameter 		sf_CALL_bfly                   = 4'b0100; 


assign 	        mul1_a_sig		=  (ena_rad2_butfly_r) ? f_mul1_a_sig : {24'h0,loopcnt_idx};	
assign 	        mul1_b_sig	    =  (ena_rad2_butfly_r) ? f_mul1_b_sig : {24'h0,tworaise2k};	
assign 	        mul1_ena_sig    =  1'b1;//SPDE doesn't support Valid Bit control currently.

assign          f_mul1_c_sig  =  mul1_c_sig;

assign          f_calc_done_o = f_done;
assign          f_busy_o      = f_busy | f_start_i;
assign  		rem_stg_idx_w   = stage_cnt_m1 - stg_cnt_idx;//k in matlab code
assign  		stage_cnt_m1    = stage_cnt_i - 1;
//assign  		loopcnt_pls_1   = loopcnt + 1;

assign          f_cos_addr_ptr = loopcnt_idx_x_tworaise2k;
assign          f_sin_addr_ptr = loopcnt_idx_x_tworaise2k;

assign          p_stage_idx_w    = loopcnt_idx;


`ifdef SIM
reg sim_stg0_done;
reg sim_stg1_done;
reg sim_stg2_done;
reg sim_stg3_done;
reg sim_stg4_done;
reg sim_stg5_done;
reg sim_stg6_done;
reg sim_stg7_done;
reg sim_stg8_done;
reg st0_file_open;
reg st1_file_open;
reg st2_file_open;
reg st3_file_open;
reg st4_file_open;
reg st5_file_open;
reg st6_file_open;
reg st7_file_open;

integer rtl_stg0_f_ptr ;
integer rtl_stg1_f_ptr ;
integer rtl_stg2_f_ptr ;
integer rtl_stg3_f_ptr ;
integer rtl_stg4_f_ptr ;
integer rtl_stg5_f_ptr ;
integer rtl_stg6_f_ptr ;
integer rtl_stg7_f_ptr ;
integer rtl_finalstg_f_ptr ;
integer sim_filemem_idx ;


`endif



always @(posedge f_clk_i or posedge f_reset_i)			
begin
	if (f_reset_i == 1'b1)
	begin
	
		//p_stage_idx          	<= 0;
		loopcnt              	<= 1;
		ena_rad2_butfly_r    	<= 0;
		buttfly_stride          <= 0;
		loop_ctrl_st_sel        <= 0;
		loopcnt_idx     	    <= 0;

		//rem_stg_idx_shfter  	<= 0;
		loopcnt_idx_x_tworaise2k   <= 0;
		
		//stg_ctrl_st_sel         <= 0;
		stg_cnt_idx           	<= 0;
		//stg_cnt_shfter         	<= 0;
		
		f_done         	    <= 0;
		f_busy         	    <= 0;
		tworaise2k         	    <= 0;
		//rem_stg_idx         	<= 0;
		
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
										f_busy       <= 1;
`ifdef SIM
//#1000;
//$stop();   
`endif										
									end
                                    else
                                    begin
									    f_fsm        <= f_fsm;
										f_busy       <= 0;
                                    end									
								end
								else
								begin
					    		    f_fsm             <= sf_IDLE;
									f_busy         	    <= 0;
								end
							
								//p_stage_idx          	<= 0;
								loopcnt           	    <= 1;								
								ena_rad2_butfly_r    	<= 0;
								buttfly_stride          <= 0;
								loop_ctrl_st_sel         <= 0;
								loopcnt_idx     		 <= 0;
								//rem_stg_idx_shfter       <= 0;	
								loopcnt_idx_x_tworaise2k    <= 0;	

								//stg_ctrl_st_sel         <= 0;	
								stg_cnt_idx           	<= 0;
								//stg_cnt_shfter         	<= 0;
								//rem_stg_idx         	<= 0;
                                f_done         	    <= 0; 
                                //f_busy         	    <= 0;
								tworaise2k         	    <= 0;

                            	
							 end
							 
			sf_STG_LOOP_CTRL:					 
							 begin
							       f_busy         	    <= 1;
							       if (stg_cnt_idx==stage_cnt_i)
								   begin
								       f_fsm     <=    sf_IDLE;
									   f_done    <=    1;
`ifdef SIM

	   for(sim_filemem_idx=0;sim_filemem_idx<512;sim_filemem_idx=sim_filemem_idx+1)
	   begin
	        $fwrite(rtl_finalstg_f_ptr,"0x%h 0x%h\n",f_R_strg_mem_model[sim_filemem_idx],f_I_strg_mem_model[sim_filemem_idx]);
	   end
	   $fclose(rtl_finalstg_f_ptr); 	
       $stop();

`endif									   
									   
									   //rem_stg_idx <= 0;
								   end
							       else
								   begin
								       case (stg_cnt_idx)
									   
									      0 : begin
										           loopcnt         	<= 1; 
										           buttfly_stride   <= 2;
											  end
									      1 : begin
										           loopcnt         	<= 2; 
										           buttfly_stride   <= 4;
											  end	
									      2 : begin
										           loopcnt         	<= 4; 
										           buttfly_stride   <= 8;
											  end	
									      3 : begin
										           loopcnt         	<= 8; 
										           buttfly_stride   <= 16;
											  end	
									      4 : begin
										           loopcnt         	<= 16; 
										           buttfly_stride   <= 32;
											  end
									      5 : begin
										           loopcnt         	<= 32; 
										           buttfly_stride   <= 64;
											  end	
									      6 : begin
										           loopcnt         	<= 64; 
										           buttfly_stride   <= 128;
											  end	
									      7 : begin
										           loopcnt         	<= 128; 
										           buttfly_stride   <= 256;
											  end												  
									      8 : begin
										           loopcnt         	<= 256; 
										           buttfly_stride   <= 512;
											  end
									      default : begin
										           loopcnt         	<= loopcnt; 
										           buttfly_stride   <= buttfly_stride;
											  end											  
									   endcase
									   ena_rad2_butfly_r    	            <= 0;
									   tworaise2k         	    			<= 0;
									   loopcnt_idx_x_tworaise2k    			<= 0;	
									   loopcnt_idx    						<= 0;	
									   //stg_cnt_idx              			<= stg_cnt_idx + 1;//jan 13
									   
`ifdef SIM
//#100;
//$stop();
`endif										   
								   
								       f_fsm                 				<= sf_CALL_BFLY_PER_STG;
                                  end
							 end

			 sf_CALL_BFLY_PER_STG  : 
							      if (loopcnt_idx==loopcnt)
								  begin
								       f_fsm     					<=    sf_STG_LOOP_CTRL;
									   ena_rad2_butfly_r    	    <= 0;
									   stg_cnt_idx              	<= stg_cnt_idx + 1;
`ifdef SIM
$display(">>>>>>>>> Stage %d done",stg_cnt_idx);
if (sim_stg6_done==1)
sim_stg7_done = 1;
#1;
if (sim_stg5_done==1)
sim_stg6_done = 1;
#1;
if (sim_stg4_done==1)
sim_stg5_done = 1;
#1
if (sim_stg3_done==1)
sim_stg4_done = 1;
#1;
if (sim_stg2_done==1)
sim_stg3_done = 1;
#1;
if (sim_stg1_done==1)
sim_stg2_done = 1;
#1;
if (sim_stg0_done==1)
sim_stg1_done = 1;
#1;
sim_stg0_done = 1;

//$stop();		
`endif									   
								   
                                  end
								  else
								  begin
								      case(loop_ctrl_st_sel)
								  
										2'b00 : begin 
													case (rem_stg_idx_w)//k
															0 : tworaise2k  		<= 1;	
															1 : tworaise2k  		<= 2;	
															2 : tworaise2k  		<= 4;	
															3 : tworaise2k  		<= 8;	
															4 : tworaise2k  		<= 16;	
															5 : tworaise2k  		<= 32;	
															6 : tworaise2k  		<= 64;	
															7 : tworaise2k  		<= 128;	
															8 : tworaise2k  		<= 256;	
															default : tworaise2k    <= tworaise2k;
														endcase
														loop_ctrl_st_sel 		    <= 1;
														ena_rad2_butfly_r    	    <= 0;
												end
												
										2'b01 :  begin 
														//loopcnt_idx_x_tworaise2k_pls_1_    <= mul1_c_sig + 1;//Pls 1 for matlab
														loopcnt_idx_x_tworaise2k          <= mul1_c_sig;
														loop_ctrl_st_sel 		 		  <= 0;
														//loopcnt_idx                       <= loopcnt_idx + 1;
														//p_stage_idx                       <= loopcnt_idx;
														
														ena_rad2_butfly_r    	    <= 1;
														f_fsm     				<=    sf_CALL_bfly_TOP_LOOP;
`ifdef SIM
//#100;
//$stop();
`endif															
												 end	
												
										default : begin
                                                        f_fsm     <=    f_fsm;
                                                  end										

                                       endcase											  
                                  end		

              sf_CALL_bfly_TOP_LOOP      : begin
													//if (p_stage_idx_bfcalc_o ==f_point_i && bf_pipleline_tracker == 3)
													if (p_stage_idx_bfcalc_o >=f_point_i && bf_pipleline_tracker == 3)
													begin	
													    f_fsm     <= sf_CALL_BFLY_PER_STG;  
														loopcnt_idx <= loopcnt_idx + 1;		
														ena_rad2_butfly_r    	    <= 0;//jan13
`ifdef SIM

/* if (sim_stg3_done==1)
sim_stg4_done = 1;
#1;
if (sim_stg2_done==1)
sim_stg3_done = 1;
#1;
if (sim_stg1_done==1)
sim_stg2_done = 1;
#1;
if (sim_stg0_done==1)
sim_stg1_done = 1;
#1;
sim_stg0_done = 1; */

/* if (st0_file_open==1)
begin
$fclose(rtl_stg0_f_ptr); st0_file_open = 0;
end
if (st1_file_open==1)
begin
$fclose(rtl_stg1_f_ptr); st1_file_open = 0;
end
if (st2_file_open==1)
begin
$fclose(rtl_stg2_f_ptr); st2_file_open = 0;
end
if (st3_file_open==1)
begin
$fclose(rtl_stg3_f_ptr); st3_file_open = 0;
end */
//$stop();	
`endif														
													end	
													else	
													begin
													    f_fsm     <= f_fsm; 
													end
				                                  end


								  
             default                            : begin
														f_fsm     <= f_fsm; 
			 
			                                      end

            endcase							 

	end
end	

assign  wb_CosSin_RAM_Data_o  =  {f_sin_rd_data_w,f_cos_rd_data_w};

assign wb_CosSin_RAM_rd_access_ctrl = ~f_busy;
assign wb_f_RAM_wr_rd_Mast_sel    = ~f_busy;

assign cos_ram_rd_addr_ptr 	= (wb_CosSin_RAM_rd_access_ctrl==1'b1)? wb_CosSin_RAM_aDDR_i : f_cos_addr_ptr;
assign sin_ram_rd_addr_ptr 	= (wb_CosSin_RAM_rd_access_ctrl==1'b1)? wb_CosSin_RAM_aDDR_i : f_sin_addr_ptr;
assign wd_sel_cos 			= wb_CosSin_RAM_Wen_i; 
assign wd_sel_sin 			= wb_CosSin_RAM_Wen_i; 

assign wen_cos 				= {wb_CosSin_RAM_Wen_i,wb_CosSin_RAM_Wen_i} ;
assign wen_sin 				= {wb_CosSin_RAM_Wen_i,wb_CosSin_RAM_Wen_i} ;



//COS/SIN data is written to RAM for f bfly computations
r512x16_512x16 u_r512x16_512x16_f_COS_DATA (
								 .WA	  	( wb_CosSin_RAM_aDDR_i[8:0]  ) 	,
								 .RA		( cos_ram_rd_addr_ptr )	,
								 .WD		( wb_CosSin_RAM_Data_i[15:0]  )	,
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
								 .WD		( wb_CosSin_RAM_Data_i[31:16]  )	,
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
								
`ifdef SIM



/* initial 
begin
    rtl_stg0_f_ptr   			= $fopen("rtl_stg0_f_ptr.txt", "w");	
    rtl_stg1_f_ptr   			= $fopen("rtl_stg1_f_ptr.txt", "w");	
    rtl_stg2_f_ptr   			= $fopen("rtl_stg2_f_ptr.txt", "w");	
    rtl_stg3_f_ptr   			= $fopen("rtl_stg3_f_ptr.txt", "w");	
    sim_stg0_done                = 0;
    sim_stg1_done                = 0;
    sim_stg2_done                = 0;
    sim_stg3_done                = 0;
	st0_file_open                = 1;   
	st1_file_open                = 0;   
	st2_file_open                = 0;   
	st3_file_open                = 0;   
	//$stop();
	while (~sim_stg0_done)
	begin
		@(posedge fram_realimg_wr);
		#50;
		//$fwrite(rtl_stg0_f_ptr,"Address =0x%h  Real Data = 0x%h Img Data = 0x%h @time=%d \n",f_realimg_waddr_mux_sig, f_real_data_mux_sig, f_img_data_mux_sig,$time);	
		$fwrite(rtl_stg0_f_ptr,"Address =0x%h  Real Data = 0x%h Img Data = 0x%h  ",f_realimg_waddr_mux_sig, f_real_data_mux_sig, f_img_data_mux_sig);	
		@(posedge WBs_CLK_i);
		#50;
		$fwrite(rtl_stg0_f_ptr,"Address =0x%h  Real Data = 0x%h Img Data = 0x%h @time=%d \n",f_realimg_waddr_mux_sig, f_real_data_mux_sig, f_img_data_mux_sig,$time);	

	end 
		$fclose(rtl_stg0_f_ptr); 
	//st1_file_open                = 1; 	
	while (~sim_stg1_done)
	begin
		@(posedge fram_realimg_wr);
		#50;
		$fwrite(rtl_stg1_f_ptr,"Address =0x%h  Real Data = 0x%h Img Data = 0x%h  ",f_realimg_waddr_mux_sig, f_real_data_mux_sig, f_img_data_mux_sig);	
		@(posedge WBs_CLK_i);
		#50;
		$fwrite(rtl_stg1_f_ptr,"Address =0x%h  Real Data = 0x%h Img Data = 0x%h\n",f_realimg_waddr_mux_sig, f_real_data_mux_sig, f_img_data_mux_sig);	
	end 	
		$fclose(rtl_stg1_f_ptr); 	
	//$fclose(rtl_stg0_f_ptr);
end */

initial 
begin
    rtl_stg0_f_ptr   			= $fopen("rtl_stg0_f_ptr.txt", "w");	
    rtl_stg1_f_ptr   			= $fopen("rtl_stg1_f_ptr.txt", "w");	
    rtl_stg2_f_ptr   			= $fopen("rtl_stg2_f_ptr.txt", "w");	
    rtl_stg3_f_ptr   			= $fopen("rtl_stg3_f_ptr.txt", "w");	
    rtl_stg4_f_ptr   			= $fopen("rtl_stg4_f_ptr.txt", "w");	
    rtl_stg5_f_ptr   			= $fopen("rtl_stg5_f_ptr.txt", "w");	
    rtl_stg6_f_ptr   			= $fopen("rtl_stg6_f_ptr.txt", "w");	
    rtl_stg7_f_ptr   			= $fopen("rtl_stg7_f_ptr.txt", "w");	
    rtl_finalstg_f_ptr   		= $fopen("rtl_finalstg_f_ptr.txt", "w");	
    sim_stg0_done                = 0;
    sim_stg1_done                = 0;
    sim_stg2_done                = 0;
    sim_stg3_done                = 0;
    sim_stg4_done                = 0;
    sim_stg5_done                = 0;
    sim_stg6_done                = 0;
    sim_stg7_done                = 0;	
	st0_file_open                = 1;   
	st1_file_open                = 0;   
	st2_file_open                = 0;   
	st3_file_open                = 0; 
	st4_file_open                = 0;   
	st5_file_open                = 0;   
	st6_file_open                = 0;   
	st7_file_open                = 0; 	
	//$stop();
	
	wait (sim_stg0_done==1);
	   for(sim_filemem_idx=0;sim_filemem_idx<512;sim_filemem_idx=sim_filemem_idx+1)
	   begin
	        //$fwrite(rtl_stg0_f_ptr,"Real = 0x%h Img = 0x%h\n",f_R_strg_mem_model[sim_filemem_idx],f_I_strg_mem_model[sim_filemem_idx]);
	        $fwrite(rtl_stg0_f_ptr,"0x%h 0x%h\n",f_R_strg_mem_model[sim_filemem_idx],f_I_strg_mem_model[sim_filemem_idx]);
	   end
	   $fclose(rtl_stg0_f_ptr); 

	wait (sim_stg1_done==1);
	   for(sim_filemem_idx=0;sim_filemem_idx<512;sim_filemem_idx=sim_filemem_idx+1)
	   begin
	        $fwrite(rtl_stg1_f_ptr,"0x%h 0x%h\n",f_R_strg_mem_model[sim_filemem_idx],f_I_strg_mem_model[sim_filemem_idx]);
	   end
	   $fclose(rtl_stg1_f_ptr); 	
	   
	wait (sim_stg2_done==1);
	   for(sim_filemem_idx=0;sim_filemem_idx<512;sim_filemem_idx=sim_filemem_idx+1)
	   begin
	        $fwrite(rtl_stg2_f_ptr,"0x%h 0x%h\n",f_R_strg_mem_model[sim_filemem_idx],f_I_strg_mem_model[sim_filemem_idx]);
	   end
	   $fclose(rtl_stg2_f_ptr); 

	wait (sim_stg3_done==1);
	   for(sim_filemem_idx=0;sim_filemem_idx<512;sim_filemem_idx=sim_filemem_idx+1)
	   begin
	        $fwrite(rtl_stg3_f_ptr,"0x%h 0x%h\n",f_R_strg_mem_model[sim_filemem_idx],f_I_strg_mem_model[sim_filemem_idx]);
	   end
	   $fclose(rtl_stg3_f_ptr);

	wait (sim_stg4_done==1);
	   for(sim_filemem_idx=0;sim_filemem_idx<512;sim_filemem_idx=sim_filemem_idx+1)
	   begin
	        $fwrite(rtl_stg4_f_ptr,"0x%h 0x%h\n",f_R_strg_mem_model[sim_filemem_idx],f_I_strg_mem_model[sim_filemem_idx]);
	   end
	   $fclose(rtl_stg4_f_ptr); 	

	wait (sim_stg5_done==1);
	   for(sim_filemem_idx=0;sim_filemem_idx<512;sim_filemem_idx=sim_filemem_idx+1)
	   begin
	        $fwrite(rtl_stg5_f_ptr,"0x%h 0x%h\n",f_R_strg_mem_model[sim_filemem_idx],f_I_strg_mem_model[sim_filemem_idx]);
	   end
	   $fclose(rtl_stg5_f_ptr); 
	   
	wait (sim_stg6_done==1);
	   for(sim_filemem_idx=0;sim_filemem_idx<512;sim_filemem_idx=sim_filemem_idx+1)
	   begin
	        $fwrite(rtl_stg6_f_ptr,"0x%h 0x%h\n",f_R_strg_mem_model[sim_filemem_idx],f_I_strg_mem_model[sim_filemem_idx]);
	   end
	   $fclose(rtl_stg6_f_ptr); 	

	wait (sim_stg7_done==1);
	   for(sim_filemem_idx=0;sim_filemem_idx<512;sim_filemem_idx=sim_filemem_idx+1)
	   begin
	        $fwrite(rtl_stg7_f_ptr,"0x%h 0x%h\n",f_R_strg_mem_model[sim_filemem_idx],f_I_strg_mem_model[sim_filemem_idx]);
	   end
	   $fclose(rtl_stg7_f_ptr); 	   
	//$fclose(rtl_stg0_f_ptr);
end

`endif								

wire  [f_MEM_ADDRWIDTH-1:0] 	    wb_f_realImg_RAM_aDDR_br;   		
wire  [f_MEM_ADDRWIDTH-1:0] 	    wb_f_realImg_RAM_aDDR_br_norm_muxed;   		
genvar br_i; 
generate 
for( br_i=0; br_i<9; br_i=br_i+1 ) 
begin : brev 
assign wb_f_realImg_RAM_aDDR_br[br_i] = wb_f_realImg_RAM_aDDR_i[8-br_i]; 
end 
endgenerate

assign wb_f_realImg_RAM_Data_o  = (~wb_f_realimgbar_ram_rd_switch_i) ? fram_real_rdata : fram_img_rdata;							

assign wb_f_realImg_RAM_aDDR_br_norm_muxed = (ena_bit_rev_i) ? wb_f_realImg_RAM_aDDR_br : wb_f_realImg_RAM_aDDR_i;			
							
/* assign f_realimg_waddr_mux_sig 	= (wb_f_RAM_wr_rd_Mast_sel) ? wb_f_realImg_RAM_aDDR_br : fram_realimg_waddr ;
assign f_realimg_raddr_mux_sig 	= (wb_f_RAM_wr_rd_Mast_sel) ? wb_f_realImg_RAM_aDDR_br : fram_realimg_raddr ; */
assign f_realimg_waddr_mux_sig 	= (wb_f_RAM_wr_rd_Mast_sel) ? wb_f_realImg_RAM_aDDR_br_norm_muxed : fram_realimg_waddr ;
assign f_realimg_raddr_mux_sig 	= (wb_f_RAM_wr_rd_Mast_sel) ? wb_f_realImg_RAM_aDDR_br_norm_muxed : fram_realimg_raddr ;
assign f_real_data_mux_sig 	    = (wb_f_RAM_wr_rd_Mast_sel) ? wb_f_real_RAM_Data_i    : fram_real_wdata;
assign f_img_data_mux_sig 	    = (wb_f_RAM_wr_rd_Mast_sel) ? 32'h0 				      : fram_img_wdata;
assign f_realimg_wen_mux_sig 	    = (wb_f_RAM_wr_rd_Mast_sel) ? wb_f_realImg_RAM_Wen_i  : fram_realimg_wr ;


//Real_Data_storage
r512x32_512x32 u_r512x32_512x32_real_DATA (
								 .WA	  	( f_realimg_waddr_mux_sig ), 
								 .RA		( f_realimg_raddr_mux_sig ),
								 
								 .WD		( f_real_data_mux_sig ),
								 .WD_SEL	( f_realimg_wen_mux_sig ),
								 .RD_SEL	( 1'b1 ),
								 .WClk		( WBs_CLK_i),
								 .RClk		( WBs_CLK_i ),
								 .WClk_En	( 1'b1  )	,
								 .RClk_En	( 1'b1  )	,
								 .WEN		( {4{f_realimg_wen_mux_sig}} ),
								 .RD		( fram_real_rdata  ),
								 .LS		( 1'b0  )	,
								 .DS		( 1'b0  )	,
								 .SD		( 1'b0  )	,
								 .LS_RB1	( 1'b0  )	,
								 .DS_RB1	( 1'b0  )	,
								 .SD_RB1    ( 1'b0  )

								);	
								
//Img_Data_storage
r512x32_512x32 u_r512x32_512x32_img_DATA (
								// .WA	  	( fram_realimg_waddr ),
								 .WA	  	( f_realimg_waddr_mux_sig ),
								 .RA		( f_realimg_raddr_mux_sig ),
								 
								 .WD		( f_img_data_mux_sig ), 
								 .WD_SEL	( f_realimg_wen_mux_sig ),
								 .RD_SEL	( 1'b1 ),
								 .WClk		( WBs_CLK_i),
								 .RClk		( WBs_CLK_i ),
								 .WClk_En	( 1'b1  )	,
								 .RClk_En	( 1'b1  )	,
								 .WEN		( {4{f_realimg_wen_mux_sig}} ),
								 .RD		( fram_img_rdata  ),
								 .LS		( 1'b0  )	,
								 .DS		( 1'b0  )	,
								 .SD		( 1'b0  )	,
								 .LS_RB1	( 1'b0  )	,
								 .DS_RB1	( 1'b0  )	,
								 .SD_RB1    ( 1'b0  )

								);			


//Instantiate r2 bfly compute block
r2_bfly_p  #(
						.ADDRWIDTH		( f_MEM_ADDRWIDTH),
						.DATAWIDTH		( f_MEM_DATAWIDTH),
                        .COEFWIDTH      ( f_COEFWIDTH)
					  )

r2_bfly_p_inst0 (
										   .clk_i						( f_clk_i								),
										   .rst_i                      ( f_reset_i                  			),
										   .ena_rad2_butfly_i          ( ena_rad2_butfly_r      				),
										   
										   .fRAM_real_data_i         ( fram_real_rdata     				),
                                           .fRAM_img_data_i          ( fram_img_rdata      				),
                                           .fRAM_real_data_o         ( fram_real_wdata     				),
                                           .fRAM_img_data_o          ( fram_img_wdata      				),
                                           .fRAM_realimg_r_addr_o    ( fram_realimg_raddr				),
                                           .fRAM_realimg_w_addr_o    ( fram_realimg_waddr				),
                                           .fRAM_realimg_wr_o        ( fram_realimg_wr    				),
                                           
                                           .cos_i                      ( f_cos_rd_data_w        				),
                                           .sin_i                      ( f_sin_rd_data_w        				),
                                           //.bfly_done_o           ( bfly_done_w       				),
                                           
                                           .scale_last_stg_i           ( scale_last_stg_i       				), 
                                           .last_stg_i                 ( last_stg_i             				),
                                           
                                           .mul1_a_o	                ( f_mul1_a_sig	            		),
                                           .mul1_b_o	                ( f_mul1_b_sig	            		),
                                           .mul1_c_i                    ( f_mul1_c_sig               			),
                                           .mul1_ena_o                  ( f_mul1_ena_sig             			),
                                           .mul2_a_o	                ( f_mul2_a_sig	            		),
                                           .mul2_b_o	                ( f_mul2_b_sig	            		),
                                           .mul2_c_i                    ( f_mul2_c_sig               			),
                                           .mul2_ena_o                  ( f_mul2_ena_sig             			),
                                           
                                           //.loop_cnt_pls_1_i           ( loopcnt_pls_1       				    ),
                                           .loop_cnt_i           	   ( loopcnt		       				    ),
                                           .stride_i                   ( buttfly_stride               			),
                                           .p_init_i                   ( p_stage_idx_w               			),
										   .cycle_cnt_o                ( bf_pipleline_tracker                   ),
										   .p_stage_idx_bfcalc_o       ( p_stage_idx_bfcalc_o                   )
                                           //.bfly_busy_o           ( bfly_busy       				)
   
						 );
						 
/*						 
qlal4s3_mult_32x32_cell u_qlal4s3_mult_32x32_cell_inst0 
						( 
							.Amult			(mul1_a_sig), 
							.Bmult			(mul1_b_sig), 
			
							.Cmult			(mul1_c_sig));
							

qlal4s3_mult_32x32_cell u_qlal4s3_mult_32x32_cell_inst1 
						( 
							.Amult			(f_mul2_a_sig), 
							.Bmult			(f_mul2_b_sig), 
			                                    
							.Cmult			(f_mul2_c_sig));	
*/							
							
qlal4s3_mult_cell_macro u_qlal4s3_mult_cell_macro_inst0 //qlal4s3_mult_cell_macro 
						( 
							.Amult			(mul1_a_sig), 
							.Bmult			(mul1_b_sig), 
							.Valid_mult		(2'b11),
                            .sel_mul_32x32  (1'b1),							
							.Cmult			(mul1_c_sig));

qlal4s3_mult_cell_macro u_qlal4s3_mult_cell_macro_inst1 //qlal4s3_mult_cell_macro 
						( 
							.Amult			(f_mul2_a_sig), 
							.Bmult			(f_mul2_b_sig), 
							.Valid_mult		(2'b11),
                            .sel_mul_32x32  (1'b1),							
							.Cmult			(f_mul2_c_sig));

`ifdef SIM
integer sim_write_pulse_count;
integer sim_curr_stg_count;

reg [31:0] f_R_strg_mem_model [0:511];
reg [31:0] f_I_strg_mem_model [0:511];

initial
begin
	sim_write_pulse_count = 0;
	sim_curr_stg_count         = 0;

end
always @(posedge fram_realimg_wr)
begin
     sim_write_pulse_count = sim_write_pulse_count +1;
	 if(sim_write_pulse_count%256==0 && sim_write_pulse_count !=0)
	   sim_curr_stg_count = sim_curr_stg_count +1;
end

integer f_cycle_count;

initial
begin
    f_cycle_count = 1;
	wait (f_start_i==1);
	forever
	begin
	     @(posedge  f_clk_i);
	     f_cycle_count = f_cycle_count + 1;
    end
end

/* always @(posedge fram_realimg_wr)
begin
	    #5;
	    f_R_strg_mem_model[fram_realimg_waddr] = f_real_data_mux_sig;
	    f_I_strg_mem_model[fram_realimg_waddr] = f_img_data_mux_sig;		
		@(posedge WBs_CLK_i);
		#5;
	    f_R_strg_mem_model[fram_realimg_waddr] = f_real_data_mux_sig;
	    f_I_strg_mem_model[fram_realimg_waddr] = f_img_data_mux_sig;	
end */

always @(posedge WBs_CLK_i)
begin
	    #5;
		if (fram_realimg_wr)
		begin
			f_R_strg_mem_model[fram_realimg_waddr] = f_real_data_mux_sig;
			f_I_strg_mem_model[fram_realimg_waddr] = f_img_data_mux_sig;		
		end
	
end

`endif							

endmodule




 