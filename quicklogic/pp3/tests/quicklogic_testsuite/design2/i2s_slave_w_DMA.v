// -----------------------------------------------------------------------------
// title          : I2S Slave (in RX mode only) with DMA Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : i2s_slave_w_DMA.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2017/03/23	
// last update    : 2017/03/23
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: The I2S Slave (in RX mode only) with DMA is designed for use in the fabric of the
//              AL4S3B. 
// -----------------------------------------------------------------------------
// copyright (c) 2016
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         		  description
// 2017/03/23      1.0        Rakesh Moolacheri  	Initial Release
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps

module i2s_slave_w_DMA ( 

                         // AHB-To_Fabric Bridge I/F
                         //
                         WBs_CLK_i,
                         WBs_RST_i,

                         WBs_ADR_i,

                         WBs_CYC_i,

                         WBs_BYTE_STB_i,
                         WBs_WE_i,
                         WBs_STB_i,
                         WBs_DAT_i,
                         WBs_DAT_o,
                         WBs_ACK_o,

                         I2S_CLK_i,
                         I2S_WS_CLK_i,
                         I2S_DIN_i,

                         I2S_RX_Intr_o, 
                         I2S_DMA_Intr_o, 
						 I2S_Dis_Intr_o,

                         SDMA_Req_I2S_o,
                         SDMA_Sreq_I2S_o,
                         SDMA_Done_I2S_i,
                         SDMA_Active_I2S_i

                         );


//------Port Parameters----------------
//

parameter                ADDRWIDTH                   =   9           ;
parameter                DATAWIDTH                   =  32           ;

parameter                I2S_EN_REG_ADR          	 =  9'h0         ;
parameter                RXFIFO_RST_REG_ADR          =  9'h1         ;
parameter                INTR_STS_REG_ADR          	 =  9'h2         ;
parameter                INTR_EN_REG_ADR          	 =  9'h3         ;
parameter                LFIFO_STS_REG_ADR           =  9'h4         ;
parameter                RFIFO_STS_REG_ADR           =  9'h5         ;
parameter                LFIFO_DAT_REG_ADR           =  9'h6         ;
parameter                RFIFO_DAT_REG_ADR           =  9'h7         ;
parameter                DMA_EN_REG_ADR              =  9'h8         ;
parameter                DMA_STS_REG_ADR             =  9'h9         ;
parameter                DMA_CNT_REG_ADR             =  9'hA         ;
parameter                DMA_DAT_REG_ADR             =  9'hB         ;

parameter                DMA_DEF_REG_VALUE           = 32'hDAD_DEF_AC; // Distinguish access to undefined area


//------Port Signals-------------------
//


// Fabric Global Signals
//
input                    WBs_CLK_i           ; // Fabric Clock               from Fabric
input                    WBs_RST_i           ; // Fabric Reset               to   Fabric


// Wishbone Bus Signals
//
input   [ADDRWIDTH-1:0]  WBs_ADR_i           ; // Address Bus                to   Fabric

input                    WBs_CYC_i   ; // Cycle Chip Select          to   Fabric

input             [3:0]  WBs_BYTE_STB_i      ; // Byte Enable Strobes        to   Fabric
input                    WBs_WE_i            ; // Write Enable               to   Fabric
input                    WBs_STB_i           ; // Strobe Signal              to   Fabric
input   [DATAWIDTH-1:0]  WBs_DAT_i           ; // Write Data Bus             to   Fabric
output  [DATAWIDTH-1:0]  WBs_DAT_o ;

output                   WBs_ACK_o           ; // Transfer Cycle Acknowledge from Fabric

// I2S Slave IF signals
//
input                    I2S_CLK_i       	 ;
input                    I2S_DIN_i       	 ;
input                    I2S_WS_CLK_i   	 ;  

output                   I2S_RX_Intr_o       ;   
output                   I2S_DMA_Intr_o      ;  
output                   I2S_Dis_Intr_o      ;                    

