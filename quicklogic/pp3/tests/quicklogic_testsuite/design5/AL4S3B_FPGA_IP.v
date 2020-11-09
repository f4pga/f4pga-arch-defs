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
//              located in the programmable fabric.
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
// 29/Jan/2018     1.5        Anand Wadke    Removed IR, added Decimation filter	
// 2/Mar/2018      1.6        Anand Wadke    Added Decimation filter,Added UART	
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps
//`define ENAB_UART_16550_inst

module AL4S3B_FPGA_IP ( 

                // AHB-To_FPGA Bridge I/F
                //
				//CLK_12M_i,

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
				
                // UART
                //
`ifdef ENAB_UART_16550_inst				
                SIN,
                SOUT,	
`endif				
				
				sys_ref_clk_i,
				
				//I2S signals
				I2S_CLK_i,
				I2S_WS_CLK_i,
				I2S_DIN_i,
				
				I2S_RX_Intr_o,
				I2S_DMA_Intr_o,
				I2S_Dis_Intr_o,
				UART_Intr_o,
				
				SDMA_Req_I2S_o,
                SDMA_Sreq_I2S_o,
                SDMA_Done_I2S_i,
                SDMA_Active_I2S_i,

				//IR Signals
				//IR_TXD_o,
				//IR_RXD_i,
				//Ir_intr_o, 
				
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

// Assumes 128K Byte FPGA Memory Aperture
/* parameter       FABRIC_REG_BASE_ADDR     = 17'h00000     ; 
parameter       I2S_f_RAM_BASE_ADDR_0    = 17'h00800     ; 
parameter       I2S_S_REG_BASE_ADDR      = 17'h01000     ; 
parameter       FIR_COSSIN_RAM_BASE_ADDR_0  = 17'h01800     ; 
parameter       UART_BASE_ADDR  			= 17'h02000     ;  */

parameter       FABRIC_REG_BASE_ADDR        = 17'h00000     ; 
parameter       I2S_S_REG_BASE_ADDR         = 17'h00800     ; 
parameter       FIR_COSSIN_RAM_BASE_ADDR_0  = 17'h01000     ; 
parameter       I2S_f_RAM_BASE_ADDR_0     = 17'h01800     ; 
parameter       I2S_f_RAM_BASE_ADDR_1     = 17'h02000     ; 


//parameter       UART_BASE_ADDR  			= 17'h02000     ; 
parameter       FABRIC_REG_ID_VALUE_ADR     =  7'h0; 
parameter       FABRIC_REVISION_NO_ADR      =  7'h1; 
parameter       FABRIC_REG_SCRATCH_REG_ADR  =  7'h2; 


parameter       AL4S3B_DEVICE_ID            = 20'h0AEC2;//20'h610EE; 
parameter       AL4S3B_REV_LEVEL            = 16'h0001;//16'h0100;
parameter       AL4S3B_SCRATCH_REG          = 32'h12345678  ;

parameter       AL4S3B_DEF_REG_VALUE        = 32'hFAB_DEF_AC; // Distinguish access to undefined area

parameter       DEFAULT_READ_VALUE          = 32'hBAD_FAB_AC; // Bad FPGA Access

parameter       ADDRWIDTH_DMA_REG           =  9            ;
parameter       DATAWIDTH_DMA_REG           = 32            ;

parameter       ADDRWIDTH_FAB_REG           =  7            ;
parameter       DATAWIDTH_FAB_REG           = 32            ;

wire  [9:0] 	f_real_dat_addr_w; 
wire  		    f_realindata_wr_en_w;
wire   		    f_realindata_rd_en_w; 
wire  [15:0]	f_realdata_i_w; 
wire  [15:0]	f_realdata_o_w; 

wire  [9:0]     wb_CosSin_RAM_aDDR_i_w;		
wire			wb_CosSin_RAM_Wen_i_w;
wire  [31:0]    wb_CosSin_RAM_Data_i_w;
wire  [31:0]    wb_CosSin_RAM_Data_o_w;
wire			wb_CosSin_RAM_rd_access_ctrl_i_w;



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

// UART
//
`ifdef ENAB_UART_16550_inst	
input           SIN              ;
output          SOUT             ;
`endif

input 			sys_ref_clk_i;

// I2S Slave I/F
input 			I2S_CLK_i		;
input 			I2S_WS_CLK_i	;
input 			I2S_DIN_i		;

output          I2S_RX_Intr_o   ;				
output          I2S_DMA_Intr_o  ;	
output          I2S_Dis_Intr_o  ;
output          UART_Intr_o      ;

input 			SDMA_Done_I2S_i	;
input 			SDMA_Active_I2S_i;

output          SDMA_Req_I2S_o  ;				
output          SDMA_Sreq_I2S_o ;

// GPIO
//
//inout   [21:0]  GPIO_PIN         ;

// Misc
//
output   [19:0]  Device_ID       ;

//Ir Debug Signals
`ifdef DEBUG
output [2:0]	rState_o;
output			rCRR_RISE_o;
//output			rRXD_o;
output			wMEM_WE_o;
output			wRX_CRR_CYC_CNT_SET1_o;
output			wRX_CRR_CYC_CNT_EN_o;	
`endif
//output          Ir_intr_o   ;
//input           CLK_12M_i		 ;
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
//wire            Ir_intr_o   ;
//------Define Parameters--------------
// Default I/O timeout statemachine
parameter       DEFAULT_IDLE   =  0  ;
parameter       DEFAULT_COUNT  =  1  ;


//------Internal Signals---------------
//
// GPIO

// Wishbone Bus Signals
//
wire            WBs_CYC_FPGA_Reg   ;
wire            WBs_CYC_I2SRx_Real_RAM           ; 
wire            WBs_CYC_I2SRx_Img_RAM           ; 
wire            WBs_CYC_I2S_S        ;
//wire            WBs_CYC_I2S_SIG        ;
wire            WBs_CYC_f_CosSin_RAM        ;

wire            WBs_ACK_FPGA_Reg   ;
//wire            WBs_ACK_IR           ;
wire            WBs_ACK_I2S_S        ; 
wire            WBs_ACK_UART         ;

wire    [31:0]  WBs_DAT_o_FPGA_Reg ;
wire    [31:0]  WBs_DAT_I2S_S        ;
wire    [31:0]  WBs_CosSin_RAM_DAT   ;
wire    [31:0]  WBs_f_RAM_DAT   ;
`ifdef ENAB_UART_16550_inst
wire    [15:0]  WBs_RD_DAT_UART       ;

`endif

wire 	 		 		f_ena_sig;
wire 	 		 		f_start_sig;

wire                    f_calc_done_sig;

wire 					sys_c21_div16_sig;
wire 					i2s_clk_div3_sig;

wire [9:0]				wb_L_f_Img_RAM_aDDR_sig;	
wire [15:0]				wb_L_f_Img_RAM_Data_sig;	
wire 				    wb_L_f_Img_RAM_Wen_sig;		
wire 				    wb_f_RAM_wr_rd_Mast_sel_sig;



//------Logic Operations---------------
//
// APERWIDTH                   = 17            ;
// APERSIZE                    =  9            ;
// Define the Chip Select for each interface
//
assign WBs_CYC_FPGA_Reg   	= (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == FABRIC_REG_BASE_ADDR    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );
							
assign WBs_CYC_I2SRx_Real_RAM  = ((  WBs_ADR[APERWIDTH-1:APERSIZE+2] == I2S_f_RAM_BASE_ADDR_0[APERWIDTH-1:APERSIZE+2] ) |
								  (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == I2S_f_RAM_BASE_ADDR_1[APERWIDTH-1:APERSIZE+2] ))	
                            & (  WBs_CYC                                                                                );

assign WBs_CYC_I2SRx_Img_RAM  = ((  WBs_ADR[APERWIDTH-1:APERSIZE+2] == I2S_f_RAM_BASE_ADDR_0[APERWIDTH-1:APERSIZE+2] ) |
								  (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == I2S_f_RAM_BASE_ADDR_1[APERWIDTH-1:APERSIZE+2] ))	
                            & (  WBs_CYC                                                                                );							

assign WBs_CYC_I2S_S       		= (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == I2S_S_REG_BASE_ADDR    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );

assign WBs_CYC_f_CosSin_RAM    = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == FIR_COSSIN_RAM_BASE_ADDR_0    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );	

