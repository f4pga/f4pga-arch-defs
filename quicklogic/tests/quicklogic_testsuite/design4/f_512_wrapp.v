/*******************************************************************
 *
 *    FILE:         f_512_wrapp.v 
 *   
 *    DESCRIPTION:  512 Tap f processing
 *
 *    HIERARCHY:   
 *
 *    AUTHOR:	    Anand A Wadke
 *
 *    HISTORY:
 *			        - Jan/4/2019	Initial coding.
 *			
 *
 * Copyright (C) 2019, Licensed Customers of QuickLogic may copy and modify this
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
 * Date: Jan 04, 2019
 * Engineer: Anand Wadke
 * Revision: 1.0
 * 
 * 1. Initial Coding
 * 2. Input 512 Data is considered to be real
 *******************************************************************/
`timescale 1ns/10ps
//`define FPGA_POWER_MEASURE //f start continously enabled
module f_512_wrapp (
						WBs_CLK_i 						,
                        WBs_RST_i                       ,
                        WBs_ADR_i                       ,
						
                        WBs_CYC_i         		        ,
                        WBs_CYC_DMA_Reg_i  	            ,
                        WBs_CYC_f_Realmg_RAM_i        ,
                        WBs_CYC_f_CosSin_RAM_i        ,
						
                        WBs_BYTE_STB_i                  ,
                        WBs_WE_i                        ,
                        WBs_STB_i                       ,
                        WBs_DAT_i                       ,
                        WBs_DAT_o                       ,
						
                        WBs_DMAREG_DAT_o                ,
                        WBs_CosSin_RAM_DAT_o            ,
                        WBs_f_RAM_DAT_o               ,
						
                        WBs_ACK_o                       ,
						
                        sys_ref_clk_i		            ,
						
                        fDone_Intr_o                  ,
                        f_DMA_Intr_o                  ,
						
                        SDMA_Req_f_o                  ,
                        SDMA_Sreq_f_o                 ,
                        SDMA_Done_f_i                 ,
                        SDMA_Active_f_i               
  
                     );


//------Port Parameters----------------
//

parameter                ADDRWIDTH                   =  17           ;
parameter                COEFFADDRWIDTH              =   9           ;
parameter                fRAMADDRWIDTH             =   9           ;
parameter                DATAWIDTH                   =  32           ;

//------Port Signals-------------------
//


// Fabric Global Signals
//
input                    WBs_CLK_i           ; // Fabric Clock               from Fabric
input                    WBs_RST_i           ; // Fabric Reset               to   Fabric


// Wishbone Bus Signals
//
input   [ADDRWIDTH-3:0]  WBs_ADR_i           ; // Address Bus                to   Fabric
//input   [ADDRWIDTH-3:0]  WBs_ADR_a_i           ; // Address Bus                to   Fabric

input                    WBs_CYC_i   ; 
input                    WBs_CYC_DMA_Reg_i   ; 
input                    WBs_CYC_f_Realmg_RAM_i      ;     
input                    WBs_CYC_f_CosSin_RAM_i      ;     

input             [3:0]  WBs_BYTE_STB_i      ; // Byte Enable Strobes        to   Fabric
input                    WBs_WE_i            ; // Write Enable               to   Fabric
input                    WBs_STB_i           ; // Strobe Signal              to   Fabric
input   [DATAWIDTH-1:0]  WBs_DAT_i           ; // Write Data Bus             to   Fabric
output  [DATAWIDTH-1:0]  WBs_DAT_o 			 ;
output  [DATAWIDTH-1:0]  WBs_DMAREG_DAT_o 	 ;
output  [DATAWIDTH-1:0]  WBs_CosSin_RAM_DAT_o;
output  [DATAWIDTH-1:0]  WBs_f_RAM_DAT_o   ;

output                   WBs_ACK_o           ; // Transfer Cycle Acknowledge from Fabric

input 					 sys_ref_clk_i		 ;

output                   fDone_Intr_o      ;   
output                   f_DMA_Intr_o      ;  

output            		 SDMA_Req_f_o      ;
output            		 SDMA_Sreq_f_o     ;
input             		 SDMA_Done_f_i     ;
input             		 SDMA_Active_f_i   ;
                                       

									   