output            		 SDMA_Req_I2S_o      ;
output            		 SDMA_Sreq_I2S_o     ;
input             		 SDMA_Done_I2S_i     ;
input             		 SDMA_Active_I2S_i   ;

                                           

// Fabric Global Signals
//
wire                     WBs_CLK_i           ; // Wishbone Fabric Clock
wire                     WBs_RST_i           ; // Wishbone Fabric Reset

// Wishbone Bus Signals
//
wire    [ADDRWIDTH-1:0]  WBs_ADR_i           ; // Wishbone Address Bus

wire                     WBs_CYC_i   ; // Wishbone Client Cycle  Strobe (i.e. Chip Select to I2C Master)

wire              [3:0]  WBs_BYTE_STB_i      ; // Wishbone Byte   Enable Strobes
wire                     WBs_WE_i            ; // Wishbone Write  Enable Strobe
wire                     WBs_STB_i           ; // Wishbone Transfer      Strobe
wire    [DATAWIDTH-1:0]  WBs_DAT_i           ; // Wishbone Write  Data Bus
 
wire    [DATAWIDTH-1:0]  WBs_DAT_o ;


wire                     WBs_ACK_o           ; // Wishbone Client Acknowledge


wire                    I2S_CLK_i       	 ; 
wire                    I2S_DIN_i       	 ;
wire                    I2S_WS_CLK_i   		 ; 

wire                    I2S_RX_Intr_o       ;   
wire                    I2S_DMA_Intr_o      ; 
wire                    I2S_Dis_Intr_o      ; 

wire              		SDMA_Req_I2S_o      ;
wire             		SDMA_Sreq_I2S_o     ;
wire              		SDMA_Done_I2S_i     ;
wire              		SDMA_Active_I2S_i   ;


//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//
wire                     Rx_FIFO_Flush      ;

wire              [15:0]  L_RXFIFO_DATIN    ;
wire                     L_RXFIFO_PUSH      ;
wire              [15:0]  R_RXFIFO_DATIN    ;
wire                     R_RXFIFO_PUSH      ;

wire              [15:0]  L_RXFIFO_DATOUT   ;
wire                     L_RXFIFO_Pop       ;
wire              [15:0]  R_RXFIFO_DATOUT   ;
wire                     R_RXFIFO_Pop       ;

wire                     LR_RXFIFO_Pop      ;
    
wire              [8:0]  L_Rx_FIFO_Level    ;
wire                     L_Rx_FIFO_Empty    ;
wire                     L_Rx_FIFO_Full     ;

wire              [8:0]  R_Rx_FIFO_Level    ;
wire                     R_Rx_FIFO_Empty    ;
wire                     R_Rx_FIFO_Full     ;

wire					 I2S_S_EN			;

wire					L_RX_DAT_IRQ_EN       ;  
wire					L_RX_DAT_IRQ          ;
wire					I2S_RX_Intr_L ;
wire					I2S_RX_Intr_R ;
    
wire					R_RX_DAT_IRQ_EN       ;  
wire					R_RX_DAT_IRQ          ; 		

wire					I2S_Dis_IRQ_EN       ;  
wire					I2S_Dis_IRQ           ; 
 

wire    [DATAWIDTH-1:0]  WBs_DAT_o_reg      ;
wire                     WBs_CYC_reg        ;
wire                     WBs_ACK_reg        ; // Acknowledge to the system from the register block


wire  					DMA_Busy;
wire  					DMA_Start;
wire 					DMA_Active;
wire					DMA_Done;
wire					SDMA_Req_I2S;
wire					DMA_Clr;

wire  					i2s_clk;

wire					DMA_Done_IRQ_EN;
wire					DMA_Done_IRQ; 

wire              [8:0] DMA_CNT; 

wire              [8:0] dma_cntr; 

wire              [1:0] dma_st;

wire 					i2s_dis;

wire  					STEREO_EN;
wire  					LR_CHNL_SEL;
wire             [31:0] LR_RXFIFO_DAT; 
wire  					LR_Rx_FIFO_Full;
wire  					LR_Rx_FIFO_Empty; 
wire             [8:0]  LR_Rx_FIFO_Level ;
  

