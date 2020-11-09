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
parameter       FPGA_REG_BASE_ADDRESS     = 17'h00000     ; 
parameter       I2S_RAM_REG_BASE_ADDRESS    = 17'h00800     ; 
parameter       I2S_S_REG_BASE_ADDRESS      = 17'h01000     ; 
parameter       FIR_COEFF_REG_BASE_ADDRESS  = 17'h01800     ; 
parameter       UART_BASE_ADDRESS  			= 17'h02000     ; 

parameter       FPGA_REG_ID_VALUE_ADR     =  7'h0; 
parameter       FPGA_REVISION_NO_ADR      =  7'h1; 
parameter       FPGA_REG_SCRATCH_REG_ADR  =  7'h2; 

//parameter       AL4S3B_DEVICE_ID            = 20'h610EF;
//parameter       AL4S3B_REV_LEVEL            = 16'h0101;
parameter       AL4S3B_DEVICE_ID            = 20'h0AEC2;//20'h610EE; 
parameter       AL4S3B_REV_LEVEL            = 16'h0002;//Revision 2 
parameter       AL4S3B_SCRATCH_REG          = 32'h12345678  ;

parameter       AL4S3B_DEF_REG_VALUE        = 32'hFAB_DEF_AC; // Distinguish access to undefined area

parameter       DEFAULT_READ_VALUE          = 32'hBAD_FAB_AC; // Bad FPGA Access

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
wire            WBs_CYC_I2S_PREDECI_RAM           ; 
wire            WBs_CYC_I2S_S        ;
wire            WBs_CYC_I2S_SIG        ;
wire            WBs_CYC_FIR_COEFF_RAM        ;

wire            WBs_ACK_FPGA_Reg   ;
wire            WBs_ACK_IR           ;
wire            WBs_ACK_I2S_S        ; 
wire            WBs_ACK_UART         ;

wire    [31:0]  WBs_DAT_o_FPGA_Reg ;
wire    [31:0]  WBs_DAT_I2S_S        ;
wire    [31:0]  WBs_COEF_RAM_DAT        ;
wire    [15:0]  WBs_RD_DAT_UART       ;


wire  [7:0]  WBs_RD_DAT_ir       ;  // Read Data Bus              from FPGA

//FIR interface signals
//wire 	[9:0]  			 FIR_DATA_RaDDR_sig;
wire 	[8:0]  			 FIR_DATA_RaDDR_sig;
wire 	[15:0]  		 FIR_RD_DATA_sig;
wire 	 		 		 FIR_ena_sig;

wire   					fir_deci_data_push_sig;  
wire  [15:0]			fir_deci_data_sig; 

wire  [15:0]			fir_dat_mul_sig; 
wire  [15:0]			fir_coef_mul_sig; 
wire  [1:0]				fir_mul_valid_sig; 
wire  [31:0]			fir_cmult_sig;

wire   [31:0]		amult_int;
wire   [31:0]		bmult_int;
wire   [63:0]		cmult_int;

wire        FIR_DECI_Done_sig;

wire  [8:0]             FIR_RXRAM_w_Addr_sig;
wire                    FIR_I2S_RXRAM_w_ena_sig;

wire  [8:0]  			wb_Coeff_RAM_aDDR_sig;		
wire 					wb_Coeff_RAM_Wen_sig;
wire  [15:0]            wb_Coeff_RAM_Data_sig;

wire 				    i2s_clk_gclk;

wire [15:0] 			wb_Coeff_RAM_rd_Data_sig;
wire 					wb_coeff_RAM_access_ctrl_sig;

wire 					sys_c21_div16_sig;
wire 					i2s_clk_div3_sig;

//------Logic Operations---------------
//
// APERWIDTH                   = 17            ;
// APERSIZE                    =  9            ;
// Define the Chip Select for each interface
//
assign WBs_CYC_FPGA_Reg   	= (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == FPGA_REG_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );
							
assign WBs_CYC_I2S_PREDECI_RAM  = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == I2S_RAM_REG_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );							

assign WBs_CYC_I2S_S       		= (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == I2S_S_REG_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );

assign WBs_CYC_FIR_COEFF_RAM    = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == FIR_COEFF_REG_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );	
							
assign WBs_CYC_UART         = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == UART_BASE_ADDRESS          [APERWIDTH-1:APERSIZE+2] ) 
                            & (( WBs_CYC & WBs_WE  & WBs_BYTE_STB[0]                                                    ) 
                            |  ( WBs_CYC & WBs_RD                                                                       ));							

