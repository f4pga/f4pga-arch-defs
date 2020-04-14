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
// 2018/01/29	   1.1        Anand A Wadke         Modified for FIR decimator
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps
//`define AEC_1_0
`define ACSLIP_USE_I2S_BITCLK
module i2s_slave_w_DMA ( 

                         // AHB-To_Fabric Bridge I/F
                         //
                         WBs_CLK_i,
                         WBs_RST_i,

                         WBs_ADR_i,

                         WBs_CYC_i,
						 WBs_CYC_I2S_PREDECI_RAM_i,
						 WBs_CYC_FIR_COEFF_RAM_i,  

                         WBs_BYTE_STB_i,
                         WBs_WE_i,
                         WBs_STB_i,
                         WBs_DAT_i,
                         WBs_DAT_o,
						 WBs_COEF_RAM_DAT_o,
                         WBs_ACK_o,
						 
						 sys_ref_clk_i,//Sys_clk0  

                         I2S_CLK_i,
                         I2S_WS_CLK_i,
                         I2S_DIN_i,

                         I2S_RX_Intr_o, 
                         I2S_DMA_Intr_o, 
						 I2S_Dis_Intr_o,
						 
						 //FIR interface
						 i2s_clk_o,
						 
						 FIR_DATA_RaDDR_i,
						 FIR_RD_DATA_o,		
						 FIR_ena_o,
						 
						 wb_Coeff_RAM_aDDR_o,
						 wb_Coeff_RAM_Wen_o,
						 wb_Coeff_RAM_Data_o,
						 wb_Coeff_RAM_Data_i,
						 wb_Coeff_RAM_rd_access_ctrl_o,
						 
						 FIR_DECI_DATA_i,
						 FIR_DECI_DATA_PUSH_i,	

                         FIR_I2S_RXRAM_w_Addr_o,
						 FIR_I2S_RXRAM_w_ena_o,
                         i2s_Clock_Stoped_o,
						 
                         FIR_DECI_Done_i,		

                         sys_c21_div16_o,						 
                         i2s_clk_div3_o,						 

                         SDMA_Req_I2S_o,
                         SDMA_Sreq_I2S_o,
                         SDMA_Done_I2S_i,
                         SDMA_Active_I2S_i

                         );


//------Port Parameters----------------
//

parameter                ADDRWIDTH                   =   9           ;
parameter                DATAWIDTH                   =  32           ;

parameter                I2S_EN_REG_ADR          	 =  10'h0         ;
parameter                ACSLIP_REG_RST_ADR          =  10'h1         ;
parameter                INTR_STS_REG_ADR          	 =  10'h2         ;
parameter                INTR_EN_REG_ADR          	 =  10'h3         ;
parameter                DECI_FIFO_STS_REG_ADR       =  10'h4         ;
parameter                DECI_FIFO_DATA_REG_ADR		 =  10'h5         ;
parameter                ACSLIP_REG_ADR              =  10'h6         ;
parameter                DECI_FIFO_RST_ADR           =  10'h7         ;
parameter                DMA_EN_REG_ADR              =  10'h8         ;
parameter                DMA_STS_REG_ADR             =  10'h9         ;
parameter                DMA_CNT_REG_ADR             =  10'hA         ;
parameter                ACSLIP_TIMER_REG_ADR            =  10'hB         ;
parameter                FIR_DECI_CNTRL_REG_ADR      =  10'hC         ;
parameter                RESERVED_2             =  10'hD         ;
parameter                FIR_PREDECI_RAM_STRT_ADDR1  =  10'h200       ;
parameter                FIR_PREDECI_RAM_STRT_ADDR2  =  10'h000       ;
parameter                FIR_COEFF_RAM_ADDR1         =  10'h200       ;
parameter                RESERVED_3                  =  10'hB         ;

parameter                DMA_DEF_REG_VALUE           = 32'hDAD_DEF_AC; // Distinguish access to undefined area

parameter                ACSLIP_REG_WIDTH            = 32;
//------Port Signals-------------------
//


// Fabric Global Signals
//
input                    WBs_CLK_i           ; // Fabric Clock               from Fabric
input                    WBs_RST_i           ; // Fabric Reset               to   Fabric


// Wishbone Bus Signals
//
//input   [ADDRWIDTH-1:0]  WBs_ADR_i           ; // Address Bus                to   Fabric
input   [ADDRWIDTH:0]  WBs_ADR_i           ; // Address Bus                to   Fabric

input                    WBs_CYC_i   ; // Cycle Chip Select          to   Fabric
input                    WBs_CYC_I2S_PREDECI_RAM_i   ; // Cycle Chip Select          to   Fabric  
input                    WBs_CYC_FIR_COEFF_RAM_i      ; // Cycle Chip Select          to   Fabric    

input             [3:0]  WBs_BYTE_STB_i      ; // Byte Enable Strobes        to   Fabric
input                    WBs_WE_i            ; // Write Enable               to   Fabric
input                    WBs_STB_i           ; // Strobe Signal              to   Fabric
input   [DATAWIDTH-1:0]  WBs_DAT_i           ; // Write Data Bus             to   Fabric
output  [DATAWIDTH-1:0]  WBs_DAT_o ;
output  [DATAWIDTH-1:0]  WBs_COEF_RAM_DAT_o ;

output                   WBs_ACK_o           ; // Transfer Cycle Acknowledge from Fabric


input 					sys_ref_clk_i;
// I2S Slave IF signals
//
input                    I2S_CLK_i       	 ;
input                    I2S_DIN_i       	 ;
input                    I2S_WS_CLK_i   	 ;  

output                   I2S_RX_Intr_o       ;   
output                   I2S_DMA_Intr_o      ;  
output                   I2S_Dis_Intr_o      ; 

output					 i2s_clk_o; 

input 	[8:0]  			 FIR_DATA_RaDDR_i;
output 	[15:0]  		 FIR_RD_DATA_o;
output 	 		 		 FIR_ena_o;

output  [8:0]  			 wb_Coeff_RAM_aDDR_o;		
output 					 wb_Coeff_RAM_Wen_o;
output  [15:0] 			 wb_Coeff_RAM_Data_o;
input  [15:0] 			 wb_Coeff_RAM_Data_i;
output                   wb_Coeff_RAM_rd_access_ctrl_o;


input 	[15:0]  		 FIR_DECI_DATA_i;
input 					 FIR_DECI_DATA_PUSH_i;
input 					 FIR_DECI_Done_i;

output 					 sys_c21_div16_o;
output 				     i2s_clk_div3_o;
                  

output            		 SDMA_Req_I2S_o      ;
output            		 SDMA_Sreq_I2S_o     ;
input             		 SDMA_Done_I2S_i     ;
input             		 SDMA_Active_I2S_i   ;

output 	[8:0]            FIR_I2S_RXRAM_w_Addr_o;
output                   FIR_I2S_RXRAM_w_ena_o;
output                   i2s_Clock_Stoped_o;
                                           

// Fabric Global Signals
//
wire                     WBs_CLK_i           ; // Wishbone Fabric Clock
wire                     WBs_RST_i           ; // Wishbone Fabric Reset

// Wishbone Bus Signals
//
//wire    [ADDRWIDTH-1:0]  WBs_ADR_i           ; // Wishbone Address Bus
wire    [ADDRWIDTH:0]  WBs_ADR_i           ; // Wishbone Address Bus

wire                     WBs_CYC_i   ; // Wishbone Client Cycle  Strobe (i.e. Chip Select to I2C Master)
wire                     WBs_CYC_I2S_PREDECI_RAM_i    ; // Wishbone Client Cycle  Strobe (i.e. Chip Select to I2C Master)
wire                     WBs_CYC_FIR_COEFF_RAM_i      ; // Wishbone Client Cycle  Strobe (i.e. Chip Select to I2C Master)

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
wire                     DeciData_Rx_FIFO_Flush      ;
//From I2S deserializer block
wire              [15:0]  L_RXFIFO_DATIN    ;
wire                      L_RXFIFO_PUSH      ;
wire              [15:0]  R_RXFIFO_DATIN    ;
wire                      R_RXFIFO_PUSH      ;

wire                     DeciData_RXFIFO_Pop_sig      ;
wire              [15:0] DeciData_RXFIFO_DAT_sig      ;

 
wire              [8:0]  DeciData_Rx_FIFO_Level_sig    ;
wire              [3:0]  DeciData_Rx_FIFO_Empty_flag_sig    ;
wire                     DeciData_Rx_FIFO_Empty    ;
wire                     DeciData_Rx_FIFO_Full     ;

wire					 I2S_S_EN			;

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

wire                    DECIMATION_EN_sig;
wire [8:0]              L_PREDECI_RXRAM_w_Addr_sig;

wire [8:0]			   wb_FIR_L_PreDeci_RAM_aDDR_sig;			
wire				   wb_FIR_L_PreDeci_RAM_Wen_sig;			
wire				   wb_FIR_L_PREDECI_RAM_wrMASTER_CTRL_sig;	

wire				  Deci_Done_IRQ_EN_sig	;		 
wire				  Deci_Done_IRQ_sig		;		 
wire				  DeciData_Rx_DAT_AVL_IRQ_EN_sig ;
wire				  DeciData_Rx_DAT_AVL_IRQ_sig  ; 
wire                  ACSLIP_timer_IRQ_EN_sig;
wire                  ACSLIP_timer_IRQ_sig;


//wire      [9:0]      ACLSIP_Reg_sig;
wire      [ACSLIP_REG_WIDTH-1:0]      ACLSIP_Reg_sig;

wire                 ACSLIP_Reg_Rst_sig;
wire 				 ACSLIP_EN_sig;

wire 				 sys_ref_clk_16khz_sig;

//AEC1.0 For Debug
wire              [31:0]  cnt_mic_dat_sig ;
wire              [31:0]  cnt_i2s_dat_sig ;


     

//------Logic Operations---------------
//
assign sys_c21_div16_o = sys_ref_clk_16khz_sig;

assign i2s_clk_o = i2s_clk;

assign FIR_I2S_RXRAM_w_Addr_o = L_PREDECI_RXRAM_w_Addr_sig;

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

//assign I2S_RX_Intr_L = (L_RX_DAT_IRQ_EN)? L_RX_DAT_IRQ : 1'b0;
//assign I2S_RX_Intr_R = (R_RX_DAT_IRQ_EN)? R_RX_DAT_IRQ : 1'b0;
//assign I2S_RX_Intr_o  = I2S_RX_Intr_L | I2S_RX_Intr_R; 
assign I2S_RX_Intr_o  = 	(Deci_Done_IRQ_EN_sig 			& Deci_Done_IRQ_sig) 			| 
							(DeciData_Rx_DAT_AVL_IRQ_EN_sig & DeciData_Rx_DAT_AVL_IRQ_sig) 	|
							(ACSLIP_timer_IRQ_EN_sig 		& ACSLIP_timer_IRQ_sig) ; 

assign I2S_DMA_Intr_o = (DMA_Done_IRQ_EN)? DMA_Done_IRQ: 1'b0; 

assign I2S_Dis_Intr_o = (I2S_Dis_IRQ_EN)? I2S_Dis_IRQ: 1'b0; 

//assign FIR_ena_o      = DECIMATION_EN_sig;

assign i2s_Clock_Stoped_o = i2s_dis ;
     
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

	.I2S_EN_REG_ADR  					( I2S_EN_REG_ADR             ),            
	.ACSLIP_REG_RST_ADR                 ( ACSLIP_REG_RST_ADR         ),
	.INTR_STS_REG_ADR                   ( INTR_STS_REG_ADR           ),
	.INTR_EN_REG_ADR                    ( INTR_EN_REG_ADR            ),
    .DECI_FIFO_STS_REG_ADR 				( DECI_FIFO_STS_REG_ADR       ), 
	.DECI_FIFO_DATA_REG_ADR		    	( DECI_FIFO_DATA_REG_ADR	  ),
	.ACSLIP_REG_ADR                 	( ACSLIP_REG_ADR              ),
	.DECI_FIFO_RST_ADR              	( DECI_FIFO_RST_ADR           ),
	.DMA_EN_REG_ADR                 	( DMA_EN_REG_ADR              ),
	.DMA_STS_REG_ADR                	( DMA_STS_REG_ADR             ),
	.DMA_CNT_REG_ADR                	( DMA_CNT_REG_ADR             ),
	.ACSLIP_TIMER_REG_ADR                   ( ACSLIP_TIMER_REG_ADR                  ),
	.FIR_DECI_CNTRL_REG_ADR         	( FIR_DECI_CNTRL_REG_ADR      ),
	.RESERVED_2                	( RESERVED_2             ),
	.FIR_PREDECI_RAM_STRT_ADDR1     	( FIR_PREDECI_RAM_STRT_ADDR1  ),
	.FIR_PREDECI_RAM_STRT_ADDR2     	( FIR_PREDECI_RAM_STRT_ADDR2  ),
	.FIR_COEFF_RAM_ADDR1            	( FIR_COEFF_RAM_ADDR1         ),
	.RESERVED_3                     	( RESERVED_3                  ),
	
	.ACSLIP_REG_WIDTH					(ACSLIP_REG_WIDTH),
	
    .DMA_DEF_REG_VALUE                  ( DMA_DEF_REG_VALUE               )
	                                                                      )
                                          u_i2s_slave_w_DMA_registers 
                                        ( 
    .WBs_CLK_i                          ( WBs_CLK_i                       ),//
    .WBs_RST_i                          ( WBs_RST_i                       ),//

`ifdef ACSLIP_USE_I2S_BITCLK	
	.sys_ref_clk_i					    (i2s_clk_div3_o),
