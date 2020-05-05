// -----------------------------------------------------------------------------
// title          : I2C Master with Command Queue Top Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : I2C_Master_CmdQueue_Top.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2016/03/11	
// last update    : 2016/03/11
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: The I2C Master with Tx FIFO is designed for use in the fabric of the
//              AL4S3B. The only AL4S3B specific portion is the Tx FIFO. This
//              design takes the existing I2C Master and adds a Tx FIFO. This
//              helps to releave the processor from monitoring each I2C bus
//              transfer.
// -----------------------------------------------------------------------------
// copyright (c) 2016
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         description
// 2016/02/22      1.0        Glen Gomes     Initial Release
//
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps


module I2C_Master_w_CmdQueue_Top ( 

                // AHB-To_Fabric Bridge I/F
                //
				CLK_4M_i,
				RST_fb_i,
				
                WBs_CLK_i,
                WBs_RST_i,

                WBs_ADR_i,
                WBs_CYC_CQ_Reg_i,
                WBs_CYC_CQ_Tx_FIFO_i,
				WBs_CYC_LCD_Reg_i,
				WBs_CYC_SRAM_i,
                WBs_BYTE_STB_i,
                WBs_WE_i ,
                WBs_STB_i,
                WBs_DAT_i,
                WBs_DAT_o,
				WBs_LCD_DAT_o,
                WBs_ACK_o,

                WBs_ADR_CQ_o,
                WBs_CYC_CQ_o,
                WBs_WE_CQ_o ,
                WBs_STB_CQ_o,
                WBs_DAT_o_CQ_o,

                WBs_ACK_i2c_i,

                tip_i2c_i,

                CQ_Busy_o,
                CQ_Intr_o,
				
				LCD_DMA_Intr_o,

                SDMA_Req_CQ_o,
                SDMA_Sreq_CQ_o,
                SDMA_Done_CQ_i,
                SDMA_Active_CQ_i

                );


//------Port Parameters----------------
//

parameter       ADDRWIDTH                   =   10           ;
parameter       DATAWIDTH                   =  32           ;

parameter       CQ_STATUS_REG_ADR           =  7'h0         ;
parameter       CQ_CONTROL_REG_ADR          =  7'h1         ;
parameter       CQ_FIFO_LEVEL_REG_ADR       =  7'h2         ;

parameter       CQ_CNTL_DEF_REG_VALUE       = 32'hC0C_DEF_AC; // Distinguish access to undefined area


//------Port Signals-------------------
//

// Fabric Global Signals
//
input                    WBs_CLK_i           ; // Fabric Clock               from Fabric
input                    WBs_RST_i           ; // Fabric Reset               to   Fabric


// Wishbone Bus Signals
//
input   [ADDRWIDTH-1:0]  WBs_ADR_i           ; // Address Bus                to   Fabric
input                    WBs_CYC_CQ_Reg_i    ; // Cycle Chip Select          to   Fabric 
input                    WBs_CYC_CQ_Tx_FIFO_i; // Cycle Chip Select          to   Fabric
input                    WBs_CYC_LCD_Reg_i   ; // Cycle Chip Select          to   Fabric 
input                    WBs_CYC_SRAM_i      ; // Cycle Chip Select          to   Fabric
input             [3:0]  WBs_BYTE_STB_i      ; // Wishbone Byte   Enable Strobes
input                    WBs_WE_i            ; // Write Enable               to   Fabric
input                    WBs_STB_i           ; // Strobe Signal              to   Fabric
input   [DATAWIDTH-1:0]  WBs_DAT_i           ; // Write Data Bus             to   Fabric
output  [DATAWIDTH-1:0]  WBs_DAT_o           ; // Read  Data Bus             from Fabric
output  [DATAWIDTH-1:0]  WBs_LCD_DAT_o		 ;
output                   WBs_ACK_o           ; // Transfer Cycle Acknowledge from Fabric


// I2C Master Signals
//
output            [2:0]  WBs_ADR_CQ_o        ;
output                   WBs_CYC_CQ_o        ;
output                   WBs_WE_CQ_o         ;
output                   WBs_STB_CQ_o        ;
output            [7:0]  WBs_DAT_o_CQ_o      ;

input                    WBs_ACK_i2c_i       ;

input                    tip_i2c_i           ;

output                   CQ_Busy_o           ;
output                   CQ_Intr_o           ;

output					 LCD_DMA_Intr_o		 ;

output                   SDMA_Req_CQ_o       ;
output                   SDMA_Sreq_CQ_o      ;
input                    SDMA_Done_CQ_i      ;
input                    SDMA_Active_CQ_i    ; 

