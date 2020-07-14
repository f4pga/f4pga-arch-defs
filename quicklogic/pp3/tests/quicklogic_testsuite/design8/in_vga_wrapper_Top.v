// -----------------------------------------------------------------------------
// title          : InVGA Frame Receive
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : in_vga_wrapper_Top.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2017/11/8	
// last update    : 2017/11/8
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: 
// -----------------------------------------------------------------------------
// copyright (c) 2017
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         description
// 2016/11/08      1.0        Anand Wadke     Initial Release
//
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps


module in_vga_wrapper_Top ( 

				
                WBs_CLK_i,
                WBs_RST_i,

                WBs_ADR_i,
                WBs_CYC_i,
                //WBs_CYC_LCD_Tx_FIFO_i,
                WBs_BYTE_STB_i,
                WBs_WE_i ,
                WBs_STB_i,
                WBs_DAT_i,
                WBs_DAT_o,
				//WBs_LCD_DAT_o,
                WBs_ACK_o,
				
				//LCD_Busy_o,	
                VGA_Intr_o,
			    VGA_DMA_Intr_o,

                SDMA_Req_VGA_o,
                SDMA_Sreq_VGA_o,
                SDMA_Done_VGA_i,
                SDMA_Active_VGA_i,
				
				PCLK_i,    	
				VSYNC_i,    
				HREF_HSYNC_i,
				RGB_DAT_i  
				
                );


//------Port Parameters----------------
//

parameter       ADDRWIDTH                   	=   10           ;
parameter       DATAWIDTH                   	=  32           ;

//Parameters
parameter       IN_VGA_STATUS_REG_ADDR 		   = 5'h0 ;	
parameter       IN_VGA_CONTROL_REG_ADR		   = 5'h1 ;
parameter       IN_VGA_RX_FIFO_DATCNT_REG_ADR	   = 5'h2 ;
parameter       IN_VGA_RX_FIFO_LINECNT_REG_ADR   = 5'h3 ;
parameter       IN_VGA_DMA_CONTROL_REG_ADR	   = 5'h4 ;
parameter       IN_VGA_DMA_STATUS_REG_ADR	       = 5'h5 ;
parameter       IN_VGA_RGB_RXDATA_REG_ADR	       = 5'h6 ;
parameter       IN_VGA_DEBUG_REG_ADR	       	   = 5'h7 ;
parameter       IN_VGA_DEF_REG_VALUE			   = 32'hC0C_DEF_AC; // Distinguish access to undefined area


//------Port Signals-------------------
//

// Fabric Global Signals
//
//input 					 clk_i;
//input 					 RST_fb_i;


input                    WBs_CLK_i           ; // Fabric Clock               from Fabric
input                    WBs_RST_i           ; // Fabric Reset               to   Fabric



// Wishbone Bus Signals
//
input   [ADDRWIDTH-1:0]  WBs_ADR_i           ; // Address Bus                to   Fabric
input                    WBs_CYC_i    ; // Cycle Chip Select          to   Fabric 
//input                    WBs_CYC_LCD_Tx_FIFO_i; // Cycle Chip Select          to   Fabric
input             [3:0]  WBs_BYTE_STB_i      ; // Wishbone Byte   Enable Strobes
input                    WBs_WE_i            ; // Write Enable               to   Fabric
input                    WBs_STB_i           ; // Strobe Signal              to   Fabric
input   [DATAWIDTH-1:0]  WBs_DAT_i           ; // Write Data Bus             to   Fabric
output  [DATAWIDTH-1:0]  WBs_DAT_o           ; // Read  Data Bus             from Fabric
//output  [DATAWIDTH-1:0]  WBs_LCD_DAT_o		 ;
output                   WBs_ACK_o           ; // Transfer Cycle Acknowledge from Fabric


//output                   LCD_Busy_o           ;
output                   VGA_Intr_o           ;

output					 VGA_DMA_Intr_o		 ;

output                   SDMA_Req_VGA_o       ;
output                   SDMA_Sreq_VGA_o      ;
input                    SDMA_Done_VGA_i      ;
input                    SDMA_Active_VGA_i    ; 

//VGA Interface
input 					 PCLK_i;
input 					 VSYNC_i;
input 					 HREF_HSYNC_i;
input 	[7:0]			 RGB_DAT_i;	



