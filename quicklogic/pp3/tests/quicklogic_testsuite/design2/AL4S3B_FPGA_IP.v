// -----------------------------------------------------------------------------
// title          : AL4S3B Example FPGA IP Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : AL4S3B_FPGA_IP.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 28/Oct/2016	
// last update    : 28/Oct/2016
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: The FPGA example IP design contains the essential logic for
//              interfacing the ASSP of the AL4S3B to registers and memory 
//              located in the programmable FPGA.
// -----------------------------------------------------------------------------
// copyright (c) 2016
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         description
// 2016/02/03      1.0        Glen Gomes     Initial Release
// 2016/05/24      1.1        Anand Wadke    Fixed HRM I2C Mapping
// 2016/05/25      1.2        Rakesh M       Fixed the HRM sensor I2C PADs, to have both the I2C LCD and I2C HRM
// 28/Oct/2016     1.3        Anand Wadke    Integrated PEEL IP.
// 23/Mar/2016     1.4        Rakesh M       integrated I2S Slave IP
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps


module AL4S3B_FPGA_IP ( 

                // AHB-To_FPGA Bridge I/F
                //
				CLK_12M_i,

                WBs_ADR,
                WBs_CYC,
                WBs_BYTE_STB,
                WBs_WE,
                WBs_RD,
                WBs_STB,
                WBs_WR_DAT,
                WB_CLK,
                WB_RST,
                WBs_RD_DAT,
                WBs_ACK,
				
				//I2S signals
				I2S_CLK_i,
				I2S_WS_CLK_i,
				I2S_DIN_i,
				
				I2S_RX_Intr_o,
				I2S_DMA_Intr_o,
				I2S_Dis_Intr_o,
				
				SDMA_Req_I2S_o,
                SDMA_Sreq_I2S_o,
                SDMA_Done_I2S_i,
                SDMA_Active_I2S_i,

				//IR Signals
				IR_TXD_o,
				IR_RXD_i,
				Ir_intr_o, 
				
                //GPIO_PIN,
                //
                // Misc
                //
			`ifdef DEBUG
				rState_o,
				rCRR_RISE_o,
				rRXD_o,
				wMEM_WE_o,
				wRX_CRR_CYC_CNT_SET1_o,
				wRX_CRR_CYC_CNT_EN_o,	
			`endif					
                Device_ID,
                rx_debug_o
				
                );


//------Port Parameters----------------
//

parameter       APERWIDTH                   = 17            ;
parameter       APERSIZE                    =  9            ;

parameter       FPGA_REG_BASE_ADDRESS     = 17'h00000     ; // Assumes 128K Byte FPGA Memory Aperture
parameter       IR_REG_BASE_ADDRESS         = 17'h00800     ; // Assumes 128K Byte FPGA Memory Aperture
parameter       I2S_S_REG_BASE_ADDRESS      = 17'h01000     ; // Assumes 128K Byte FPGA Memory Aperture

parameter                FPGA_REG_ID_VALUE_ADR     =  7'h0; 
parameter                FPGA_REVISION_NO_ADR    =  7'h1; 
parameter                FPGA_REG_SCRATCH_REG_ADR  =  7'h2; 

parameter                AL4S3B_DEVICE_ID            = 20'h610EE;
parameter                AL4S3B_REV_LEVEL            = 16'h0100;
parameter                AL4S3B_SCRATCH_REG          = 32'h12345678  ;

parameter       AL4S3B_DEF_REG_VALUE        = 32'hFAB_DEF_AC; // Distinguish access to undefined area


parameter       DEFAULT_READ_VALUE          = 32'hBAD_FAB_AC; // Bad FPGA Access

//parameter       ADDRWIDTH_DMA_REG           =  7            ;
parameter       ADDRWIDTH_DMA_REG           =  9            ;
parameter       DATAWIDTH_DMA_REG           = 32            ;

parameter       ADDRWIDTH_FAB_REG           =  7            ;
parameter       DATAWIDTH_FAB_REG           = 32            ;



//------Port Signals-------------------
//