input                    CLK_4M_i    		 ; 
input                    RST_fb_i    		 ;


// Fabric Global Signals
//
wire                     WBs_CLK_i           ; // Wishbone Fabric Clock
wire                     WBs_RST_i           ; // Wishbone Fabric Reset

// Wishbone Bus Signals
//
wire    [ADDRWIDTH-1:0]  WBs_ADR_i           ; // Wishbone Address Bus
wire                     WBs_CYC_CQ_Reg_i    ; // Cycle Chip Select          to   Fabric 
wire                     WBs_CYC_CQ_Tx_FIFO_i; // Cycle Chip Select          to   Fabric
wire                     WBs_CYC_LCD_Reg_i	 ; // Cycle Chip Select          to   Fabric 
wire                     WBs_CYC_SRAM_i  	 ; // Cycle Chip Select          to   Fabric
wire              [3:0]  WBs_BYTE_STB_i      ; // Wishbone Byte   Enable Strobes
wire                     WBs_WE_i            ; // Wishbone Write  Enable Strobe
wire                     WBs_STB_i           ; // Wishbone Transfer      Strobe
wire    [DATAWIDTH-1:0]  WBs_DAT_i           ; // Wishbone Wrire  Data Bus
wire    [DATAWIDTH-1:0]  WBs_DAT_o           ; // Wishbone Read   Data Bus
wire    [DATAWIDTH-1:0]  WBs_LCD_DAT_o		 ; 
wire                     WBs_ACK_o           ; // Wishbone Client Acknowledge


// I2C Master Signals
//
wire              [2:0]  WBs_ADR_CQ_o        ;
wire                     WBs_CYC_CQ_o        ;
wire                     WBs_WE_CQ_o         ;
wire                     WBs_STB_CQ_o        ;
reg               [7:0]  WBs_DAT_o_CQ_o      ;
wire                     WBs_ACK_i2c_i       ;

wire                     tip_i2c_i           ;

wire                     CQ_Busy_o           ;
wire                     CQ_Intr_o           ;

wire                     SDMA_Req_CQ_o       ;
wire                     SDMA_Sreq_CQ_o      ;
wire                     SDMA_Done_CQ_i      ;
wire                     SDMA_Active_CQ_i    ;

wire              [35:0] LCD_TXFIFO_DAT 	 ;
wire					 LCD_TXFIFO_PUSH	 ;
wire 					 LCD_CQ_EN			 ;





//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//

wire                     Tx_FIFO_dma_ena_sig      ;

wire                     Tx_FIFO_Flush      ;
wire                     Tx_FIFO_Pop        ;
wire                     Tx_FIFO_Empty      ;
wire                     Tx_FIFO_Full       ;
wire              [8:0]  Tx_FIFO_Level      ;
wire             [31:0]  Tx_FIFO_DAT        ;

wire                     WBs_ACK_CQ_Reg     ;
wire                     WBs_ACK_CQ_Tx_FIFO ;

wire                     WBs_ACK_LCD_Reg     ; 
wire                     WBs_ACK_LCD_SRAM    ;

wire              [1:0]  WBs_DAT_CQ_Sel     ;

wire              [3:0]  Tx_FIFO_BYTE_STB   ;
reg                      WBs_BYTE_STB_CQ    ;

wire                     CQ_Enable          ;
wire                     CQ_Single_Step     ;
wire                     CQ_Enable_int      ;

wire 					dma_req_gen_sig;


wire                     LCD_CNTL_EN;
wire					 AUTO_PAN_EN;
//wire                     LCD_PAN_EN;
//wire                     LCD_PAN_RNL;
//wire            [11:0]   LCD_Dp_Strt_Adr;
wire            [6:0]    LCD_SLV_Adr;
wire                     LCD_CNTL_Busy;
wire                     LCD_Clr;
wire                     LCD_LD_Done;

wire                     DMA_Clr;
wire                     DMA_REQ;
wire                     DMA_Done;
wire                     DMA_EN;
wire                     DMA_Done_IRQ;
wire                     LCD_Load_Done_IRQ;

wire            [7:0]    SRAM_RD_DAT;
wire            [11:0]   SRAM_RD_ADR;


//------Logic Operations---------------
//

// Acknowledge accesses to each block
//
assign WBs_ACK_o = WBs_ACK_CQ_Reg
                 | WBs_ACK_CQ_Tx_FIFO | WBs_ACK_LCD_Reg | WBs_ACK_LCD_SRAM;