`else	
	.sys_ref_clk_i					    (sys_ref_clk_16khz_sig),
`endif	

    //.WBs_ADR_i                          ( WBs_ADR_i[ADDRWIDTH-1:0]        ),//
    .WBs_ADR_i                          ( WBs_ADR_i[ADDRWIDTH:0]        ),//
    .WBs_CYC_i                          ( WBs_CYC_reg                     ),//
	.WBs_CYC_I2S_PREDECI_RAM_i 			( WBs_CYC_I2S_PREDECI_RAM_i   ),
	.WBs_CYC_FIR_COEFF_RAM_i            ( WBs_CYC_FIR_COEFF_RAM_i     ),
	
    .WBs_BYTE_STB_i                     ( WBs_BYTE_STB_i[2:0]             ),//
    .WBs_WE_i                           ( WBs_WE_i                        ),//
    .WBs_STB_i                          ( WBs_STB_i                       ),//
    .WBs_DAT_i                          ( WBs_DAT_i                       ),//
    .WBs_DAT_o                          ( WBs_DAT_o_reg                   ),//
	.WBs_COEF_RAM_DAT_o					(WBs_COEF_RAM_DAT_o),
    .WBs_ACK_o                          ( WBs_ACK_reg                     ),//
	
	.i2s_dis_i                       	( i2s_dis                         ),
	.I2S_S_EN_o                       	( I2S_S_EN                        ),
	.ACSLIP_EN_o                       	( ACSLIP_EN_sig                        ),
	
	.ACSLIP_Reg_Rst_o                   ( ACSLIP_Reg_Rst_sig        ),//Add Logic
	.ACLSIP_Reg_i                   	( ACLSIP_Reg_sig        ),//Add Logic
	