//------Logic Operations---------------
//


// Select the source of control signals into the I2C Master from the DMA logic
//
assign WBs_CYC_reg         =    WBs_CYC_i;

// Select the source of control signals from the I2C Master and TxFIFO logic
//
assign WBs_DAT_o =  WBs_DAT_o_reg;


// Determine the final Wishbone bus acknowledge
//
assign WBs_ACK_o           =  WBs_ACK_reg ;	
					   
assign SDMA_Req_I2S_o = SDMA_Req_I2S; 
assign SDMA_Sreq_I2S_o = 1'b0;

assign I2S_RX_Intr_L = (L_RX_DAT_IRQ_EN)? L_RX_DAT_IRQ : 1'b0;
assign I2S_RX_Intr_R = (R_RX_DAT_IRQ_EN)? R_RX_DAT_IRQ : 1'b0;
assign I2S_RX_Intr_o = I2S_RX_Intr_L | I2S_RX_Intr_R; 

assign I2S_DMA_Intr_o = (DMA_Done_IRQ_EN)? DMA_Done_IRQ: 1'b0; 

assign I2S_Dis_Intr_o = (I2S_Dis_IRQ_EN)? I2S_Dis_IRQ: 1'b0; 
     
//------Instantiate Modules------------
//


// I2S_Slave (in RX mode only)
//
i2s_slave_rx                           u_i2s_slave_rx
                                        (
										
	.WBs_CLK_i                          ( WBs_CLK_i                       ),//
    .WBs_RST_i                          ( WBs_RST_i                       ),//
	
    .i2s_clk_i                          ( I2S_CLK_i                       ),    
	.i2s_clk_o                          ( i2s_clk                         ),
    .i2s_ws_clk_i                       ( I2S_WS_CLK_i                    ), 
    .i2s_din_i                          ( I2S_DIN_i                       ), 
	
	.I2S_S_EN_i                       	( I2S_S_EN                        ),
	
	.i2s_dis_o                       	( i2s_dis                         ),

    .data_left_o                        ( L_RXFIFO_DATIN                  ),   
    .data_right_o                       ( R_RXFIFO_DATIN                  ),

    .push_left_o                        ( L_RXFIFO_PUSH                   ),
    .push_right_o                       ( R_RXFIFO_PUSH                   )
    );
 
	
