// -----------------------------------------------------------------------------
// title          : I2C Master with Command Queue Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : I2C_Master_w_CmdQueue.v
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


module I2C_Master_w_CmdQueue ( 

                         // AHB-To_Fabric Bridge I/F
                         //
						 CLK_4M_i,
						 RST_fb_i,
						 
                         WBs_CLK_i,
                         WBs_RST_i,

                         WBs_ADR_i,

                         WBs_CYC_I2C_i,
                         //WBs_CYC_CQ_Reg_i,
                         //WBs_CYC_CQ_Tx_FIFO_i,
						 //WBs_CYC_LCD_Reg_i,
						 //WBs_CYC_SRAM_i,

                         WBs_BYTE_STB_i,
                         WBs_WE_i,
                         WBs_STB_i,
                         WBs_DAT_i,
                         //WBs_DAT_o_CQ_Reg_o,
						 //WBs_DAT_o_LCD_Reg_o,
                         WBs_DAT_o_I2C_o,
                         WBs_ACK_o,

                         scl_pad_i,
                         scl_pad_o,
                         scl_padoen_o,

                         sda_pad_i,
                         sda_pad_o,
                         sda_padoen_o,

                         i2c_Intr_o
                         //CQ_Intr_o,
						 
						 //LCD_DMA_Intr_o,

                        // SDMA_Req_CQ_o,
                        // SDMA_Sreq_CQ_o,
                        // SDMA_Done_CQ_i,
                        // SDMA_Active_CQ_i

                         );


//------Port Parameters----------------
//

parameter                ADDRWIDTH                   =  10           ;
parameter                DATAWIDTH                   =  32           ;

parameter                I2C_DEFAULT_READ_VALUE      = 32'hFEEDBEEF  ;

parameter                CQ_STATUS_REG_ADR           =  7'h0         ;
parameter                CQ_CONTROL_REG_ADR          =  7'h1         ;
parameter                CQ_FIFO_LEVEL_REG_ADR       =  7'h2         ;

parameter                CQ_CNTL_DEF_REG_VALUE       = 32'hC0C_DEF_AC; // Distinguish access to undefined area



//------Port Signals-------------------
//


// Fabric Global Signals
//
input                    WBs_CLK_i           ; // Fabric Clock               from Fabric
input                    WBs_RST_i           ; // Fabric Reset               to   Fabric


// Wishbone Bus Signals
//
input   [ADDRWIDTH-1:0]  WBs_ADR_i           ; // Address Bus                to   Fabric

input                    WBs_CYC_I2C_i       ; // Cycle Chip Select          to   Fabric
//input                    WBs_CYC_CQ_Reg_i    ;
//input                    WBs_CYC_CQ_Tx_FIFO_i;
//input                    WBs_CYC_LCD_Reg_i	 ; 
//input                    WBs_CYC_SRAM_i		 ;

input             [3:0]  WBs_BYTE_STB_i      ; // Byte Enable Strobes        to   Fabric
input                    WBs_WE_i            ; // Write Enable               to   Fabric
input                    WBs_STB_i           ; // Strobe Signal              to   Fabric
input   [DATAWIDTH-1:0]  WBs_DAT_i           ; // Write Data Bus             to   Fabric
//output  [DATAWIDTH-1:0]  WBs_DAT_o_CQ_Reg_o  ;
//output  [DATAWIDTH-1:0]  WBs_DAT_o_LCD_Reg_o ;
output  [DATAWIDTH-1:0]  WBs_DAT_o_I2C_o     ;

output                   WBs_ACK_o           ; // Transfer Cycle Acknowledge from Fabric


input                    scl_pad_i           ;
output                   scl_pad_o           ;
output                   scl_padoen_o        ;

input                    sda_pad_i           ;
output                   sda_pad_o           ;
output                   sda_padoen_o        ;

output                   i2c_Intr_o          ;
//output                   CQ_Intr_o           ; 

//output                   LCD_DMA_Intr_o      ;

//output                   SDMA_Req_CQ_o       ;
//output                   SDMA_Sreq_CQ_o      ;
//input                    SDMA_Done_CQ_i      ;
//input                    SDMA_Active_CQ_i    ; 

input                    CLK_4M_i		     ; 
input                    RST_fb_i		     ;


// Fabric Global Signals
//
wire                     WBs_CLK_i           ; // Wishbone Fabric Clock
wire                     WBs_RST_i           ; // Wishbone Fabric Reset

// Wishbone Bus Signals
//
wire    [ADDRWIDTH-1:0]  WBs_ADR_i           ; // Wishbone Address Bus

wire                     WBs_CYC_I2C_i       ; // Wishbone Client Cycle  Strobe (i.e. Chip Select to I2C Master)
//wire                     WBs_CYC_CQ_Reg_i    ; // Wishbone Client Cycle  Strobe (i.e. Chip Select to TxFIFO    )
//wire                     WBs_CYC_CQ_Tx_FIFO_i; // Wishbone Client Cycle  Strobe (i.e. Chip Select to TxFIFO    )
//wire                     WBs_CYC_LCD_Reg_i	 ;
//wire                     WBs_CYC_SRAM_i		 ;