// Fabric Global Signals
//
wire                     WBs_CLK_i           ; // Wishbone Fabric Clock
wire                     WBs_RST_i           ; // Wishbone Fabric Reset

// Wishbone Bus Signals
//
wire    [ADDRWIDTH-1:0]  WBs_ADR_i           ; // Wishbone Address Bus
wire                     WBs_CYC_i    ; // Cycle Chip Select          to   Fabric 
//wire                     WBs_CYC_LCD_Tx_FIFO_i; // Cycle Chip Select          to   Fabric
wire              [3:0]  WBs_BYTE_STB_i      ; // Wishbone Byte   Enable Strobes
wire                     WBs_WE_i            ; // Wishbone Write  Enable Strobe
wire                     WBs_STB_i           ; // Wishbone Transfer      Strobe
wire    [DATAWIDTH-1:0]  WBs_DAT_i           ; // Wishbone Wrire  Data Bus
wire    [DATAWIDTH-1:0]  WBs_DAT_o           ; // Wishbone Read   Data Bus
//wire    [DATAWIDTH-1:0]  WBs_LCD_DAT_o		 ; 
wire                     WBs_ACK_o           ; // Wishbone Client Acknowledge


// I2C Master Signals
//

//wire                     LCD_Busy_o           ;
wire                     VGA_Intr_o           ;

wire                     SDMA_Req_VGA_o       ;
wire                     SDMA_Sreq_VGA_o      ;
wire                     SDMA_Done_VGA_i      ;
wire                     SDMA_Active_VGA_i    ;

//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//
wire                     Rx_FIFO_Flush      ;
//wire                     Rx_FIFO_Pop        ;
wire                     Rx_FIFO_Empty      ;
//wire                     Rx_FIFO_h_Empty      ;
wire                     Rx_FIFO_Full       ;
//wire              [8:0]  Rx_FIFO_Level      ;
wire              [3:0]  Rx_FIFO_Pop_flag      ;
wire              [3:0]  Rx_FIFO_push_flag      ;

wire                     WBs_ACK_VGA_Reg     ;
wire                     WBs_ACK_VGA_Rx_FIFO ;

wire                     SDMA_Clr;
wire                     SDMA_REQ;
wire                     SDMA_Done_IRQ;
wire 					 SDMA_ena_sig;

wire [31:0] 			 Rx_FIFO_DAT_in_sig;
wire 					 Rx_FIFO_Push;	
wire        			 SDMA_Done_VGA;
wire 					 Rx_fifo_reset;
wire 					 rx_fifo_overflow_detected_sig;

wire [15:0]				 vga_ctrl_reg_sig;
wire [7:0]				 vga_fsm_sts_sig;
wire [10:0]  			 Rx_FIFO_data_cnt_sig;	
wire 					thresh_line_cnt_reached_sig;
wire [9:0]				fc_rcvd_line_cnt_sig;
wire [9:0]				thresh_line_count_dw_sig;
wire 					clear_ena_frame_samp_sig;

wire [31:0] 			Rx_fifo_data_sig;

//------Logic Operations---------------
//

// Acknowledge accesses to each block
//
assign WBs_ACK_o = WBs_ACK_VGA_Reg | WBs_ACK_VGA_Rx_FIFO ;//| WBs_ACK_VGA_Reg | WBs_ACK_LCD_SRAM;


//------Instantiate Modules------------
//