`ifdef AEC_1_0	 						
	.cnt_mic_dat_i 						( cnt_mic_dat_sig    ),
	.cnt_i2s_dat_i 						( cnt_i2s_dat_sig    ),
`endif		
	
	
	
	.wb_FIR_L_PreDeci_RAM_aDDR_o		( wb_FIR_L_PreDeci_RAM_aDDR_sig				),
	.wb_FIR_L_PreDeci_RAM_Wen_o			( wb_FIR_L_PreDeci_RAM_Wen_sig				),		
	.wb_FIR_L_PreDeci_RAM_wrMASTER_CTRL_o	( wb_FIR_L_PREDECI_RAM_wrMASTER_CTRL_sig		),	
	
	.wb_Coeff_RAM_aDDR_o				( wb_Coeff_RAM_aDDR_o	),
	.wb_Coeff_RAM_Wen_o					( wb_Coeff_RAM_Wen_o	),
	.wb_Coeff_RAM_Data_o				( wb_Coeff_RAM_Data_o	),
	.wb_Coeff_RAM_Data_i				( wb_Coeff_RAM_Data_i	),
	.wb_Coeff_RAM_rd_access_ctrl_o				( wb_Coeff_RAM_rd_access_ctrl_o),
	
	//FIR decimator	
	.FIR_DECI_Done_i                    ( FIR_DECI_Done_i  ),
	.FIR_ena_o                          ( FIR_ena_o  ),
	
	.DeciData_Rx_FIFO_Flush_o           ( DeciData_Rx_FIFO_Flush         ),
	
	.DeciData_Rx_FIFO_Pop_o             ( DeciData_RXFIFO_Pop_sig        ),//DMA
	.DeciData_Rx_FIFO_DAT_i             ( DeciData_RXFIFO_DAT_sig        ),
	.DeciData_Rx_FIFO_Full_i            ( DeciData_Rx_FIFO_Full          ),
	.DeciData_Rx_FIFO_Empty_i           ( DeciData_Rx_FIFO_Empty         ),
	.DeciData_Rx_FIFO_Level_i           ( DeciData_Rx_FIFO_Level_sig         ),
	.DeciData_Rx_FIFO_Empty_flag_i      ( DeciData_Rx_FIFO_Empty_flag_i         ),

    .Deci_Done_IRQ_EN_o					( Deci_Done_IRQ_EN_sig			 ),   
    .Deci_Done_IRQ_o					( Deci_Done_IRQ_sig				 ),			
    .DeciData_Rx_DAT_AVL_IRQ_EN_o		( DeciData_Rx_DAT_AVL_IRQ_EN_sig ),   
    .DeciData_Rx_FIFO_DAT_IRQ_o			( DeciData_Rx_DAT_AVL_IRQ_sig   ),//L_RX_DAT_IRQ_o_
	
	.ACSLIP_timer_IRQ_EN_o				( ACSLIP_timer_IRQ_EN_sig	),
	.ACSLIP_timer_IRQ_o					( ACSLIP_timer_IRQ_sig      ),
	
	.DMA_Busy_i                         ( DMA_Busy                        ),//
	.DMA_Clr_i                          ( DMA_Clr                         ),//
	.DMA_Done_i                         ( DMA_Done                        ),//
	.DMA_Active_i                       ( DMA_Active            		  ),//
	.DMA_REQ_i                          ( SDMA_Req_I2S            		  ),//
	.dma_cntr_i                       	( dma_cntr                        ),
	.dma_st_i                           ( dma_st                          ),
	
	.I2S_Dis_IRQ_o                      ( I2S_Dis_IRQ                     ),//
	.I2S_Dis_IRQ_EN_o                   ( I2S_Dis_IRQ_EN                  ),// 	
	
	.DMA_CNT_o                          ( DMA_CNT                		  ),//
	.DMA_Start_o                       	( DMA_Start                       ),//
	.DMA_Done_IRQ_o                     ( DMA_Done_IRQ                    ),//
	.DMA_Done_IRQ_EN_o                  ( DMA_Done_IRQ_EN                 )


	//.L_RX_DAT_IRQ_o                     ( L_RX_DAT_IRQ                    ),// 
	//.L_RX_DAT_IRQ_EN_o                  ( L_RX_DAT_IRQ_EN                 ),// 
	//.R_RX_DAT_IRQ_o                     ( R_RX_DAT_IRQ                    ),//
	//.R_RX_DAT_IRQ_EN_o                  ( R_RX_DAT_IRQ_EN                 ),// 	
	//.L_RXFIFO_DAT_i                     ( L_RXFIFO_DATOUT                 ),
	//.L_RXFIFO_Pop_o                     ( L_RXFIFO_Pop                    ),
	//.R_RXFIFO_DAT_i                     ( R_RXFIFO_DATOUT                 ),
	//.R_RXFIFO_Pop_o                     ( R_RXFIFO_Pop                    ),	
	//.STEREO_EN_o                        ( STEREO_EN                       ),
	//.LR_CHNL_SEL_o                      ( LR_CHNL_SEL                     ),
	//.L_Rx_FIFO_Empty_i                  ( DeciData_Rx_FIFO_Empty                 ),
	//.L_Rx_FIFO_Full_i                   ( L_Rx_FIFO_Full                  ),
	//.L_Rx_FIFO_Level_i                  ( L_Rx_FIFO_Level                 ),
	//.R_Rx_FIFO_Empty_i                  ( R_Rx_FIFO_Empty                 ),
	//.R_Rx_FIFO_Full_i                   ( R_Rx_FIFO_Full                  ),
	//.R_Rx_FIFO_Level_i                  ( R_Rx_FIFO_Level                 ),	
	
    );
			
  
  