// Select the correct bit to pass to the I2C Master
//
always @( WBs_DAT_CQ_Sel   or
          Tx_FIFO_DAT
        )
begin
    case(WBs_DAT_CQ_Sel)
    2'h0: WBs_DAT_o_CQ_o  <= Tx_FIFO_DAT[ 7:0] ;
    2'h1: WBs_DAT_o_CQ_o  <= Tx_FIFO_DAT[15:8] ;
    2'h2: WBs_DAT_o_CQ_o  <= Tx_FIFO_DAT[23:16];
    2'h3: WBs_DAT_o_CQ_o  <= Tx_FIFO_DAT[31:24];
    endcase
end


// Select the corresponding Byte Strobe.
//
// Note: The CQ Statemachine checks this bit to make sure that the value
//       written by the M4/AP to the FIFO was valid.
//
always @( WBs_DAT_CQ_Sel   or
          Tx_FIFO_BYTE_STB
        )
begin
    case(WBs_DAT_CQ_Sel)
    2'h0: WBs_BYTE_STB_CQ <= Tx_FIFO_BYTE_STB[0];
    2'h1: WBs_BYTE_STB_CQ <= Tx_FIFO_BYTE_STB[1];
    2'h2: WBs_BYTE_STB_CQ <= Tx_FIFO_BYTE_STB[2];
    2'h3: WBs_BYTE_STB_CQ <= Tx_FIFO_BYTE_STB[3];
    endcase
end


//------Instantiate Modules------------
//


// Define the Storage elements of the Command Queue block
//
// Note: This includes all of the data registers.
//
I2C_Master_w_CmdQueue_Registers_dma        #(

    .ADDRWIDTH                          ( 7                               ),
    .DATAWIDTH                          ( DATAWIDTH                       ),

    .CQ_STATUS_REG_ADR                  ( CQ_STATUS_REG_ADR               ),
    .CQ_CONTROL_REG_ADR                 ( CQ_CONTROL_REG_ADR              ),
    .CQ_FIFO_LEVEL_REG_ADR              ( CQ_FIFO_LEVEL_REG_ADR           ),

    .CQ_CNTL_DEF_REG_VALUE              ( CQ_CNTL_DEF_REG_VALUE           )
	                                                                      )

     u_I2C_Master_w_CmdQueue_Registers    
	                                    ( 
    // AHB-To_Fabric Bridge I/F
    //
    .WBs_CLK_i                          ( WBs_CLK_i                       ),
    .WBs_RST_i                          ( WBs_RST_i                       ),

    .WBs_ADR_i                          ( WBs_ADR_i[6:0]                       ),
    .WBs_CYC_i                          ( WBs_CYC_CQ_Reg_i                ),
    .WBs_BYTE_STB_i                     ( WBs_BYTE_STB_i[1:0]             ),
    .WBs_WE_i                           ( WBs_WE_i                        ),
    .WBs_STB_i                          ( WBs_STB_i                       ),
    .WBs_DAT_i                          ( WBs_DAT_i[15:0]                 ),
    .WBs_DAT_o                          ( WBs_DAT_o                       ),
    .WBs_ACK_o                          ( WBs_ACK_CQ_Reg                  ),

    .CQ_Busy_i                          ( CQ_Busy_o                       ),
    .CQ_Single_Step_o                   ( CQ_Single_Step                  ),
    .CQ_Enable_o                        ( CQ_Enable                       ),
    .CQ_Intr_o                          ( CQ_Intr_o                       ),

    // TX
    .Tx_FIFO_Empty_i                    ( Tx_FIFO_Empty                   ),
    .Tx_FIFO_Full_i                     ( Tx_FIFO_Full                    ),
    .Tx_FIFO_Level_i                    ( Tx_FIFO_Level                   ),
    .Tx_FIFO_Flush_o                    ( Tx_FIFO_Flush                   ),
	
	
	.dma_done_i							(SDMA_Done_CQ_i),
	.dma_active_i						(SDMA_Active_CQ_i),
	.Tx_FIFO_dma_ena_o					(Tx_FIFO_dma_ena_sig)

                                                                          );