i2s_slave_w_DMA_registers             #(

    .ADDRWIDTH                          ( ADDRWIDTH                       ),
    .DATAWIDTH                          ( DATAWIDTH                       ),

    .I2S_EN_REG_ADR                 	( I2S_EN_REG_ADR	              ),
    .RXFIFO_RST_REG_ADR                	( RXFIFO_RST_REG_ADR              ),
	.INTR_STS_REG_ADR                	( INTR_STS_REG_ADR         	      ),
	.INTR_EN_REG_ADR                	( INTR_EN_REG_ADR                 ),
	.LFIFO_STS_REG_ADR                	( LFIFO_STS_REG_ADR               ),
	.RFIFO_STS_REG_ADR                	( RFIFO_STS_REG_ADR               ),
	.LFIFO_DAT_REG_ADR                	( LFIFO_DAT_REG_ADR               ),
	.RFIFO_DAT_REG_ADR                	( RFIFO_DAT_REG_ADR               ),
	.DMA_EN_REG_ADR                		( DMA_EN_REG_ADR                  ),
	.DMA_STS_REG_ADR                	( DMA_STS_REG_ADR                 ),
	.DMA_CNT_REG_ADR                	( DMA_CNT_REG_ADR                 ),
	.DMA_DAT_REG_ADR                	( DMA_DAT_REG_ADR                 ),
	
    .DMA_DEF_REG_VALUE                  ( DMA_DEF_REG_VALUE               )
	                                                                      )
                                          u_i2s_slave_w_DMA_registers 
                                        ( 
    .WBs_CLK_i                          ( WBs_CLK_i                       ),//
    .WBs_RST_i                          ( WBs_RST_i                       ),//

    .WBs_ADR_i                          ( WBs_ADR_i[ADDRWIDTH-1:0]        ),//
    .WBs_CYC_i                          ( WBs_CYC_reg                     ),//
    .WBs_BYTE_STB_i                     ( WBs_BYTE_STB_i[2:0]             ),//
    .WBs_WE_i                           ( WBs_WE_i                        ),//
    .WBs_STB_i                          ( WBs_STB_i                       ),//
    .WBs_DAT_i                          ( WBs_DAT_i                       ),//
    .WBs_DAT_o                          ( WBs_DAT_o_reg                   ),//
    .WBs_ACK_o                          ( WBs_ACK_reg                     ),//
	
	.i2s_dis_i                       	( i2s_dis                         ),
	.I2S_S_EN_o                       	( I2S_S_EN                        ),
	.Rx_FIFO_Flush_o                    ( Rx_FIFO_Flush                   ),
	
	.L_RXFIFO_DAT_i                     ( L_RXFIFO_DATOUT                 ),
	.L_RXFIFO_Pop_o                     ( L_RXFIFO_Pop                    ),
	
	.R_RXFIFO_DAT_i                     ( R_RXFIFO_DATOUT                 ),
	.R_RXFIFO_Pop_o                     ( R_RXFIFO_Pop                    ),
	
	.LR_RXFIFO_Pop_o                    ( LR_RXFIFO_Pop                   ),//DMA
	
	.STEREO_EN_o                        ( STEREO_EN                       ),
	.LR_CHNL_SEL_o                      ( LR_CHNL_SEL                     ),
	.LR_RXFIFO_DAT_i                    ( LR_RXFIFO_DAT                   ),
	.LR_Rx_FIFO_Full_i                  ( LR_Rx_FIFO_Full                 ),
	.LR_Rx_FIFO_Empty_i                 ( LR_Rx_FIFO_Empty                ),
	.LR_Rx_FIFO_Level_i                 ( LR_Rx_FIFO_Level                ),
	
	.L_Rx_FIFO_Empty_i                  ( L_Rx_FIFO_Empty                 ),
	.L_Rx_FIFO_Full_i                   ( L_Rx_FIFO_Full                  ),
	.L_Rx_FIFO_Level_i                  ( L_Rx_FIFO_Level                 ),
	
	.R_Rx_FIFO_Empty_i                  ( R_Rx_FIFO_Empty                 ),
	.R_Rx_FIFO_Full_i                   ( R_Rx_FIFO_Full                  ),
	.R_Rx_FIFO_Level_i                  ( R_Rx_FIFO_Level                 ),
	
	.L_RX_DAT_IRQ_o                     ( L_RX_DAT_IRQ                    ),// 
	.L_RX_DAT_IRQ_EN_o                  ( L_RX_DAT_IRQ_EN                 ),// 
	
	.R_RX_DAT_IRQ_o                     ( R_RX_DAT_IRQ                    ),//
	.R_RX_DAT_IRQ_EN_o                  ( R_RX_DAT_IRQ_EN                 ),// 
	
	.I2S_Dis_IRQ_o                      ( I2S_Dis_IRQ                     ),//
	.I2S_Dis_IRQ_EN_o                   ( I2S_Dis_IRQ_EN                  ),// 
	
	.DMA_Busy_i                         ( DMA_Busy                        ),//
	.DMA_Clr_i                          ( DMA_Clr                         ),//
	.DMA_Done_i                         ( DMA_Done                        ),//
	.DMA_Active_i                       ( DMA_Active            		  ),//
	.DMA_REQ_i                          ( SDMA_Req_I2S            		  ),//
	
	.DMA_CNT_o                          ( DMA_CNT                		  ),//
	
	.dma_cntr_i                       	( dma_cntr                        ),
	.dma_st_i                           ( dma_st                          ),
	
	.DMA_Start_o                       	( DMA_Start                       ),//
	.DMA_Done_IRQ_o                     ( DMA_Done_IRQ                    ),//
	.DMA_Done_IRQ_EN_o                  ( DMA_Done_IRQ_EN                 )
    );
			
  
  