`ifdef ENAB_UART_16550_inst							
assign WBs_CYC_UART         = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == UART_BASE_ADDR          [APERWIDTH-1:APERSIZE+2] ) 
                            & (( WBs_CYC & WBs_WE  & WBs_BYTE_STB[0]                                                    ) 
                            |  ( WBs_CYC & WBs_RD                                                                       ));
`endif							

					

// Define the Acknowledge back to the host for everything
//
assign WBs_ACK              =    WBs_ACK_FPGA_Reg
                            |    WBs_ACK_I2S_S 
							|    WBs_ACK_UART;  
                            

assign rx_debug_o[0]           = i2s_clk_div3_sig;
assign rx_debug_o[1]           = I2S_WS_CLK_i ;
assign rx_debug_o[2]           = sys_c21_div16_sig;
							
// Define the how to read from each IP
//
always @(
         WBs_ADR               or
         WBs_DAT_o_FPGA_Reg  or
         WBs_DAT_I2S_S         or 
`ifdef ENAB_UART_16550_inst		 
         WBs_RD_DAT_UART        or 
`endif		 
         WBs_CosSin_RAM_DAT    or 
         WBs_f_RAM_DAT       or 
         WBs_RD_DAT    
        )
 begin
    case(WBs_ADR[APERWIDTH-1:APERSIZE+2])
    FABRIC_REG_BASE_ADDR    [APERWIDTH-1:APERSIZE+2]		: WBs_RD_DAT  <=    WBs_DAT_o_FPGA_Reg   ;
    I2S_S_REG_BASE_ADDR     [APERWIDTH-1:APERSIZE+2]		: WBs_RD_DAT  <=    WBs_DAT_I2S_S   ;
    FIR_COSSIN_RAM_BASE_ADDR_0 [APERWIDTH-1:APERSIZE+2]		: WBs_RD_DAT  <=    WBs_CosSin_RAM_DAT   ;
    I2S_f_RAM_BASE_ADDR_0 [APERWIDTH-1:APERSIZE+2]		: WBs_RD_DAT  <=    WBs_f_RAM_DAT   ;
    I2S_f_RAM_BASE_ADDR_1 [APERWIDTH-1:APERSIZE+2]		: WBs_RD_DAT  <=    WBs_f_RAM_DAT   ;