// Command Queue Tx FIFO
//
I2C_Master_w_CmdQueue_Tx_FIFO             u_I2C_Master_w_CmdQueue_Tx_FIFO
                                        ( 

    .WBs_CLK_i                          ( WBs_CLK_i                       ),
    .WBs_RST_i                          ( WBs_RST_i                       ),

    .WBs_CYC_i                          ( WBs_CYC_CQ_Tx_FIFO_i            ),
    .WBs_BYTE_STB_i                     ( WBs_BYTE_STB_i                  ),
    .WBs_WE_i                           ( WBs_WE_i                        ),
    .WBs_STB_i                          ( WBs_STB_i                       ),
    .WBs_DAT_i                          ( WBs_DAT_i                       ),
    .WBs_ACK_o                          ( WBs_ACK_CQ_Tx_FIFO              ),

    .Tx_FIFO_Flush_i                    ( Tx_FIFO_Flush                   ),
	
	.LCD_TXFIFO_DAT_i                   ( LCD_TXFIFO_DAT                  ),
	.LCD_TXFIFO_PUSH_i                  ( LCD_TXFIFO_PUSH                 ),
	.LCD_CNTL_Busy_i                    ( LCD_CNTL_Busy                   ),
	

    .Tx_FIFO_Pop_i                      ( Tx_FIFO_Pop                     ),
    .Tx_FIFO_DAT_o                      ( Tx_FIFO_DAT                     ),
    .Tx_FIFO_BYTE_STB_o                 ( Tx_FIFO_BYTE_STB                ),

    .Tx_FIFO_Empty_o                    ( Tx_FIFO_Empty                   ),
    .Tx_FIFO_Full_o                     ( Tx_FIFO_Full                    ),
    .Tx_FIFO_Level_o                    ( Tx_FIFO_Level                   )
                                                                          );


// Command Queue Statemachine
//
I2C_Master_w_CmdQueue_StateMachine        u_I2C_Master_w_CmdQueue_StateMachine
                                        ( 

    .WBs_CLK_i                          ( WBs_CLK_i                       ),
    .WBs_RST_i                          ( WBs_RST_i                       ),

    .WBs_ADR_CQ_o                       ( WBs_ADR_CQ_o                    ),
    .WBs_CYC_CQ_o                       ( WBs_CYC_CQ_o                    ),
    .WBs_STB_CQ_o                       ( WBs_STB_CQ_o                    ),
    .WBs_WE_CQ_o                        ( WBs_WE_CQ_o                     ),

    .WBs_DAT_CQ_Sel_o                   ( WBs_DAT_CQ_Sel                  ),

    .WBs_BYTE_STB_i                     ( WBs_BYTE_STB_CQ                 ),

    .Tx_FIFO_Flush_i                    ( Tx_FIFO_Flush                   ),
    .Tx_FIFO_Empty_i                    ( Tx_FIFO_Empty                   ),
    .Tx_FIFO_Pop_o                      ( Tx_FIFO_Pop                     ),

    .WBs_ACK_i2c_i                      ( WBs_ACK_i2c_i                   ),

    .stop_i2c_i                         ( WBs_DAT_o_CQ_o[6]               ),
    .read_i2c_i                         ( WBs_DAT_o_CQ_o[5]               ),
    .write_i2c_i                        ( WBs_DAT_o_CQ_o[4]               ),

    .tip_i2c_i                          ( tip_i2c_i                       ),

    .CQ_Single_Step_i                   ( CQ_Single_Step                  ),
    .CQ_Enable_i                        ( CQ_Enable_int                   ),
    .CQ_Busy_o                          ( CQ_Busy_o                       )
                                                                          );
																		  
assign CQ_Enable_int = (LCD_CNTL_Busy)? LCD_CQ_EN: CQ_Enable;

//
// Instantiate the DMA block here
//
// Please use the register block for register storage 
//
//
/*
dma_request_gen  u_CQ_dma_req_gen
				(
					.wbs_clk_i          ( WBs_CLK_i                       ),
					.wbs_rst_i          ( WBs_RST_i                       ),
					.dma_ena_i			(Tx_FIFO_dma_ena_sig),
					.Tx_fifo_empty_i	(Tx_FIFO_Empty),
					.dma_req_gen_o		(dma_req_gen_sig),
					.dma_done_i			(SDMA_Done_CQ_i),
					.dma_active_i		(SDMA_Active_CQ_i)
				
				
				);

assign SDMA_Req_CQ_o = dma_req_gen_sig;
assign SDMA_Sreq_CQ_o = dma_req_gen_sig;	
*/			