// AHB-To_FPGA Bridge I/F
//
input   [16:0]  WBs_ADR          ;  // Address Bus                to   FPGA
input           WBs_CYC          ;  // Cycle Chip Select          to   FPGA
input    [3:0]  WBs_BYTE_STB     ;  // Byte Select                to   FPGA
input           WBs_WE           ;  // Write Enable               to   FPGA
input           WBs_RD           ;  // Read  Enable               to   FPGA
input           WBs_STB          ;  // Strobe Signal              to   FPGA
input   [31:0]  WBs_WR_DAT       ;  // Write Data Bus             to   FPGA
input           WB_CLK           ;  // FPGA Clock               from FPGA
input           WB_RST           ;  // FPGA Reset               to   FPGA
output  [31:0]  WBs_RD_DAT       ;  // Read Data Bus              from FPGA
output          WBs_ACK          ;  // Transfer Cycle Acknowledge from FPGA

// I2S Slave I/F
input 			I2S_CLK_i		;
input 			I2S_WS_CLK_i	;
input 			I2S_DIN_i		;

output          I2S_RX_Intr_o   ;				
output          I2S_DMA_Intr_o  ;	
output          I2S_Dis_Intr_o  ;

input 			SDMA_Done_I2S_i	;
input 			SDMA_Active_I2S_i;

output          SDMA_Req_I2S_o  ;				
output          SDMA_Sreq_I2S_o ;

// GPIO
//
//inout   [21:0]  GPIO_PIN         ;

output           IR_TXD_o          ;
input            IR_RXD_i         ;

// Misc
//
output   [19:0]  Device_ID       ;

//Ir Debug Signals
`ifdef DEBUG
output [2:0]	rState_o;
output			rCRR_RISE_o;
output			rRXD_o;
output			wMEM_WE_o;
output			wRX_CRR_CYC_CNT_SET1_o;
output			wRX_CRR_CYC_CNT_EN_o;	
`endif
output          Ir_intr_o   ;
input           CLK_12M_i		 ;
output  [7:0]        rx_debug_o   ;
// Wishbone Bus Signals
//
wire            WB_CLK           ;  // Wishbone FPGA Clock
wire            WB_RST           ;  // Wishbone FPGA Reset
wire    [16:0]  WBs_ADR          ;  // Wishbone Address Bus
wire            WBs_CYC          ;  // Wishbone Client Cycle  Strobe (i.e. Chip Select)
wire     [3:0]  WBs_BYTE_STB     ;  // Wishbone Byte   Enables
wire            WBs_WE           ;  // Wishbone Write  Enable Strobe
wire            WBs_RD           ;  // Wishbone Read   Enable Strobe
wire            WBs_STB          ;  // Wishbone Transfer      Strobe
reg     [31:0]  WBs_RD_DAT       ;  // Wishbone Read   Data Bus
//wire     [31:0]  WBs_RD_DAT       ;  // Wishbone Read   Data Bus
wire    [31:0]  WBs_WR_DAT       ;  // Wishbone Write  Data Bus
wire            WBs_ACK          ;  // Wishbone Client Acknowledge

//I2S slave signals
wire 			I2S_CLK_i		;
wire 			I2S_WS_CLK_i	;
wire 			I2S_DIN_i		;

wire          	I2S_RX_Intr_o   ;				
wire          	I2S_DMA_Intr_o  ;	
wire          	I2S_Dis_Intr_o  ;

wire 			SDMA_Done_I2S_i	;
wire 			SDMA_Active_I2S_i;

wire      	    SDMA_Req_I2S_o  ;				
wire          	SDMA_Sreq_I2S_o ;

// Misc
wire    [19:0]  Device_ID        ;
wire            Ir_intr_o   ;
//------Define Parameters--------------
// Default I/O timeout statemachine
parameter       DEFAULT_IDLE   =  0  ;
parameter       DEFAULT_COUNT  =  1  ;


//------Internal Signals---------------
//

// GPIO
//
//wire    [21:0]  GPIO_In              ;
//wire    [21:0]  GPIO_Out             ;
//wire    [21:0]  GPIO_oe              ;

// Wishbone Bus Signals
//
wire            WBs_CYC_FPGA_Reg   ;
wire            WBs_CYC_IR           ; 
wire            WBs_CYC_I2S_S        ;
//wire            WBs_CYC_UART         ;


wire            WBs_ACK_FPGA_Reg   ;
wire            WBs_ACK_IR           ;
wire            WBs_ACK_I2S_S        ; 
//wire            WBs_ACK_UART         ;