`ifdef ENAB_UART_16550_inst	
	UART_BASE_ADDR          [APERWIDTH-1:APERSIZE+2]		: WBs_RD_DAT  <= { 16'h0, WBs_RD_DAT_UART        };
`endif	
	
	default:                                            WBs_RD_DAT  <=    DEFAULT_READ_VALUE     ;
	endcase
end

//------Instantiate Modules------------
//

// Define the FPGA I/O Pad Signals
//
// Note: Use the Constraint manager in SpDE to assign these buffers to FBIO pads.
//

// UART
//
`ifdef ENAB_UART_16550_inst
inpad  u_inpad_I22  ( .P( SIN          ),  .Q( SIN_i         )  );
outpad u_outpad_I27 ( .A( SOUT_o        ), .P( SOUT         ) );
`endif


// General FPGA Resources 
//
// General FPGA Resources 
//
 AL4S3B_FPGA_Registers #(

    .ADDRWIDTH                  ( ADDRWIDTH_FAB_REG             ),
    .DATAWIDTH                  ( DATAWIDTH_FAB_REG             ),

    .FABRIC_REG_ID_VALUE_ADR    ( FABRIC_REG_ID_VALUE_ADR       ),
	.FABRIC_REVISION_NO_ADR     ( FABRIC_REVISION_NO_ADR        ),
    .FABRIC_REG_SCRATCH_REG_ADR ( FABRIC_REG_SCRATCH_REG_ADR    ),

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
    //.WBs_ADR_i                 ( WBs_ADR[ADDRWIDTH_DMA_REG+1:2] ),
    .WBs_ADR_i                 ( WBs_ADR[ADDRWIDTH_DMA_REG+2:2] ),// To accommodate the RAM access

    .WBs_CYC_i         		   ( WBs_CYC_I2S_S                  ),
    .WBs_CYC_I2SRx_Real_RAM_i  ( WBs_CYC_I2SRx_Real_RAM        ),
    .WBs_CYC_I2SRx_Img_RAM_i   ( WBs_CYC_I2SRx_Img_RAM        ),
    .WBs_CYC_f_CosSin_RAM_i  ( WBs_CYC_f_CosSin_RAM          ),
	
	.wb_L_f_Img_RAM_aDDR_o	( wb_L_f_Img_RAM_aDDR_sig			),
	.wb_L_f_Img_RAM_Data_i	( wb_L_f_Img_RAM_Data_sig			),
	.wb_L_f_Img_RAM_Wen_o     ( wb_L_f_Img_RAM_Wen_sig		),
	.wb_f_RAM_wr_rd_Mast_sel_o( wb_f_RAM_wr_rd_Mast_sel_sig		),
	
    .WBs_BYTE_STB_i            ( WBs_BYTE_STB                   ),
    .WBs_WE_i                  ( WBs_WE                       	),
    .WBs_STB_i                 ( WBs_STB                      	),
    .WBs_DAT_i                 ( WBs_WR_DAT                     ),
    .WBs_DAT_o                 ( WBs_DAT_I2S_S                  ),
    .WBs_CosSin_RAM_DAT_o      ( WBs_CosSin_RAM_DAT               ),
    .WBs_f_RAM_DAT_o         ( WBs_f_RAM_DAT               ),
    .WBs_ACK_o                 ( WBs_ACK_I2S_S                  ),
	
	.sys_ref_clk_i		   ( sys_ref_clk_i ),

    .I2S_CLK_i                 ( I2S_CLK_i             			),  
    .I2S_WS_CLK_i              ( I2S_WS_CLK_i              		),
    .I2S_DIN_i           	   ( I2S_DIN_i                      ),

    .I2S_RX_Intr_o             ( I2S_RX_Intr_o                  ), 
	.I2S_DMA_Intr_o            ( I2S_DMA_Intr_o                 ),
	.I2S_Dis_Intr_o            ( I2S_Dis_Intr_o                 ),

     //f Data Ram interface-Real
	.f_Real_RAM_RaDDR_i		(	f_real_dat_addr_w		),								 								 
	.f_Real_RAM_WaDDR_i		(	f_real_dat_addr_w		),								 								 
	.f_Real_RAM_Wr_en_i		(	f_realindata_wr_en_w	),								 								 
	//.f_realindata_rd_en_i		(	f_realindata_rd_en_w	),
    .f_Real_RAM_WR_DATA_i		(	f_realdata_o_w		),	
	.f_Real_RAM_RD_DATA_o		(	f_realdata_i_w		),								 

	.f_start_o		       ( f_start_sig	),   
	.f_ena_o				   ( f_ena_sig   ),	
	
	//Coeff Ram Interface
	.wb_CosSin_RAM_aDDR_o		(	wb_CosSin_RAM_aDDR_i_w	),
	.wb_CosSin_RAM_Wen_o		(	wb_CosSin_RAM_Wen_i_w	),
	.wb_CosSin_RAM_Data_o		(	wb_CosSin_RAM_Data_i_w	),	
	.wb_CosSin_RAM_Data_i		(	wb_CosSin_RAM_Data_o_w	),		
	.wb_CosSin_RAM_rd_access_ctrl_o	(	wb_CosSin_RAM_rd_access_ctrl_i_w	),
	
	.f_calc_done_i		   ( f_calc_done_sig   ),	//f_calc_done_i

    .sys_c21_div16_o           ( sys_c21_div16_sig ),	
    .i2s_clk_div3_o            ( i2s_clk_div3_sig ),	
	//

    .SDMA_Req_I2S_o            ( SDMA_Req_I2S_o                 ), 
    .SDMA_Sreq_I2S_o           ( SDMA_Sreq_I2S_o                ),
    .SDMA_Done_I2S_i           ( SDMA_Done_I2S_i                ),
    .SDMA_Active_I2S_i         ( SDMA_Active_I2S_i              )
                                                                );