// Define the Storage elements of the Command Queue block
//
// Note: This includes all of the data registers.
//
vga_rx_reg #(

				.ADDRWIDTH                          ( 7                               ),
				.DATAWIDTH                          ( DATAWIDTH                       ),
			
				.IN_VGA_STATUS_REG_ADDR 			( IN_VGA_STATUS_REG_ADDR 			),			 	 
				.IN_VGA_CONTROL_REG_ADR		    ( IN_VGA_CONTROL_REG_ADR		    ),
				.IN_VGA_RX_FIFO_DATCNT_REG_ADR	( IN_VGA_RX_FIFO_DATCNT_REG_ADR	),  
				.IN_VGA_RX_FIFO_LINECNT_REG_ADR   ( IN_VGA_RX_FIFO_LINECNT_REG_ADR  ),
				.IN_VGA_DMA_CONTROL_REG_ADR	    ( IN_VGA_DMA_CONTROL_REG_ADR	    ),
				.IN_VGA_DMA_STATUS_REG_ADR	    ( IN_VGA_DMA_STATUS_REG_ADR	    ),  
				.IN_VGA_RGB_RXDATA_REG_ADR	    ( IN_VGA_RGB_RXDATA_REG_ADR	    ),  
				.IN_VGA_DEBUG_REG_ADR	       	    ( IN_VGA_DEBUG_REG_ADR	       	), 
				 
				.IN_VGA_DEF_REG_VALUE  			( IN_VGA_DEF_REG_VALUE	)
	                                                                      ) 

				u_vga_rx_reg( 

                         // AHB-To_Fabric Bridge I/F
                         //
                         .WBs_CLK_i				( WBs_CLK_i                       ),			
                         .WBs_RST_i				( WBs_RST_i                       ),            
                         .WBs_ADR_i				( WBs_ADR_i[6:0]                  ),       
                         .WBs_CYC_i				( WBs_CYC_i               ),           
                         .WBs_BYTE_STB_i		( WBs_BYTE_STB_i[1:0]             ),            
                         .WBs_WE_i				( WBs_WE_i                        ),            
                         .WBs_STB_i				( WBs_STB_i                       ),            
                         .WBs_DAT_i				( WBs_DAT_i                       ),            
                         .WBs_DAT_o				( WBs_DAT_o                       ),            
                         .WBs_ACK_o				( WBs_ACK_VGA_Reg                 ),  

						 .Rx_fifo_data_i 		(Rx_fifo_data_sig),

                         // LCD control status
						 .fsm_sts_i				    (vga_fsm_sts_sig),
						 .rcvd_line_cnt_i 			(fc_rcvd_line_cnt_sig),
						 
						 .thresh_line_count_dw_o	(thresh_line_count_dw_sig),
						 
						 .vga_interrut_o            (VGA_Intr_o),
	 					 .vga_ctrl_reg_o            (vga_ctrl_reg_sig),
						 .clear_ena_frame_samp_i    (clear_ena_frame_samp_sig),
						 
						 .thresh_line_cnt_reached_i	( thresh_line_cnt_reached_sig	),
						 
						 .rxfifo_overflow_detected_i (rx_fifo_overflow_detected_sig),//( rxfifo_ovrfw_detected_sig	),	
						 .Rx_FIFO_DAT_cnt_i         ( Rx_FIFO_data_cnt_sig),	
						 
                         .Rx_FIFO_Empty_i			( Rx_FIFO_Empty ),					
                         .Rx_FIFO_Full_i			( Rx_FIFO_Full),					
                         .Rx_FIFO_Pop_flag_i		( Rx_FIFO_Pop_flag),
						 .Rx_FIFO_push_flag_i       ( Rx_FIFO_push_flag),
                        					 
                         .Rx_FIFO_Flush_o			( Rx_FIFO_Flush),					
						 						 
						 //DMA
						 .DMA_done_i				( SDMA_Done_VGA ),						
						 .DMA_Done_IRQ_o			( SDMA_Done_IRQ ),						
						 .DMA_active_i				( SDMA_Active_VGA_i ),						
						 .DMA_Clr_i					( SDMA_Clr),							
						 .DMA_REQ_i					( SDMA_REQ),						 	
						 .DMA_ena_o					( SDMA_ena_sig )
                         );
						 
						 
vga_rx_dma_ctrl u_vga_rx_dma_ctrl( 
					.clk_i				( WBs_CLK_i     ),
					.rst_i				( WBs_RST_i     ),
					
					.Rx_FIFO_Full_i	    ( Rx_FIFO_Full ),
					.Rx_FIFO_Empty_i	( Rx_FIFO_Empty ),
					//.Rx_FIFO_DAT_CNT_i  ( Rx_FIFO_data_cnt_sig ),
					.thresh_line_cnt_reached_i	( thresh_line_cnt_reached_sig	),
					
					.DMA_Active_i		( SDMA_Active_VGA_i ),	
                    .ASSP_DMA_Done_i	(SDMA_Done_VGA_i),					
					.DMA_Done_o			( SDMA_Done_VGA ),		
					.DMA_Clr_o			( SDMA_Clr),	
					.DMA_Enable_i		( SDMA_ena_sig )	,
					.DMA_REQ_o			( SDMA_REQ )	  	 				
	

			);						 
						 