wire   [3:0]		   				stage_cnt;
wire   [9:0]         				f_point;
wire			      				ena_perstgscale;	

wire   [COEFFADDRWIDTH-1:0]   	    wb_CosSin_RAM_aDDR;
wire 								wb_CosSin_RAM_Wen;
wire   [DATAWIDTH-1:0] 			    wb_CosSin_RAM_wrData_sig;	
wire   [DATAWIDTH-1:0]  			wb_CosSin_RAM_rdData_sig;	
                                  
wire   [fRAMADDRWIDTH-1:0] 	    wb_f_realImg_RAM_aDDR_sig;	 
wire   [DATAWIDTH-1:0]     		    wb_f_realImg_RAM_rdData_sig;	 
wire   [DATAWIDTH-1:0]     		    wb_f_real_RAM_wrData_sig;	 
wire 								wb_f_realImg_RAM_Wen_sig;	 
wire								wb_f_realimgbar_ram_rd_switch;	

wire 								f_calc_done;									   
wire 								f_busy;
wire 								f_start;

wire 								f_IRQ;
wire 								f_IRQ_EN;

wire 								DMA0_Clr;
wire 								DMA0_Start;
wire 								DMA0_Done_IRQ;
wire 								DMA0_Done_IRQ_EN;

wire 								f_en;

      
   
//
assign   fDone_Intr_o		=   f_IRQ 		& 	f_IRQ_EN;
assign   f_DMA_Intr_o     =   DMA0_Done_IRQ 	& 	DMA0_Done_IRQ_EN;
assign   SDMA_Sreq_f_o    =   1'b0;
									   