//pragma attribute u_I2S_Slave_w_DMA   preserve_cell true
						
f_compute f_compute_inst0(
                                 .f_clk_i			(	WB_CLK	),
								 .f_reset_i		(	WB_RST	),
								 .f_ena_i			(	f_ena_sig	),
								 
								 .f_start_i		(	f_start_sig	),
								 
								 .WBs_CLK_i			(	WB_CLK	),
								 .WBs_RST_i			(	WB_RST	),
								 
								 //f Data Ram interface-Real
								 .f_real_dat_addr_o		(	f_real_dat_addr_w	),								 								 
								 .f_realindata_wr_en_o	(	f_realindata_wr_en_w	),								 								 
								 .f_realindata_rd_en_o	(	f_realindata_rd_en_w	),								 							 
								 .f_realdata_i			(	f_realdata_i_w	),								 
								 .f_realdata_o			(	f_realdata_o_w	),
								 
								 //Coeff Ram Interface
								 .wb_CosSin_RAM_aDDR_i		(	wb_CosSin_RAM_aDDR_i_w	),
								 .wb_CosSin_RAM_Wen_i		(	wb_CosSin_RAM_Wen_i_w	),
								 .wb_CosSin_RAM_Data_i		(	wb_CosSin_RAM_Data_i_w	),	
								 .wb_CosSin_RAM_Data_o		(	wb_CosSin_RAM_Data_o_w	),		
								 .wb_CosSin_RAM_rd_access_ctrl_i	(	wb_CosSin_RAM_rd_access_ctrl_i_w	),
								 
								 //Wishbone Read interface to f img data.
								 .wb_L_f_Img_RAM_aDDR_i	 ( wb_L_f_Img_RAM_aDDR_sig			),
								 .wb_L_f_Img_RAM_Data_o	 ( wb_L_f_Img_RAM_Data_sig			),
								 .wb_L_f_Img_RAM_Wen_i     ( wb_L_f_Img_RAM_Wen_sig		        ),
								 .wb_f_RAM_wr_rd_Mast_sel_i( wb_f_RAM_wr_rd_Mast_sel_sig		),
							     
								 .f_calc_done_o	(	f_calc_done_sig	)

								);	

								
								


`ifdef ENAB_UART_16550_inst
// Serial Port
//
UART_16550 u_UART_16550        
                               ( 
    // AHB-To_FPGA Bridge I/F
    //
    .WBs_ADR_i                 ( WBs_ADR[5:2]                   ),
    .WBs_CYC_i                 ( WBs_CYC_UART                   ),
    .WBs_WE_i                  ( WBs_WE                         ),
    .WBs_STB_i                 ( WBs_STB                        ),
    .WBs_DAT_i                 ( WBs_WR_DAT[7:0]                ),
    .WBs_CLK_i                 ( WB_CLK                         ),
    .WBs_RST_i                 ( WB_RST                         ),
    .WBs_DAT_o                 ( WBs_RD_DAT_UART                 ),
    .WBs_ACK_o                 ( WBs_ACK_UART                   ),

	.SIN_i                     ( SIN_i                          ),
	.SOUT_o                    ( SOUT_o                         ),

	.INTR_o                    ( UART_Intr_o                    )
                                                                );
																
`else
assign    WBs_ACK_UART = 0;  	
assign    WBs_RD_DAT_UART = 16'h0; 
assign    UART_Intr_o = 0; 															
`endif

endmodule