wire    [31:0]  WBs_DAT_o_FPGA_Reg ;
wire    [31:0]  WBs_DAT_I2S_S        ;
//wire    [15:0]  WBs_DAT_o_UART       ;
//wire    [31:0]  WBs_DAT_o_CQ         ;
//wire    [31:0]  WBs_DAT_o_LCD         ;
//wire    [31:0]  WBs_DAT_o_I2C_Sen    ;
//wire    [31:0]  WBs_DAT_o_QL_Reserved;

wire  [7:0]  WBs_RD_DAT_ir       ;  // Read Data Bus              from FPGA



//------Logic Operations---------------
//

// Define the Chip Select for each interface
//
assign WBs_CYC_FPGA_Reg   = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == FPGA_REG_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );

assign WBs_CYC_IR          = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == IR_REG_BASE_ADDRESS       [APERWIDTH-1:APERSIZE+2] ) 
                              & (  WBs_CYC                                                                                );  

assign WBs_CYC_I2S_S       = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == I2S_S_REG_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );
							

// Define the Acknowledge back to the host for everything
//
assign WBs_ACK              =    WBs_ACK_FPGA_Reg
                            |    WBs_ACK_IR
                           // |    WBs_ACK_UART
                            |    WBs_ACK_I2S_S ;  
                            
						