LCD_controller_registers        u_LCD_controller_registers
                                        ( 

    .WBs_CLK_i                          ( WBs_CLK_i                       ),
    .WBs_RST_i                          ( WBs_RST_i                       ),

    .WBs_ADR_i                          ( WBs_ADR_i                       ),
    .WBs_CYC_i                          ( WBs_CYC_LCD_Reg_i               ),
    .WBs_BYTE_STB_i                     ( WBs_BYTE_STB_i[2:0]             ),
    .WBs_WE_i                           ( WBs_WE_i                        ),
    .WBs_STB_i                          ( WBs_STB_i                       ),
    .WBs_DAT_i                          ( WBs_DAT_i		              	  ),
    .WBs_DAT_o                          ( WBs_LCD_DAT_o                   ),
    .WBs_ACK_o                          ( WBs_ACK_LCD_Reg                 ), 
	
	.WBs_SRAM_CYC_i                     ( WBs_CYC_SRAM_i                  ),
	.WBs_SRAM_ACK_o                     ( WBs_ACK_LCD_SRAM                ),

    .LCD_CNTL_EN_o                   	( LCD_CNTL_EN                  	  ),
	.AUTO_PAN_EN_o                   	( AUTO_PAN_EN                  	  ),
	//.LCD_PAN_EN_o                   	( LCD_PAN_EN                      ),
	//.LCD_PAN_RNL_o                   	( LCD_PAN_RNL	                  ),
	//.LCD_Dp_Strt_Adr_o                ( LCD_Dp_Strt_Adr                 ),
	.LCD_SLV_Adr_o                   	( LCD_SLV_Adr	                  ),
	.LCD_CNTL_Busy_i                   	( LCD_CNTL_Busy	                  ),
	.LCD_Clr_i                   		( LCD_Clr		                  ),
	.LCD_LD_Done_i                   	( LCD_LD_Done	                  ),

    .DMA_Clr_i                     		( DMA_Clr		                  ),
	.DMA_REQ_i                     		( DMA_REQ		                  ),
	.DMA_Done_i                     	( DMA_Done		                  ),
	.DMA_EN_o                     		( DMA_EN		                  ),
	.DMA_Done_IRQ_o                     ( DMA_Done_IRQ		              ),

    .LCD_Load_Done_IRQ_o                ( LCD_Load_Done_IRQ               ),

    .SRAM_RD_DAT_o                      ( SRAM_RD_DAT                     ),
    .SRAM_RD_ADR_i                      ( SRAM_RD_ADR                     )
                                                                          );

LCD_Controller_StateMachine        u_LCD_Controller_StateMachine
                                        ( 
	.CLK_4M_i							( CLK_4M_i						  ), 
	.RST_fb_i							( RST_fb_i						  ), 
	
    .WBs_CLK_i                          ( WBs_CLK_i                       ),
    .WBs_RST_i                          ( WBs_RST_i                       ),

    .LCD_TXFIFO_DAT_o                   (LCD_TXFIFO_DAT            		  ),
    .LCD_TXFIFO_PUSH_o                  (LCD_TXFIFO_PUSH  				  ),
    .LCD_CQ_EN_o	                    (LCD_CQ_EN        				  ),
    .Tx_FIFO_Empty_i                    (Tx_FIFO_Empty                    ),

    .LCD_CNTL_EN_i                   	( LCD_CNTL_EN                  	  ),
	.AUTO_PAN_EN_i                   	( AUTO_PAN_EN                  	  ),
	//.LCD_PAN_EN_i                   	( LCD_PAN_EN                      ),
	//.LCD_PAN_RNL_i                   	( LCD_PAN_RNL	                  ),
	//.LCD_Dp_Strt_Adr_i                  ( LCD_Dp_Strt_Adr                 ),
	.LCD_SLV_Adr_i                   	( LCD_SLV_Adr	                  ),
	.LCD_CNTL_Busy_o                   	( LCD_CNTL_Busy	                  ),
	.LCD_Clr_o                   		( LCD_Clr		                  ),
	.LCD_LD_Done_o                   	( LCD_LD_Done	                  ),

    .DMA_Clr_o                     		( DMA_Clr		                  ),
	.DMA_REQ_o                     		( DMA_REQ		                  ),
	.DMA_Done_o                     	( DMA_Done		                  ),
	.DMA_Enable_i                  		( DMA_EN		                  ),
	.DMA_Active_i                       ( SDMA_Active_CQ_i	              ),

    .SRAM_RD_DAT_i                      ( SRAM_RD_DAT                     ),
    .SRAM_RD_ADR_o                      ( SRAM_RD_ADR                     )
                                                                          );	
																		  
assign SDMA_Req_CQ_o = DMA_REQ;
assign SDMA_Sreq_CQ_o = DMA_REQ;
assign LCD_DMA_Intr_o = DMA_Done_IRQ | LCD_Load_Done_IRQ;

endmodule