wire              [3:0]  WBs_BYTE_STB_i      ; // Wishbone Byte   Enable Strobes
wire                     WBs_WE_i            ; // Wishbone Write  Enable Strobe
wire                     WBs_STB_i           ; // Wishbone Transfer      Strobe
wire    [DATAWIDTH-1:0]  WBs_DAT_i           ; // Wishbone Write  Data Bus
 
//wire    [DATAWIDTH-1:0]  WBs_DAT_o_CQ_Reg_o  ; 
//wire    [DATAWIDTH-1:0]  WBs_DAT_o_LCD_Reg_o ;
wire    [DATAWIDTH-1:0]  WBs_DAT_o_I2C_o     ;


wire                     WBs_ACK_o           ; // Wishbone Client Acknowledge


wire                     scl_pad_i           ;
wire                     scl_pad_o           ;
wire                     scl_padoen_o        ;

wire                     sda_pad_i           ;
wire                     sda_pad_o           ;
wire                     sda_padoen_o        ;

wire                     i2c_Intr_o          ;
//wire                     CQ_Intr_o           ;

//wire                     LCD_DMA_Intr_o      ;

//wire                     SDMA_Req_CQ_o       ;
//wire                     SDMA_Sreq_CQ_o      ;
//wire                     SDMA_Done_CQ_i      ;
//wire                     SDMA_Active_CQ_i    ;


//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//

wire              [2:0]  WBs_ADR_i2c        ;
wire              [7:0]  WBs_DAT_i_i2c      ;
wire              [7:0]  WBs_DAT_o_i2c      ;
wire                     WBs_WE_i2c         ;
wire                     WBs_STB_i2c        ;
wire                     WBs_CYC_i2c        ;
wire                     WBs_ACK_i2c        ;

wire                     tip_i2c            ;


wire              [2:0]  WBs_ADR_CQ         ;
wire                     WBs_CYC_CQ         ;
wire              [7:0]  WBs_DAT_o_CQ       ;
wire                     WBs_WE_CQ          ;
wire                     WBs_STB_CQ         ;

wire                     WBs_ACK_CQ         ; // Acknowledge to the system from the register block

wire                     CQ_Busy            ; 

reg                      WBs_ACK_Default    ;
wire                     WBs_ACK_Default_nxt;


//------Logic Operations---------------
//

// Determine the I2C Master's Wishbone Master
//

// Select the source of control signals into the I2C Master from the TxFIFO logic
//
assign WBs_ADR_i2c         =    WBs_ADR_i[2:0] ;
assign WBs_CYC_i2c         =    WBs_CYC_I2C_i  ;
assign WBs_DAT_i_i2c       =    WBs_DAT_i[7:0] ;
assign WBs_WE_i2c          =    WBs_WE_i       ;
assign WBs_STB_i2c         =    WBs_STB_i      ;