//RX FIFO block
i2s_slave_Rx_FIFOs                u_i2s_slave_Rx_FIFOs_inst0
                                        (
    .i2s_clk_i                          ( i2s_clk                         ), 
    .WBs_CLK_i                          ( WBs_CLK_i                       ), 
    .WBs_RST_i                          ( WBs_RST_i                       ), 

    .Deci_Rx_FIFO_Flush_i               ( DeciData_Rx_FIFO_Flush                   ),
	
    .L_PreDeci_RXRAM_DAT_i              ( L_RXFIFO_DATIN                  ), 
	.L_PreDeci_RXRAM_WR_i               ( L_RXFIFO_PUSH                   ),
	
    .FIR_L_PreDeci_DATA_RaDDR_i		    (  FIR_DATA_RaDDR_i ),	
	.FIR_L_PreDeci_RD_DATA_o			(  FIR_RD_DATA_o ),
		
	.L_PreDeci_RXRAM_w_Addr_o	 	    ( L_PREDECI_RXRAM_w_Addr_sig ),	
	.L_PreDeci_I2S_RXRAM_w_ena_o        ( FIR_I2S_RXRAM_w_ena_o ),
    .i2s_Clock_Stopped_i			    ( i2s_dis ),
	
	.wb_FIR_L_PreDeci_RAM_aDDR_i    	    ( wb_FIR_L_PreDeci_RAM_aDDR_sig				),
	.wb_FIR_L_PreDeci_RAM_Wen_i			    ( wb_FIR_L_PreDeci_RAM_Wen_sig				),	
	.wb_FIR_L_PreDeci_RAM_wrMASTER_CTRL_i	( wb_FIR_L_PREDECI_RAM_wrMASTER_CTRL_sig		),	
	
	.FIR_Deci_DATA_i		 		    ( FIR_DECI_DATA_i ),
	.FIR_Deci_DATA_PUSH_i 		        ( FIR_DECI_DATA_PUSH_i ),	

	.DeciData_RXFIFO_Pop_i              ( DeciData_RXFIFO_Pop_sig                   ),//LR_RXFIFO_Pop_	
	.DeciData_RXFIFO_DAT_o				( DeciData_RXFIFO_DAT_sig ),
	
	.DeciData_Rx_FIFO_Empty_o           ( DeciData_Rx_FIFO_Empty        ),//L_Rx_FIFO_Empty_
	.DeciData_Rx_FIFO_Full_o            ( DeciData_Rx_FIFO_Full         ),//L_Rx_FIFO_Full_o_,
	.DeciData_Rx_FIFO_Level_o           ( DeciData_Rx_FIFO_Level_sig    ), //L_Rx_FIFO_Level_o_	
	.DeciData_Rx_FIFO_Empty_flag_o      ( DeciData_Rx_FIFO_Empty_flag_sig         ) 	
 	

	//.R_RXFIFO_DAT_i                     ( R_RXFIFO_DATIN                  ),
	//.R_RXFIFO_PUSH_i                    ( R_RXFIFO_PUSH                   ),
	//.L_RXFIFO_DAT_o                     ( L_RXFIFO_DATOUT                 ),
	//.L_RXFIFO_Pop_i                     ( L_RXFIFO_Pop                    ),
	//.R_RXFIFO_DAT_o                     ( R_RXFIFO_DATOUT                 ),
	//.R_RXFIFO_Pop_i                     ( R_RXFIFO_Pop                    ),
	//.STEREO_EN_i                        ( STEREO_EN                       ),
	//.LR_CHNL_SEL_i                      ( LR_CHNL_SEL                     ),
	//.LR_RXFIFO_DAT_o                    ( LR_RXFIFO_DAT                   ),
	//.LR_Rx_FIFO_Full_o                  ( LR_Rx_FIFO_Full                 ),
	//.LR_Rx_FIFO_Empty_o                 ( LR_Rx_FIFO_Empty                ),
	//.LR_Rx_FIFO_Level_o                 ( LR_Rx_FIFO_Level                ),
	//.DMA_Busy_i                         ( DMA_Busy                        ),
	//.R_Rx_FIFO_Empty_o                  ( R_Rx_FIFO_Empty                 ),
	//.R_Rx_FIFO_Full_o                   ( R_Rx_FIFO_Full                  ),
	//.R_Rx_FIFO_Level_o                  ( R_Rx_FIFO_Level                 )
	);