//RX FIFO block
i2s_slave_Rx_FIFOs                u_i2s_slave_Rx_FIFOs
                                        (
    .i2s_clk_i                          ( i2s_clk                         ), 
	
    .WBs_CLK_i                          ( WBs_CLK_i                       ), 
    .WBs_RST_i                          ( WBs_RST_i                       ), 

    .Rx_FIFO_Flush_i                    ( Rx_FIFO_Flush                   ),
	
    .L_RXFIFO_DAT_i                     ( L_RXFIFO_DATIN                  ), 
	.L_RXFIFO_PUSH_i                    ( L_RXFIFO_PUSH                   ),
	
	.R_RXFIFO_DAT_i                     ( R_RXFIFO_DATIN                  ),
	.R_RXFIFO_PUSH_i                    ( R_RXFIFO_PUSH                   ),
	
	.L_RXFIFO_DAT_o                     ( L_RXFIFO_DATOUT                 ),
	.L_RXFIFO_Pop_i                     ( L_RXFIFO_Pop                    ),
	
	.R_RXFIFO_DAT_o                     ( R_RXFIFO_DATOUT                 ),
	.R_RXFIFO_Pop_i                     ( R_RXFIFO_Pop                    ),
	
	.STEREO_EN_i                        ( STEREO_EN                       ),
	.LR_CHNL_SEL_i                      ( LR_CHNL_SEL                     ),
	.LR_RXFIFO_DAT_o                    ( LR_RXFIFO_DAT                   ),
	.LR_Rx_FIFO_Full_o                  ( LR_Rx_FIFO_Full                 ),
	.LR_Rx_FIFO_Empty_o                 ( LR_Rx_FIFO_Empty                ),
	.LR_Rx_FIFO_Level_o                 ( LR_Rx_FIFO_Level                ),
	
	.LR_RXFIFO_Pop_i                    ( LR_RXFIFO_Pop                   ),
	
	.DMA_Busy_i                         ( DMA_Busy                        ),
	
	.L_Rx_FIFO_Empty_o                  ( L_Rx_FIFO_Empty                 ),
	.L_Rx_FIFO_Full_o                   ( L_Rx_FIFO_Full                  ),
	.L_Rx_FIFO_Level_o                  ( L_Rx_FIFO_Level                 ),

	.R_Rx_FIFO_Empty_o                  ( R_Rx_FIFO_Empty                 ),
	.R_Rx_FIFO_Full_o                   ( R_Rx_FIFO_Full                  ),
	.R_Rx_FIFO_Level_o                  ( R_Rx_FIFO_Level                 )
	);
							 
										
//
// Instantiate the DMA logic below
//
i2s_slave_w_DMA_StateMachine        u_i2s_slave_w_DMA_StateMachine
                                        ( 

    .WBs_CLK_i                           ( WBs_CLK_i                       ),//
    .WBs_RST_i                           ( WBs_RST_i                       ),//

	.DMA_Clr_o                   		 ( DMA_Clr                         ),//
	
	.DMA_REQ_o                   		 ( SDMA_Req_I2S		               ),//
	.DMA_DONE_o                   		 ( DMA_Done                  	   ),//
	.DMA_Active_i                    	 ( SDMA_Active_I2S_i               ),//
	.DMA_Active_o                    	 ( DMA_Active                      ),//

    .LR_RXFIFO_Pop_i                     ( LR_RXFIFO_Pop                   ),
	
	.DMA_CNT_i                           ( DMA_CNT                		  ),//

    .DMA_Start_i                       	 ( DMA_Start                       ),
	.I2S_S_EN_i                       	 ( I2S_S_EN                        ),
	
	.dma_cntr_o                       	 ( dma_cntr                        ),
	.dma_st_o                       	 ( dma_st                          ),
    .DMA_Busy_o                          ( DMA_Busy                        )
                                                                          );  

endmodule
