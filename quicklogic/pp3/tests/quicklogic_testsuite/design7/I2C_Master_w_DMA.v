// -----------------------------------------------------------------------------
// title          : I2C Master with DMA Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : I2C_Master_w_DMA.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2016/03/11	
// last update    : 2016/03/11
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: The I2C Master with DMA is designed for use in the fabric of the
//              AL4S3B. 
// -----------------------------------------------------------------------------
// copyright (c) 2016
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         		description
// 2016/02/22      1.0        Glen Gomes     		Initial Release
// 2016/05/23      1.1        Rakesh Moolacheri     Added DMA state machine
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps

module I2C_Master_w_DMA ( 

                         // AHB-To_Fabric Bridge I/F
                         //
                         WBs_CLK_i,
                         WBs_RST_i,

                         WBs_ADR_i,

                         WBs_CYC_I2C_Sen_i,

                         WBs_BYTE_STB_i,
                         WBs_WE_i,
                         WBs_STB_i,
                         WBs_DAT_i,
                         WBs_DAT_o_I2C_Sen_o,
                         WBs_ACK_o,

                         scl_Sen_pad_i,
                         scl_Sen_pad_o,
                         scl_Sen_padoen_o,

                         sda_Sen_pad_i,
                         sda_Sen_pad_o,
                         sda_Sen_padoen_o,

                         i2c_Sen_Intr_o,

                         SDMA_Req_Sen_o,
                         SDMA_Sreq_Sen_o,
                         SDMA_Done_Sen_i,
                         SDMA_Active_Sen_i

                         );


//------Port Parameters----------------
//

parameter                ADDRWIDTH                   =   7           ;
parameter                DATAWIDTH                   =  32           ;

parameter                DMA_STATUS_REG_ADR          =  7'h40         ;
parameter                DMA_CONTROL_REG_ADR         =  7'h41         ;
//parameter                DMA_TRNS_CNT_REG_ADR  =  7'h42         ; // DMA transfer count register
//parameter                DMA_SCRATCH_REG_ADR         =  7'h43        ;
parameter                DMA_SLV_ADR_REG_ADR   		 =  7'h44         ; // DMA Slave Adr, Reg1 Adr, Reg2 Adr  Register 

parameter                DMA_DATA1_REG_ADR   =  7'h48        ;
parameter                DMA_DATA2_REG_ADR   =  7'h49        ;

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

input                    WBs_CYC_I2C_Sen_i   ; // Cycle Chip Select          to   Fabric

input             [3:0]  WBs_BYTE_STB_i      ; // Byte Enable Strobes        to   Fabric
input                    WBs_WE_i            ; // Write Enable               to   Fabric
input                    WBs_STB_i           ; // Strobe Signal              to   Fabric
input   [DATAWIDTH-1:0]  WBs_DAT_i           ; // Write Data Bus             to   Fabric
output  [DATAWIDTH-1:0]  WBs_DAT_o_I2C_Sen_o ;

output                   WBs_ACK_o           ; // Transfer Cycle Acknowledge from Fabric


input                    scl_Sen_pad_i       ;
output                   scl_Sen_pad_o       ;
output                   scl_Sen_padoen_o    ;

input                    sda_Sen_pad_i       ;
output                   sda_Sen_pad_o       ;
output                   sda_Sen_padoen_o    ;

output                   i2c_Sen_Intr_o      ;

output            		 SDMA_Req_Sen_o      ;
output            		 SDMA_Sreq_Sen_o     ;
input             		 SDMA_Done_Sen_i     ;
input             		 SDMA_Active_Sen_i   ;

                                           

// Fabric Global Signals
//
wire                     WBs_CLK_i           ; // Wishbone Fabric Clock
wire                     WBs_RST_i           ; // Wishbone Fabric Reset

// Wishbone Bus Signals
//
wire    [ADDRWIDTH-1:0]  WBs_ADR_i           ; // Wishbone Address Bus