// Select the source of control signals from the I2C Master and TxFIFO logic
//
assign WBs_DAT_o_I2C_o     =    {{(DATAWIDTH-8){1'b0}}, WBs_DAT_o_i2c};


// Determine the final Wishbone bus acknowledge
//
assign WBs_ACK_o           =  WBs_ACK_i2c  ;


// Detemine when to generate an acknowledge to cycles directed at the I2C
// Master when the I2C Master is being used by the TxFIFO logic
//
//assign WBs_ACK_Default_nxt =    CQ_Busy  &  WBs_CYC_I2C_i & WBs_STB_i & (~WBs_ACK_Default);


// Generate a Default acknowledge cycle
//
// Note: This acknowledge prevents the wishbone bus from being locked during
//       long Tx FIFO block transfers.
//
//       Writes go no where. Reads output a recognizable default value.
//
/*
always @(posedge WBs_CLK_i or posedge WBs_RST_i)
begin

    if (WBs_RST_i)
    begin
        WBs_ACK_Default <= 1'b0;
    end
    else
    begin
        WBs_ACK_Default <= WBs_ACK_Default_nxt ;
    end

end
*/

//------Instantiate Modules------------
//


// I2C Master
//
// Note: This is IP has not been modified for this application.
//
i2c_master_top                            u_i2c_master_top 
                                        (
	.wb_clk_i                           ( WBs_CLK_i                       ), 
    .wb_rst_i                           ( 1'b0                            ), 
    .arst_i                             ( WBs_RST_i                       ), 
    .wb_adr_i                           ( WBs_ADR_i2c                     ), 
    .wb_dat_i                           ( WBs_DAT_i_i2c                   ), 
    .wb_dat_o                           ( WBs_DAT_o_i2c                   ),
    .wb_we_i                            ( WBs_WE_i2c                      ), 
    .wb_stb_i                           ( WBs_STB_i2c                     ), 
    .wb_cyc_i                           ( WBs_CYC_i2c                     ), 
    .wb_ack_o                           ( WBs_ACK_i2c                     ), 
    .wb_inta_o                          ( i2c_Intr_o                      ),

    .scl_pad_i                          ( scl_pad_i                       ), 
    .scl_pad_o                          ( scl_pad_o                       ), 
    .scl_padoen_o                       ( scl_padoen_o                    ), 
    .sda_pad_i                          ( sda_pad_i                       ), 
    .sda_pad_o                          ( sda_pad_o                       ), 
    .sda_padoen_o                       ( sda_padoen_o                    ), 

    .rxack_stick_en_i                   ( 1'b0                            ),
    .rxack_clr_i                        ( 1'b0                            ),
    .rxack_o                            (                                 ),

    .al_stick_en_i                      ( 1'b0                            ),
    .al_clr_i                           ( 1'b0                            ),
    .al_o                               (                                 ),

    .tip_o                              ( tip_i2c                         ), 
    .i2c_busy_o                         (                                 ), 
    .DrivingI2cBusOut                   (                                 )
                                                                          );


// Command FIFO Interface
//
// Note: This IP expects data to be sent to it in a specific format of 
//       1 Byte Tx Data (TxData) and 1 Byte I2C Master Command data 
//       (CmdData). A 32-bit value will consist of:
//
//          [31:24]   [23:16]  [15:8]    [7:0]
//         <CmdData> <TxData> <CmdData> <TxData>
//
/*
I2C_Master_w_CmdQueue_Top              #(

    .ADDRWIDTH                          ( ADDRWIDTH                       ),
    .DATAWIDTH                          ( DATAWIDTH                       ),

    .CQ_STATUS_REG_ADR                  ( CQ_STATUS_REG_ADR               ),
    .CQ_CONTROL_REG_ADR                 ( CQ_CONTROL_REG_ADR              ),
    .CQ_FIFO_LEVEL_REG_ADR              ( CQ_FIFO_LEVEL_REG_ADR           ),

    .CQ_CNTL_DEF_REG_VALUE              ( CQ_CNTL_DEF_REG_VALUE           )
                                                                          )
	u_I2C_Master_w_CmdQueue_Top               
                                        (
    // Port to the ASSP
    //
	.CLK_4M_i							( CLK_4M_i						  ), 
	.RST_fb_i							( RST_fb_i						  ),
	
	.WBs_CLK_i                          ( WBs_CLK_i                       ), 
    .WBs_RST_i                          ( WBs_RST_i                       ), 

    .WBs_ADR_i                          ( WBs_ADR_i                       ), // Need to add address bits
    .WBs_CYC_CQ_Reg_i                   ( WBs_CYC_CQ_Reg_i                ),
    .WBs_CYC_CQ_Tx_FIFO_i               ( WBs_CYC_CQ_Tx_FIFO_i            ), 
	.WBs_CYC_LCD_Reg_i               	( WBs_CYC_LCD_Reg_i           	  ),
	.WBs_CYC_SRAM_i               		( WBs_CYC_SRAM_i            	  ),
    .WBs_BYTE_STB_i                     ( WBs_BYTE_STB_i                  ),
    .WBs_WE_i                           ( WBs_WE_i                        ), 
    .WBs_STB_i                          ( WBs_STB_i                       ), 
    .WBs_DAT_i                          ( WBs_DAT_i                       ), 
    .WBs_DAT_o                          ( WBs_DAT_o_CQ_Reg_o              ), 
	.WBs_LCD_DAT_o						( WBs_DAT_o_LCD_Reg_o              ), 
    .WBs_ACK_o                          ( WBs_ACK_CQ                      ),

    // Port to the I2C Master PSB
    //
    .WBs_ADR_CQ_o                       ( WBs_ADR_CQ                      ), 
    .WBs_CYC_CQ_o                       ( WBs_CYC_CQ                      ), 
    .WBs_WE_CQ_o                        ( WBs_WE_CQ                       ), 
    .WBs_STB_CQ_o                       ( WBs_STB_CQ                      ), 
    .WBs_DAT_o_CQ_o                     ( WBs_DAT_o_CQ                    ), 

    .WBs_ACK_i2c_i                      ( WBs_ACK_i2c                     ), 

    .tip_i2c_i                          ( tip_i2c                         ),

    .CQ_Busy_o                          ( CQ_Busy                         ),
    .CQ_Intr_o                          ( CQ_Intr_o                       ),
	
	.LCD_DMA_Intr_o                     ( LCD_DMA_Intr_o                  ),

    .SDMA_Req_CQ_o                      ( SDMA_Req_CQ_o                   ),
    .SDMA_Sreq_CQ_o                     ( SDMA_Sreq_CQ_o                  ),
    .SDMA_Done_CQ_i                     ( SDMA_Done_CQ_i                  ),
    .SDMA_Active_CQ_i                   ( SDMA_Active_CQ_i                )
                                                                          );
*/

endmodule