//	
										
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

    .LR_RXFIFO_Pop_i                     ( DeciData_RXFIFO_Pop_sig                   ),
	
	.DMA_CNT_i                           ( DMA_CNT                		  ),//

    .DMA_Start_i                       	 ( DMA_Start                       ),
	//.I2S_S_EN_i                       	 ( I2S_S_EN                        ),
	.I2S_S_EN_i                       	 ( I2S_S_EN  | FIR_ena_o                      ),
	
	.dma_cntr_o                       	 ( dma_cntr                        ),
	.dma_st_o                       	 ( dma_st                          ),
    .DMA_Busy_o                          ( DMA_Busy                        )
                                                                          );  
																		  
																		  

fll_acslip # (
			  .ACSLIP_REG_WIDTH					(ACSLIP_REG_WIDTH)
			  ) 	
			  fll_acslip_inst0(
							.wbs_clk_i			( WBs_CLK_i  ),
							.wbs_rst_i			( WBs_RST_i  ),		
                            .ACSLIP_EN_i        ( ACSLIP_EN_sig                        ),  							
							                    
							.sys_ref_clk_i	      ( sys_ref_clk_i ),
							
							.sys_ref_clk_16khz_o  (sys_ref_clk_16khz_sig),
							.i2s_clk_div3_o       (i2s_clk_div3_o),
							                  
							.i2s_clk_i		      ( I2S_CLK_i  ),
							.i2s_ws_clk_i		  ( I2S_WS_CLK_i  ),
							                   
							.ACSLIP_Reg_Rst_i	  ( ACSLIP_Reg_Rst_sig  ),
							.i2s_en_i			  (I2S_S_EN),
`ifdef AEC_1_0	 						
							.cnt_mic_dat_o 			( cnt_mic_dat_sig    ),
							.cnt_i2s_dat_o 			( cnt_i2s_dat_sig    ),
`endif							
							                   
							.ACLSIP_Reg_o	    ( ACLSIP_Reg_sig )


		   );







																		  

endmodule


//wire              [15:0]  L_RXFIFO_DATOUT   ;
//wire                     L_RXFIFO_Pop       ;
//wire              [15:0]  R_RXFIFO_DATOUT   ;
//wire                     R_RXFIFO_Pop       ;
//wire              [8:0]  R_Rx_FIFO_Level    ;
//wire                     R_Rx_FIFO_Empty    ;
//wire                     R_Rx_FIFO_Full     ;
//wire					L_RX_DAT_IRQ_EN       ;  
//wire					L_RX_DAT_IRQ          ;
//wire					I2S_RX_Intr_L ;
//wire					I2S_RX_Intr_R ;
//wire					R_RX_DAT_IRQ_EN       ;  
//wire					R_RX_DAT_IRQ          ; 
//wire  					STEREO_EN;
//wire  					LR_CHNL_SEL;
//wire             [31:0] LR_RXFIFO_DAT; 
//wire  					LR_Rx_FIFO_Full;
//wire  					LR_Rx_FIFO_Empty; 
//wire             [8:0]  LR_Rx_FIFO_Level ;