wire                     WBs_CYC_I2C_Sen_i   ; // Wishbone Client Cycle  Strobe (i.e. Chip Select to I2C Master)

wire              [3:0]  WBs_BYTE_STB_i      ; // Wishbone Byte   Enable Strobes
wire                     WBs_WE_i            ; // Wishbone Write  Enable Strobe
wire                     WBs_STB_i           ; // Wishbone Transfer      Strobe
wire    [DATAWIDTH-1:0]  WBs_DAT_i           ; // Wishbone Write  Data Bus
 
wire    [DATAWIDTH-1:0]  WBs_DAT_o_I2C_Sen_o ;


wire                     WBs_ACK_o           ; // Wishbone Client Acknowledge


wire                     scl_Sen_pad_i       ;
wire                     scl_Sen_pad_o       ;
wire                     scl_Sen_padoen_o    ;

wire                     sda_Sen_pad_i       ;
wire                     sda_Sen_pad_o       ;
wire                     sda_Sen_padoen_o    ;

wire                    i2c_Sen_Intr_o      ;

wire              		SDMA_Req_Sen_o      ;
wire             		SDMA_Sreq_Sen_o     ;
wire              		SDMA_Done_Sen_i     ;
wire              		SDMA_Active_Sen_i   ;

wire                    HRM_DMA_Intr    ;
wire                    HRM_I2C_Intr    ;


//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//

wire              [7:0]  WBs_DAT_o_i2c      ;
wire                     WBs_CYC_i2c        ;
wire                     WBs_ACK_i2c        ;

wire                     tip_i2c            ;


wire    [DATAWIDTH-1:0]  WBs_DAT_o_reg      ;
wire                     WBs_CYC_reg        ;
wire                     WBs_ACK_reg        ; // Acknowledge to the system from the register block


wire              [2:0]  WBs_ADR_i2c        ;
wire                     WBs_CYC_i2c_int    ;
wire              [7:0]  WBs_DAT_i_i2c      ;
wire                     WBs_WE_i2c         ;
wire                     WBs_STB_i2c        ; 


wire  					DMA_Busy;
wire  					DMA_Enable;
wire 					DMA_Active;
wire					DMA_Done;
wire					SDMA_Req_Sen;
wire					DMA_Clr;


wire			  [2:0]	WBs_ADR_DMA;
wire					WBs_CYC_DMA;
wire					WBs_STB_DMA;
wire					WBs_WE_DMA;  
wire              [7:0] WBs_DAT_DMA;

wire			  [15:0]	SLV_REG_AD;

wire              [23:0] I2C_SEN_DATA1;

wire					DMA_Done_IRQ_EN;
wire					DMA_Done_IRQ;

reg                      WBs_ACK_Default    ;
wire                     WBs_ACK_Default_nxt;

wire                    rx_ack    ;
wire					DMA_I2C_NACK;
wire					SEL_16BIT;

//------Logic Operations---------------
//

// Determine the I2C Master's Wishbone Master
//

// Select the source of control signals into the HRM I2C Master 
//
assign WBs_ADR_i2c         =    DMA_Busy          ?  WBs_ADR_DMA             : WBs_ADR_i[2:0] ;
assign WBs_CYC_i2c         =    DMA_Busy          ?  WBs_CYC_DMA             : WBs_CYC_i2c_int  ;
assign WBs_DAT_i_i2c       =    DMA_Busy          ?  WBs_DAT_DMA             : WBs_DAT_i[7:0] ;
assign WBs_WE_i2c          =    DMA_Busy          ?  WBs_WE_DMA              : WBs_WE_i       ;
assign WBs_STB_i2c         =    DMA_Busy          ?  WBs_STB_DMA             : WBs_STB_i      ;

// Determine the I2C Master's Wishbone Master
//

// Select the source of control signals into the I2C Master from the DMA logic
//
assign WBs_CYC_i2c_int     =    WBs_CYC_I2C_Sen_i & (~WBs_ADR_i[6]);
assign WBs_CYC_reg         =    WBs_CYC_I2C_Sen_i & (WBs_ADR_i[6]);