f_512_compute 	#(
						.f_MEM_ADDRWIDTH	( fRAMADDRWIDTH ),
						.f_MEM_DATAWIDTH  ( DATAWIDTH )
	                  )

					f_512_compute_inst0 (
                                 .f_clk_i						    (  WBs_CLK_i	 			),
								 .f_reset_i                       (  WBs_RST_i				),
								 .f_ena_i                         (  f_en  				),
`ifdef FPGA_POWER_MEASURE
								 .f_start_i					    (  1'b1				),
`else								 
								 .f_start_i					    (  f_start				),
`endif								 
								 
								 .WBs_CLK_i						    (  WBs_CLK_i				),
								 //.WBs_RST_i                         (  WBs_RST_i 				),
								 
								 .stage_cnt_i					    (  stage_cnt		        ),
								 .f_point_i                       (  f_point               	),
								 .ena_perstgscale_i                 (  ena_perstgscale         	),
								 .ena_bit_rev_i                     (  ena_bit_rev_sig            ),
							 
								 .wb_CosSin_RAM_aDDR_i            	(	wb_CosSin_RAM_aDDR     		), 
								 .wb_CosSin_RAM_Wen_i             	(	wb_CosSin_RAM_Wen       	),
								 .wb_CosSin_RAM_Data_i	          	(	wb_CosSin_RAM_wrData_sig	),
								 .wb_CosSin_RAM_Data_o	          	(	wb_CosSin_RAM_rdData_sig	),
								 								 
								 .wb_f_realImg_RAM_aDDR_i	        (	wb_f_realImg_RAM_aDDR_sig		),
								 .wb_f_realImg_RAM_Data_o	        (	wb_f_realImg_RAM_rdData_sig		),
								 .wb_f_real_RAM_Data_i	        (	wb_f_real_RAM_wrData_sig	    ),
								 .wb_f_realImg_RAM_Wen_i	        (	wb_f_realImg_RAM_Wen_sig	    ),
								 .wb_f_realimgbar_ram_rd_switch_i (	wb_f_realimgbar_ram_rd_switch	),
								 
								 .f_calc_done_o					(	f_calc_done				),
								 .f_busy_o                        (   f_busy					)
								 
								);									   
						

f_registers      #(
						.ADDRWIDTH			( ADDRWIDTH ),
						.DATAWIDTH  		( DATAWIDTH ),
						.COEFFADDRWIDTH		( COEFFADDRWIDTH 	),
						.fRAMADDRWIDTH    ( fRAMADDRWIDTH   )
	                )

					f_registers_inst0( 
                         
								.WBs_CLK_i 							(  WBs_CLK_i ),         
								.WBs_RST_i                          (  WBs_RST_i ),
                                                
								.WBs_ADR_i                          (  WBs_ADR_i ),
								//.WBs_ADR_b_i                          (  WBs_ADR_a_i ),
								.WBs_CYC_i                          (  WBs_CYC_i ),
								.WBs_CYC_DMA_i                      (  WBs_CYC_DMA_Reg_i		 ),
								.WBs_CYC_COEFF_RAM_i                (  WBs_CYC_f_CosSin_RAM_i  ),
								.WBs_CYC_RealImg_RAM_i              (  WBs_CYC_f_Realmg_RAM_i  ),
 			                                    
								.WBs_BYTE_STB_i                     (  WBs_BYTE_STB_i ),
								.WBs_WE_i                           (  WBs_WE_i ),
								.WBs_STB_i                          (  WBs_STB_i  ),
								.WBs_DAT_i                          (  WBs_DAT_i ),
								.WBs_DAT_o                          (  WBs_DAT_o ),
								.WBs_DMA_DAT_o                      (  WBs_DMAREG_DAT_o ),
								.WBs_f_RealImg_RAM_DAT_o	        (  WBs_f_RAM_DAT_o ),
								.WBs_COEF_RAM_DAT_o	                (  WBs_CosSin_RAM_DAT_o ),
			                                   
								.WBs_ACK_o                          (  WBs_ACK_o ),
								
								.stage_cnt_o						( stage_cnt      ),
								.f_point_o						( f_point      ),
								.ena_perstgscale_o					( ena_perstgscale      ),
								.f_en_o							( f_en),
								
								.ena_bit_rev_o                     (  ena_bit_rev_sig            ),
			                                  
								.f_IRQ_o                          (  f_IRQ     ),
								.f_IRQ_EN_o                       (  f_IRQ_EN  ),
                                                
								.f_done_i	                        (  f_calc_done ),
								.f_busy_i                         (  f_busy ),
								.f_start_o                        (  f_start ),
                                              
								.wb_CosSin_RAM_aDDR_o               (  wb_CosSin_RAM_aDDR     	 ),
								.wb_CosSin_RAM_Wen_o                (  wb_CosSin_RAM_Wen         ),
								.wb_CosSin_RAM_Data_o	            (  wb_CosSin_RAM_wrData_sig  ),
								.wb_CosSin_RAM_Data_i	            (  wb_CosSin_RAM_rdData_sig  ),
			                          
								.wb_f_realImg_RAM_aDDR_o	        (  wb_f_realImg_RAM_aDDR_sig		 ),
								.wb_f_realImg_RAM_Data_i	        (  wb_f_realImg_RAM_rdData_sig	 ),
								.wb_f_real_RAM_Data_o	            (  wb_f_real_RAM_wrData_sig	     ),
								.wb_f_realImg_RAM_Wen_o	        (  wb_f_realImg_RAM_Wen_sig	     ),
								.wb_f_realimgbar_ram_rd_switch_o  (  wb_f_realimgbar_ram_rd_switch	 ),
                             
								.DMA0_Clr_i                         (  DMA0_Clr ),
								.DMA0_Done_i                        (  SDMA_Done_f_i ),
								.DMA0_Start_o                       (  DMA0_Start  ),
								
								.DMA0_Done_IRQ_o                    (  DMA0_Done_IRQ     ),
								.DMA0_Done_IRQ_EN_o                 (  DMA0_Done_IRQ_EN  )

			
            );



dma_ctrl u_f_dma_ctrl( 
								.clk_i				( WBs_CLK_i     ),
								.rst_i				( WBs_RST_i     ),
								
								.trig_i	            ( DMA0_Start		),
								
								.DMA_Active_i		( SDMA_Active_f_i ),	
								.ASSP_DMA_Done_i	( SDMA_Done_f_i	),					
								.DMA_Done_o			(  					),		
								.DMA_Clr_o			( DMA0_Clr			),	
								.DMA_Enable_i		( 1'b1 				),
								.DMA_REQ_o			( SDMA_Req_f_o    )	  	 				

			           );

					 

endmodule




 