//assign WBs_CYC_I2S_SIG          = WBs_CYC_I2S_S | WBs_CYC_I2S_PREDECI_RAM | WBs_CYC_FIR_COEFF_RAM;							

//assign WBs_CYC_I2S_S       = (  WBs_ADR[APERWIDTH-1:APERSIZE+1] == I2S_S_REG_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+1] ) 
 //                           & (  WBs_CYC                                                                                );							

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
         WBs_RD_DAT_UART        or 
         WBs_COEF_RAM_DAT    or 
         WBs_RD_DAT    
        )
 begin
    case(WBs_ADR[APERWIDTH-1:APERSIZE+2])
    FPGA_REG_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2]		: WBs_RD_DAT  <=    WBs_DAT_o_FPGA_Reg   ;
    I2S_S_REG_BASE_ADDRESS     [APERWIDTH-1:APERSIZE+2]		: WBs_RD_DAT  <=    WBs_DAT_I2S_S   ;
    FIR_COEFF_REG_BASE_ADDRESS [APERWIDTH-1:APERSIZE+2]		: WBs_RD_DAT  <=    WBs_COEF_RAM_DAT   ;
	UART_BASE_ADDRESS          [APERWIDTH-1:APERSIZE+2]		: WBs_RD_DAT  <= { 16'h0, WBs_RD_DAT_UART        };
	
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


//pragma attribute ir_tx_rx_wrap_inst   preserve_cell true

// I2S Slave (RX mode) support with DMA
//
(* keep *)
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
    .WBs_CYC_I2S_PREDECI_RAM_i ( WBs_CYC_I2S_PREDECI_RAM        ),
    .WBs_CYC_FIR_COEFF_RAM_i   ( WBs_CYC_FIR_COEFF_RAM          ),

    .WBs_BYTE_STB_i            ( WBs_BYTE_STB                   ),
    .WBs_WE_i                  ( WBs_WE                       	),
    .WBs_STB_i                 ( WBs_STB                      	),
    .WBs_DAT_i                 ( WBs_WR_DAT                     ),
    .WBs_DAT_o                 ( WBs_DAT_I2S_S                  ),
    .WBs_COEF_RAM_DAT_o        ( WBs_COEF_RAM_DAT               ),
    .WBs_ACK_o                 ( WBs_ACK_I2S_S                  ),
	
	.sys_ref_clk_i		   ( sys_ref_clk_i ),

    .I2S_CLK_i                 ( I2S_CLK_i             			),  
    .I2S_WS_CLK_i              ( I2S_WS_CLK_i              		),
    .I2S_DIN_i           	   ( I2S_DIN_i                      ),

    .I2S_RX_Intr_o             ( I2S_RX_Intr_o                  ), 
	.I2S_DMA_Intr_o            ( I2S_DMA_Intr_o                 ),
	.I2S_Dis_Intr_o            ( I2S_Dis_Intr_o                 ),
	
	//FIR Decimation
	.i2s_clk_o                 (i2s_clk_gclk),
	.FIR_DATA_RaDDR_i		   ( FIR_DATA_RaDDR_sig	),
	.FIR_RD_DATA_o			   ( FIR_RD_DATA_sig	),		
	.FIR_ena_o				   ( FIR_ena_sig   ),
	
	.wb_Coeff_RAM_aDDR_o	   ( wb_Coeff_RAM_aDDR_sig ),		
	.wb_Coeff_RAM_Wen_o		   ( wb_Coeff_RAM_Wen_sig  ),		
	.wb_Coeff_RAM_Data_o	   ( wb_Coeff_RAM_Data_sig ),
    .wb_Coeff_RAM_Data_i       (wb_Coeff_RAM_rd_Data_sig), 
	.wb_Coeff_RAM_rd_access_ctrl_o (wb_coeff_RAM_access_ctrl_sig), 
	
	.FIR_DECI_DATA_i		   ( fir_deci_data_sig	),
	.FIR_DECI_DATA_PUSH_i	   ( fir_deci_data_push_sig	),

	.FIR_I2S_RXRAM_w_Addr_o    ( FIR_RXRAM_w_Addr_sig),
	.FIR_I2S_RXRAM_w_ena_o     ( FIR_I2S_RXRAM_w_ena_sig),
	.i2s_Clock_Stoped_o        (i2s_Clock_Stoped_sig),	
	
	.FIR_DECI_Done_i		   ( FIR_DECI_Done_sig   ),	

    .sys_c21_div16_o           ( sys_c21_div16_sig ),	
    .i2s_clk_div3_o            ( i2s_clk_div3_sig ),	
	//

    .SDMA_Req_I2S_o            ( SDMA_Req_I2S_o                 ), 
    .SDMA_Sreq_I2S_o           ( SDMA_Sreq_I2S_o                ),
    .SDMA_Done_I2S_i           ( SDMA_Done_I2S_i                ),
    .SDMA_Active_I2S_i         ( SDMA_Active_I2S_i              )
                                                                );