// Select the source of control signals from the I2C Master and TxFIFO logic
//
assign WBs_DAT_o_I2C_Sen_o =  (WBs_ADR_i[6]) ?  WBs_DAT_o_reg : {24'h0, WBs_DAT_o_i2c};


// Determine the final Wishbone bus acknowledge
//
assign WBs_ACK_o           = ( DMA_Busy  &  WBs_ACK_Default )        
						   | ((~DMA_Busy) &  WBs_ACK_i2c   )
                           |                WBs_ACK_reg ;	

// Detemine when to generate an acknowledge to cycles directed at the I2C
// Master when the I2C Master is being used by the DMA logic
//
assign WBs_ACK_Default_nxt =    DMA_Busy  &  WBs_CYC_i2c_int & WBs_STB_i & (~WBs_ACK_Default);


// Generate a Default acknowledge cycle
//
// Note: This acknowledge prevents the wishbone bus from being locked during
//       long DMA transfers.
//
//       Writes go no where. Reads output a recognizable default value.
//
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

						   
						   
assign SDMA_Req_Sen_o = SDMA_Req_Sen; 
assign SDMA_Sreq_Sen_o = 1'b0;

assign HRM_DMA_Intr = (DMA_Done_IRQ_EN)? DMA_Done_IRQ: 1'b0; 

assign i2c_Sen_Intr_o = HRM_DMA_Intr | HRM_I2C_Intr;


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
    .wb_adr_i                           ( WBs_ADR_i2c              		  ), 
    .wb_dat_i                           ( WBs_DAT_i_i2c                   ), 
    .wb_dat_o                           ( WBs_DAT_o_i2c                   ),
    .wb_we_i                            ( WBs_WE_i2c                      ), 
    .wb_stb_i                           ( WBs_STB_i2c                     ), 
    .wb_cyc_i                           ( WBs_CYC_i2c                     ), 
    .wb_ack_o                           ( WBs_ACK_i2c                     ), 
    .wb_inta_o                          ( HRM_I2C_Intr                    ),

    .scl_pad_i                          ( scl_Sen_pad_i                   ), 
    .scl_pad_o                          ( scl_Sen_pad_o                   ), 
    .scl_padoen_o                       ( scl_Sen_padoen_o                ), 
    .sda_pad_i                          ( sda_Sen_pad_i                   ), 
    .sda_pad_o                          ( sda_Sen_pad_o                   ), 
    .sda_padoen_o                       ( sda_Sen_padoen_o                ), 

    .rxack_stick_en_i                   ( 1'b0                            ),
    .rxack_clr_i                        ( 1'b0                            ),
    .rxack_o                            ( rx_ack                          ),

    .al_stick_en_i                      ( 1'b0                            ),
    .al_clr_i                           ( 1'b0                            ),
    .al_o                               (                                 ),

    .tip_o                              ( tip_i2c                         ), 
    .i2c_busy_o                         (                                 ), 
    .DrivingI2cBusOut                   (                                 )
                                                                          );

I2C_Master_w_DMA_Registers             #(

    .ADDRWIDTH                          ( ADDRWIDTH                       ),
    .DATAWIDTH                          ( DATAWIDTH                       ),

    .DMA_STATUS_REG_ADR                 ( DMA_STATUS_REG_ADR              ),
    .DMA_CONTROL_REG_ADR                ( DMA_CONTROL_REG_ADR             ),
	.DMA_SLV_ADR_REG_ADR                ( DMA_SLV_ADR_REG_ADR             ),
	.DMA_DATA1_REG_ADR                	( DMA_DATA1_REG_ADR               ),
	.DMA_DATA2_REG_ADR                	( DMA_DATA2_REG_ADR               ),
	
    .DMA_DEF_REG_VALUE                  ( DMA_DEF_REG_VALUE               )
	                                                                      )
                                          u_I2C_Master_w_DMA_Registers 
                                        ( 
    .WBs_CLK_i                          ( WBs_CLK_i                       ),//
    .WBs_RST_i                          ( WBs_RST_i                       ),//

    .WBs_ADR_i                          ( WBs_ADR_i[ADDRWIDTH-1:0]        ),//
    .WBs_CYC_i                          ( WBs_CYC_reg                     ),//
    .WBs_BYTE_STB_i                     ( WBs_BYTE_STB_i[2:0]             ),//
    .WBs_WE_i                           ( WBs_WE_i                        ),//
    .WBs_STB_i                          ( WBs_STB_i                       ),//
    .WBs_DAT_i                          ( WBs_DAT_i[23:0]                 ),//
    .WBs_DAT_o                          ( WBs_DAT_o_reg                   ),//
    .WBs_ACK_o                          ( WBs_ACK_reg                     ),//
	
	.DMA_Busy_i                         ( DMA_Busy                        ),//
	.DMA_Clr_i                          ( DMA_Clr                         ),//
	.DMA_Done_i                         ( DMA_Done                        ),//
	.DMA_Active_i                       ( DMA_Active            		  ),//
	.DMA_REQ_i                          ( SDMA_Req_Sen            		  ),//
	.DMA_I2C_NACK_i					    ( DMA_I2C_NACK                    ),
	
	.DMA_EN_o                       	( DMA_Enable                      ),//
	.DMA_Done_IRQ_o                     ( DMA_Done_IRQ                    ),//
	.DMA_Done_IRQ_EN_o                  ( DMA_Done_IRQ_EN                 ),//
	.SLV_REG_ADR_o                      ( SLV_REG_AD                      ),//
	.SEL_16BIT_o                        ( SEL_16BIT                       ),
	
	.I2C_SEN_DATA1_i                     ( I2C_SEN_DATA1                  )
                                                                          );
			
											
//
// Instantiate the DMA logic below
//
// Please modify the register block above to support the DMA
//
I2C_Master_w_DMA_StateMachine        u_I2C_Master_w_DMA_StateMachine
                                        ( 

    .WBs_CLK_i                           ( WBs_CLK_i                       ),//
    .WBs_RST_i                           ( WBs_RST_i                       ),//

    .WBs_ADR_DMA_o                       ( WBs_ADR_DMA                     ),//
    .WBs_CYC_DMA_o                       ( WBs_CYC_DMA                     ),//
    .WBs_STB_DMA_o                       ( WBs_STB_DMA                     ),//
    .WBs_WE_DMA_o                        ( WBs_WE_DMA                      ),//
	
	.WBs_DAT_DMA_o                       ( WBs_DAT_DMA                     ),//
	
	.WBs_DAT_I2C_i                       ( WBs_DAT_o_i2c                   ),// 
	
	.I2C_SEN_DATA1_o                      ( I2C_SEN_DATA1                     ),//

	.DMA_Clr_o                   		 ( DMA_Clr                         ),//
	.SLV_REG_ADR_i                       ( SLV_REG_AD                      ),
	
	.DMA_REQ_o                   		 ( SDMA_Req_Sen		               ),//
	.DMA_DONE_o                   		 ( DMA_Done                  	   ),//
	.DMA_Active_i                    	 ( SDMA_Active_Sen_i               ),//
	.DMA_Active_o                    	 ( DMA_Active                      ),//

    .WBs_ACK_i2c_i                       ( WBs_ACK_i2c                     ),

    .tip_i2c_i                           ( tip_i2c                         ),
	.rx_ack_i                            ( rx_ack                          ),
	.SEL_16BIT_i                         ( SEL_16BIT                       ),
	.DMA_I2C_NACK_o						 ( DMA_I2C_NACK                    ),

    .DMA_Enable_i                        ( DMA_Enable                      ),
    .DMA_Busy_o                          ( DMA_Busy                        )
                                                                          );  

endmodule