//wire [7:0]	LCD_ctrl_reg_sig = {1'b0,sel_0_1_data_sig,Rx_FIFO_Flush,normal_frame_seq_Enable,off_seq_Enable,on_seq_Enable,lcd_fsm_ena,1'b0};


assign  Rx_fifo_reset =  Rx_FIFO_Flush ;
   					 
vga_frame_capture  u_vga_frame_capture( 
					.wb_clk_i					( WBs_CLK_i		),		
					.rst_i	            		( WBs_RST_i		),
					
					.PCLK_i             		( PCLK_i      	),
					.VSYNC_i            		( VSYNC_i       ),
					.HREF_HSYNC_i       		( HREF_HSYNC_i  ),
					.RGB_DAT_i					( RGB_DAT_i		),	
					
					.vga_ctrl_reg_i     		( vga_ctrl_reg_sig  ),
					.vga_fsm_sts_o      		( vga_fsm_sts_sig   ),
					.clear_ena_frame_samp_o     (clear_ena_frame_samp_sig),
					.rx_fifo_overflow_detected_i( rx_fifo_overflow_detected_sig    ),
					
					.rcvd_line_cnt_o 			(fc_rcvd_line_cnt_sig),
					
					.RGB_data_32_o      		( Rx_FIFO_DAT_in_sig ),
					.RGB_Rx_Push_o      		( Rx_FIFO_Push	     )
			    );	

	
						 
vga_rx_fifo_interface #(

				.ADDRWIDTH                          ( 7                               ),
				.DATAWIDTH                          ( DATAWIDTH                       ),
	            .VGA_RGB_RXDATA_REG_ADR             ( IN_VGA_RGB_RXDATA_REG_ADR )                                                         
                    ) 

		u_vga_rx_fifo_interface	(
		
		            .WBs_CLK_i				( WBs_CLK_i                       ),			
                    .WBs_RST_i				( WBs_RST_i                       ),            
                                                            
                    .WBs_ADR_i				( WBs_ADR_i[6:0]                  ),       
                    .WBs_CYC_i				(WBs_CYC_i),//( WBs_CYC_LCD_Tx_FIFO_i           ),           
                    .WBs_BYTE_STB_i		    ( WBs_BYTE_STB_i[1:0]             ),            
                    .WBs_WE_i				( WBs_WE_i                        ),            
                    .WBs_STB_i				( WBs_STB_i                       ),            
                    .WBs_DAT_i				( WBs_DAT_i                 	  ),            
                    .WBs_DAT_o				( Rx_fifo_data_sig                ),            
                    .WBs_ACK_o				( WBs_ACK_VGA_Rx_FIFO             ), 
					
					.PCLK_i					(PCLK_i),
					
					.Rx_FIFO_Flush_i			(Rx_fifo_reset),
					
				    .thresh_line_cnt_reached_o	( thresh_line_cnt_reached_sig	),
					
					//.Rxfifo_ovrfw_detected_o	( rxfifo_ovrfw_detected_sig		),	
					.Rx_FIFO_data_cnt_o         ( Rx_FIFO_data_cnt_sig			),
					
					.thresh_line_count_dw_i		( thresh_line_count_dw_sig ),
															
					.Rx_FIFO_Push_i         	( Rx_FIFO_Push                 ),
					.Rx_FIFO_DAT_i          	( Rx_FIFO_DAT_in_sig           ),
										
					.Rx_overflow_detected_o     ( rx_fifo_overflow_detected_sig ),
				
					.Rx_FIFO_Empty_o        	( Rx_FIFO_Empty                   ),
					.Rx_FIFO_Full_o         	( Rx_FIFO_Full                    ),
					.Rx_FIFO_Pop_flag_o     	( Rx_FIFO_Pop_flag                ),
					.Rx_FIFO_push_flag_o    	( Rx_FIFO_push_flag               )
				);	
						
		
		


	
																		  
assign SDMA_Req_VGA_o = SDMA_REQ;
assign SDMA_Sreq_VGA_o = SDMA_REQ;
assign VGA_DMA_Intr_o = SDMA_Done_IRQ;// | LCD_Load_Done_IRQ;

endmodule