//pragma attribute u_I2S_Slave_w_DMA   preserve_cell true
deci_filter_fir128coeff u_deci_filter_fir128coeff (
						.fir_clk_i				( WB_CLK  ),
                        .fir_reset_i			( WB_RST  ),
                        .fir_deci_ena_i			( FIR_ena_sig  ),
						.fir_filter_run_i		(FIR_FILTER_RUN_M4_CMD_SIG),
						
						//Coeff RAM Write interface
						.WBs_CLK_i                 ( WB_CLK                      	),
						.WBs_RST_i                 ( WB_RST                      	),

                        .I2S_last_ram_write_i	   ( i2s_Clock_Stoped_sig ),
                        .I2S_last_ram_addr_i	   ( FIR_RXRAM_w_Addr_sig ),
                        .I2S_ram_write_ena_i 	   ( FIR_I2S_RXRAM_w_ena_sig),
                        .I2S_clk_i 	   			   ( i2s_clk_gclk),//( I2S_CLK_i),
                                                
                       //Data Ram interface.  
						.fir_dat_addr_o			( FIR_DATA_RaDDR_sig  ),		
                        .fir_indata_rd_en_o		(   ),//RAM Block's read enable in I2S_slave_Rx_FIFO is always asserted.
                        .fir_data_i				( FIR_RD_DATA_sig  ),
						
						.wb_Coeff_RAM_aDDR_i	( wb_Coeff_RAM_aDDR_sig ),		
						.wb_Coeff_RAM_Wen_i		( wb_Coeff_RAM_Wen_sig  ),		
						.wb_Coeff_RAM_Data_i	( wb_Coeff_RAM_Data_sig ),
						.wb_Coeff_RAM_Data_o    (wb_Coeff_RAM_rd_Data_sig),   
						.wb_Coeff_RAM_rd_access_ctrl_i (wb_coeff_RAM_access_ctrl_sig), 
                                              
                        //16*16 mult            
                        .fir_dat_mul_o			( fir_dat_mul_sig  	),
                        .fir_coef_mul_o			( fir_coef_mul_sig  ),
                        .fir_mul_valid_o		( fir_mul_valid_sig  ),
                        .fir_cmult_i			( fir_cmult_sig  	),
                                                
                        .fir_deci_data_o		( fir_deci_data_sig  ),
                        .fir_deci_data_push_o   ( fir_deci_data_push_sig  ),
						.fir_deci_done_o        ( FIR_DECI_Done_sig )
						
/* 						.WBs_ADR_i                 ( WBs_ADR[ADDRWIDTH_DMA_REG+1:2] ),
						.WBs_CYC_i         		   ( WBs_CYC_FIR_DECI_COEFF_DATA_RAM ),
						.WBs_BYTE_STB_i            ( WBs_BYTE_STB                   ),
						.WBs_WE_i                  ( WBs_WE                       	),
						.WBs_STB_i                 ( WBs_STB                      	),
						.WBs_DAT_i                 ( WBs_WR_DAT                     ),
						.WBs_DAT_o                 ( WBs_FIR_COEFF_DATA_RAM_S       ),
						.WBs_ACK_o                 ( WBs_ACK_FIR_DECI_COEFF_RAM     ), */							
						
						);


/*
qlal4s3_mult_16x16_cell u_qlal4s3_mult_16x16_cell //qlal4s3_mult_16x16_cell 
						( 
							.Amult			(fir_dat_mul_sig), 
							.Bmult			(fir_coef_mul_sig), 
							.Valid_mult		(fir_mul_valid_sig),
                            //.sel_mul_32x32  (1'b0),							
							.Cmult			(fir_cmult_sig));
							
*/

assign amult_int = {{16{fir_dat_mul_sig[15]}},fir_dat_mul_sig};
assign bmult_int = {{16{fir_coef_mul_sig[15]}},fir_coef_mul_sig};
assign fir_cmult_sig = cmult_int[31:0];

qlal4s3_mult_cell_macro u_qlal4s3_mult_cell_macro//qlal4s3_mult_cell_macro 
						( 
							.Amult			(amult_int), 
							.Bmult			(bmult_int), 
							.Valid_mult		(2'b11),
                            .sel_mul_32x32  (1'b0),							
							.Cmult			(cmult_int));



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