// Define the how to read from each IP
//
always @(
         WBs_ADR               or
         WBs_DAT_o_FPGA_Reg  or
         WBs_RD_DAT_ir         or
        // WBs_DAT_o_UART        or
         WBs_DAT_I2S_S          or
         WBs_RD_DAT    
        )
 begin
    case(WBs_ADR[APERWIDTH-1:APERSIZE+2])
    FPGA_REG_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=    WBs_DAT_o_FPGA_Reg   ;
    IR_REG_BASE_ADDRESS       [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=    { 24'h0, WBs_RD_DAT_ir }  ;
	I2S_S_REG_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=    WBs_DAT_I2S_S   ;
//    UART_BASE_ADDRESS          [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <= { 16'h0, WBs_DAT_o_UART        };
	default:                                            WBs_RD_DAT  <=    DEFAULT_READ_VALUE     ;
	endcase
end

//------Instantiate Modules------------
//

// Define the FPGA I/O Pad Signals
//
// Note: Use the Constraint manager in SpDE to assign these buffers to FBIO pads.
//



// General FPGA Resources 
//
// General FPGA Resources 
//
AL4S3B_FPGA_Registers #(

    .ADDRWIDTH                  ( ADDRWIDTH_FAB_REG             ),
    .DATAWIDTH                  ( DATAWIDTH_FAB_REG             ),

    .FPGA_REG_ID_VALUE_ADR    ( FPGA_REG_ID_VALUE_ADR       ),
	.FPGA_REVISION_NO_ADR     ( FPGA_REVISION_NO_ADR        ),
    .FPGA_REG_SCRATCH_REG_ADR ( FPGA_REG_SCRATCH_REG_ADR    ),

    .AL4S3B_DEVICE_ID           ( AL4S3B_DEVICE_ID              ),
    .AL4S3B_REV_LEVEL           ( AL4S3B_REV_LEVEL              ),
	.AL4S3B_SCRATCH_REG         ( AL4S3B_SCRATCH_REG            ),

    .AL4S3B_DEF_REG_VALUE       ( AL4S3B_DEF_REG_VALUE          )
                                                                )

     u_AL4S3B_FPGA_Registers 
	                           ( 
    // AHB-To_FPGA Bridge I/F
    //
    .WBs_ADR_i                 ( WBs_ADR[ADDRWIDTH_FAB_REG+1:2] ),
    .WBs_CYC_i                 ( WBs_CYC_FPGA_Reg             ),
    .WBs_BYTE_STB_i            ( WBs_BYTE_STB                   ),
    .WBs_WE_i                  ( WBs_WE                         ),
    .WBs_STB_i                 ( WBs_STB                        ),
    .WBs_DAT_i                 ( WBs_WR_DAT                     ),
    .WBs_CLK_i                 ( WB_CLK                         ),
    .WBs_RST_i                 ( WB_RST                         ),
    .WBs_DAT_o                 ( WBs_DAT_o_FPGA_Reg           ),
    .WBs_ACK_o                 ( WBs_ACK_FPGA_Reg             ),
    //
    // Misc
    //

    .Device_ID_o               ( Device_ID                      )
    );


ir_tx_rx_wrap ir_tx_rx_wrap_inst (
`ifdef DEBUG
	.rState_o				(rState_o),
	.rCRR_RISE_o			(rCRR_RISE_o),
	.rRXD_o					(rRXD_o),
	.wMEM_WE_o				(wMEM_WE_o),
	.wRX_CRR_CYC_CNT_SET1_o	(wRX_CRR_CYC_CNT_SET1_o),
	.wRX_CRR_CYC_CNT_EN_o	(wRX_CRR_CYC_CNT_EN_o),	
`endif
	.RST_i				(WB_RST),
	.CLK_i				(CLK_12M_i),
	.TXD_o				(IR_TXD_o),
	.RXD_i				(IR_RXD_i),
	.RX_GPIO_o			(), //RX_GPIO_o
	.WBs_CLK_i  		( WB_CLK		 ),
	.WBs_RST_i          ( WB_RST         ),
	//.WBs_ADR_i          ( WBs_ADR[7:0]   ),
	.WBs_ADR_i          ( WBs_ADR[9:2]   ),
	.WBs_CYC_i          ( WBs_CYC_IR        ),
	.WBs_BYTE_STB_i     ( WBs_BYTE_STB   ),
	.WBs_WE_i           ( WBs_WE         ),
	.WBs_STB_i          ( WBs_STB        ),
	.WBs_DAT_i          ( WBs_WR_DAT[7:0]    ),
	.WBs_DAT_o          ( WBs_RD_DAT_ir     ),
	.WBs_ACK_o          ( WBs_ACK_IR        ),

//	.REG_RD_ACK_i		(rREG_RD_ACK),
	.PSB_CLK_EN_o		(),
	.INT_o				(Ir_intr_o),
	.rx_debug_o            (rx_debug_o)
);


//pragma attribute ir_tx_rx_wrap_inst   preserve_cell true

// I2S Slave (RX mode) support with DMA
//
i2s_slave_w_DMA              #(

    .ADDRWIDTH                 ( ADDRWIDTH_DMA_REG              ),
    .DATAWIDTH                 ( DATAWIDTH_DMA_REG              )
	                                                            )
                                 u_I2S_Slave_w_DMA               
                               (
    .WBs_CLK_i                 ( WB_CLK                      	),
    .WBs_RST_i                 ( WB_RST                      	),

    .WBs_ADR_i                 ( WBs_ADR[ADDRWIDTH_DMA_REG+1:2] ),

    .WBs_CYC_i         		   ( WBs_CYC_I2S_S                  ),

    .WBs_BYTE_STB_i            ( WBs_BYTE_STB                   ),
    .WBs_WE_i                  ( WBs_WE                       	),
    .WBs_STB_i                 ( WBs_STB                      	),
    .WBs_DAT_i                 ( WBs_WR_DAT                     ),
    .WBs_DAT_o                 ( WBs_DAT_I2S_S                  ),
    .WBs_ACK_o                 ( WBs_ACK_I2S_S                  ),

    .I2S_CLK_i                 ( I2S_CLK_i             			),  
    .I2S_WS_CLK_i              ( I2S_WS_CLK_i              		),
    .I2S_DIN_i           	   ( I2S_DIN_i                      ),

    .I2S_RX_Intr_o             ( I2S_RX_Intr_o                  ), 
	.I2S_DMA_Intr_o            ( I2S_DMA_Intr_o                 ),
	.I2S_Dis_Intr_o            ( I2S_Dis_Intr_o                 ),

    .SDMA_Req_I2S_o            ( SDMA_Req_I2S_o                 ), 
    .SDMA_Sreq_I2S_o           ( SDMA_Sreq_I2S_o                ),
    .SDMA_Done_I2S_i           ( SDMA_Done_I2S_i                ),
    .SDMA_Active_I2S_i         ( SDMA_Active_I2S_i              )
                                                                );
//pragma attribute u_I2S_Slave_w_DMA   preserve_cell true


endmodule
