// -----------------------------------------------------------------------------
// title          : AL4S3B Example FPGA IP Top Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : AL4S3B_FPGA_top.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 28/Oct/2016	
// last update    : 28/Oct/2016
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: .
// -----------------------------------------------------------------------------
// copyright (c) 2016
// -----------------------------------------------------------------------------
// revisions  :
// date            version     author            description
// 28/Oct/2016      1.0        Anand A Wadke     Initial Release
// 28/Mar/2016      1.1        Rakesh M          Added I2S slave IP
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// ----------------------------------------------------------------------------- 
//

`timescale 1ns / 10ps
//`define SIM
//`define ENAB_UART_16550_inst
//`define USE_DEBUG_PORT
//`define DIS_I2S_CLK_O

module top ( 
            
                //IR_TXD_o,
                //IR_RXD_i,
				I2S_CLK_i,
				I2S_CLK_o,//Added for Fixing Bootstrap issue
				I2S_WS_CLK_i,
				I2S_DIN_i
`ifdef USE_DEBUG_PORT				
				,
				test_sysclk1_o,
				test_sysclk2_o,
				test_sysclk3_o

`endif
`ifdef ENAB_UART_16550_inst
                ,
				SIN,
                SOUT
`endif				
 

                );


//pragma attribute I2S_WS_CLK_i 				buffer_sig 			inpad

//------Port Signals-------------------
//
//I2S Slave signals
//
input            I2S_CLK_i        ;
output           I2S_CLK_o        ;
input            I2S_WS_CLK_i     ;
input            I2S_DIN_i        ;

// IR signals
//
//output           IR_TXD_o            ;
//input            IR_RXD_i            ;
//`ifndef SIM	
`ifdef USE_DEBUG_PORT	
output           test_sysclk1_o   ;
output           test_sysclk2_o   ;
output           test_sysclk3_o   ;
`endif

`ifdef ENAB_UART_16550_inst
// UART
//
input           SIN            ;
output          SOUT           ;
`endif



// I2S slave signals
//
wire             I2S_CLK_i        ;
wire             I2S_WS_CLK_i     ;
wire             I2S_DIN_i        ;
// IR signals
//
//wire             IR_TXD_o    		  ;
//wire             IR_RXD_i    		  ;


//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//

// FPGA Global Signals
//
wire            WB_CLK         ; // Selected FPGA Clock

wire            Sys_Clk0       ; // Selected FPGA Clock
wire            Sys_Clk0_Rst   ; // Selected FPGA Reset

// Wishbone Bus Signals
//
wire    [16:0]  WBs_ADR        ; // Wishbone Address Bus
wire            WBs_CYC        ; // Wishbone Client Cycle  Strobe (i.e. Chip Select)
wire     [3:0]  WBs_BYTE_STB   ; // Wishbone Byte   Enables
wire            WBs_WE         ; // Wishbone Write  Enable Strobe
wire            WBs_RD         ; // Wishbone Read   Enable Strobe
wire            WBs_STB        ; // Wishbone Transfer      Strobe
wire    [31:0]  WBs_RD_DAT     ; // Wishbone Read   Data Bus
wire    [31:0]  WBs_WR_DAT     ; // Wishbone Write  Data Bus
wire            WBs_ACK        ; // Wishbone Client Acknowledge
wire            WB_RST         ; // Wishbone FPGA Reset
wire            WB_RST_FPGA  ; // Wishbone FPGA Reset

//I2S Slave signals
//
wire            I2S_RX_Intr   ; 
wire            I2S_DMA_Intr  ; 
wire            I2S_Dis_Intr  ;
wire            UART_Intr  ;

wire            SDMA_Req_I2S   ; 
wire            SDMA_Sreq_I2S  ;
wire            SDMA_Done_I2S  ;
wire            SDMA_Active_I2S;

wire    [2:0]   SDMA_Done_Extra  ;
wire    [2:0]   SDMA_Active_Extra;


// Misc
//
wire    [19:0]  Device_ID      ;

//wire            Ir_Intr   ;
wire			sys_ref_clk_sig;
wire			CLK_12M_IN;

wire [7:0] rx_debug_o;

//`ifdef SIM
`ifndef USE_DEBUG_PORT
wire            test_sysclk1_o   ;
wire            test_sysclk2_o   ;
wire            test_sysclk3_o   ;
`endif

//assign test_sysclk1_o = CLK_12M_IN;
assign test_sysclk1_o = rx_debug_o[0];
assign test_sysclk2_o = rx_debug_o[1];
assign test_sysclk3_o = rx_debug_o[2];

//`ifdef DIS_I2S_CLK_O
//assign I2S_CLK_o = 1'b0;//for bootstrap issue fix
//`else
assign I2S_CLK_o = I2S_CLK_i;//for bootstrap issue fix
//`endif

//------Logic Operations---------------
//

// Determine the FPGA reset
//
// Note: Reset the FPGA IP on either the AHB or clock domain reset signals.
//
//gclkbuff u_gclkbuff_reset ( .A(Sys_Clk0_Rst | WB_RST) , .Z(WB_RST_FPGA) );
assign WB_RST_FPGA = Sys_Clk0_Rst | WB_RST ;
gclkbuff u_gclkbuff_clock ( .A(Sys_Clk0             ) , .Z(WB_CLK       ) );

//gclkbuff u_gclkbuff_clock4M ( .A(CLK_4MHZ_IN             ) , .Z(clk_4mhz       ) );
//gclkbuff u_gclkbuff_clock12M ( .A(CLK_12M_IN             ) , .Z(CLK_12M       ) );
gclkbuff u_gclkbuff_clock48khz ( .A(SYS_C21_ACSLIPREF_Clk_sig ) , .Z(sys_ref_clk_sig       ) );


//------Instantiate Modules------------
//


// Example FPGA Design
//
(* keep *)
AL4S3B_FPGA_IP             

     u_AL4S3B_FPGA_IP        (

	// AHB-To_FPGA Bridge I/F
	//
	//.CLK_12M_i				   ( CLK_12M					 ),
	
    .WBs_ADR                   ( WBs_ADR                     ), // input  [16:0] | Address Bus                to   FPGA
    .WBs_CYC                   ( WBs_CYC                     ), // input         | Cycle Chip Select          to   FPGA
    .WBs_BYTE_STB              ( WBs_BYTE_STB                ), // input   [3:0] | Byte Select                to   FPGA
    .WBs_WE                    ( WBs_WE                      ), // input         | Write Enable               to   FPGA
    .WBs_RD                    ( WBs_RD                      ), // input         | Read  Enable               to   FPGA
    .WBs_STB                   ( WBs_STB                     ), // input         | Strobe Signal              to   FPGA
    .WBs_WR_DAT                ( WBs_WR_DAT                  ), // input  [31:0] | Write Data Bus             to   FPGA
    .WB_CLK                    ( WB_CLK                      ), // output        | FPGA Clock               from FPGA
    .WB_RST                    ( WB_RST_FPGA               ), // input         | FPGA Reset               to   FPGA
    .WBs_RD_DAT                ( WBs_RD_DAT                  ), // output [31:0] | Read Data Bus              from FPGA
    .WBs_ACK                   ( WBs_ACK                     ), // output        | Transfer Cycle Acknowledge from FPGA
	
`ifdef ENAB_UART_16550_inst
	.SIN					   ( SIN )            ,
	.SOUT          			   ( SOUT ) ,
`endif	

	.sys_ref_clk_i		   ( sys_ref_clk_sig ),
	 
    // I2S signals
	//
	.I2S_CLK_i				   ( I2S_CLK_i					 ),
	.I2S_WS_CLK_i			   ( I2S_WS_CLK_i				 ),
	.I2S_DIN_i				   ( I2S_DIN_i					 ),
	
	.I2S_RX_Intr_o			   ( I2S_RX_Intr				 ), 
	.I2S_DMA_Intr_o			   ( I2S_DMA_Intr			     ),
	.I2S_Dis_Intr_o			   ( I2S_Dis_Intr			     ),
	.UART_Intr_o			   ( UART_Intr			     ),

	.SDMA_Req_I2S_o			   ( SDMA_Req_I2S				 ), 
	.SDMA_Sreq_I2S_o		   ( SDMA_Sreq_I2S		  		 ),
	.SDMA_Done_I2S_i		   ( SDMA_Done_I2S		  		 ),
	.SDMA_Active_I2S_i		   ( SDMA_Active_I2S		     ),

    // IR signals
	//
    //.IR_TXD_o                     ( IR_TXD_o                       ),
    //.IR_RXD_i                     ( IR_RXD_i                       ),

	//.Ir_intr_o                 ( Ir_Intr                     ),

    // Misc
    //
    .Device_ID                 ( Device_ID                   ), // output [15:0]
 
	.rx_debug_o            	   ( rx_debug_o					 )

	 );
															 


// Empty Verilog model of QLAL4S3B
//
(* keep *)
qlal4s3b_cell_macro              u_qlal4s3b_cell_macro
                               (
    // AHB-To-FPGA Bridge
	//
    .WBs_ADR                   ( WBs_ADR                     ), // output [16:0] | Address Bus                to   FPGA
    .WBs_CYC                   ( WBs_CYC                     ), // output        | Cycle Chip Select          to   FPGA
    .WBs_BYTE_STB              ( WBs_BYTE_STB                ), // output  [3:0] | Byte Select                to   FPGA
    .WBs_WE                    ( WBs_WE                      ), // output        | Write Enable               to   FPGA
    .WBs_RD                    ( WBs_RD                      ), // output        | Read  Enable               to   FPGA
    .WBs_STB                   ( WBs_STB                     ), // output        | Strobe Signal              to   FPGA
    .WBs_WR_DAT                ( WBs_WR_DAT                  ), // output [31:0] | Write Data Bus             to   FPGA
    .WB_CLK                    ( WB_CLK                      ), // input         | FPGA Clock               from FPGA
    .WB_RST                    ( WB_RST                      ), // output        | FPGA Reset               to   FPGA
    .WBs_RD_DAT                ( WBs_RD_DAT                  ), // input  [31:0] | Read Data Bus              from FPGA
    .WBs_ACK                   ( WBs_ACK                     ), // input         | Transfer Cycle Acknowledge from FPGA
    //
    // SDMA Signals
    //
    .SDMA_Req                  ({3'h0,SDMA_Req_I2S}                ), // input   [3:0]     
    .SDMA_Sreq                 ({3'h0,SDMA_Sreq_I2S}               ), // input   [3:0]
    .SDMA_Done                 ({SDMA_Done_Extra,SDMA_Done_I2S}    ), // output  [3:0]
    .SDMA_Active               ({SDMA_Active_Extra,SDMA_Active_I2S}), // output  [3:0]

    //
    // FB Interrupts
    //
    //.FB_msg_out                ( {I2S_Dis_Intr,I2S_DMA_Intr,I2S_RX_Intr,Ir_Intr}), // input   [3:0]  
    .FB_msg_out                ( {I2S_Dis_Intr,I2S_DMA_Intr,I2S_RX_Intr,UART_Intr}), // input   [3:0]  
										
    .FB_Int_Clr                (  8'h0                       ), // input   [7:0]
    .FB_Start                  (                             ), // output
    .FB_Busy                   (  1'b0                       ), // input
    //
    // FB Clocks
    //
    .Sys_Clk0                  ( Sys_Clk0                    ), // output
    .Sys_Clk0_Rst              ( Sys_Clk0_Rst                ), // output
    //.Sys_Clk1                  ( CLK_12M_IN                  ), // output
    .Sys_Clk1                  ( SYS_C21_ACSLIPREF_Clk_sig                  ), // output
    .Sys_Clk1_Rst              (                             ), // output
    //
    // Packet FIFO
    //
    .Sys_PKfb_Clk              (  1'b0                       ), // input
    .Sys_PKfb_Rst              (                             ), // output
    .FB_PKfbData               ( 32'h0                       ), // input  [31:0]
    .FB_PKfbPush               (  4'h0                       ), // input   [3:0]
    .FB_PKfbSOF                (  1'b0                       ), // input
    .FB_PKfbEOF                (  1'b0                       ), // input
    .FB_PKfbOverflow           (                             ), // output
	//
	// Sensor Interface
	//
    .Sensor_Int                (                             ), // output  [7:0]
    .TimeStamp                 (                             ), // output [23:0]
    //
    // SPI Master APB Bus
    //
    .Sys_Pclk                  (                             ), // output
    .Sys_Pclk_Rst              (                             ), // output      <-- Fixed to add "_Rst"
    .Sys_PSel                  (  1'b0                       ), // input
    .SPIm_Paddr                ( 16'h0                       ), // input  [15:0]
    .SPIm_PEnable              (  1'b0                       ), // input
    .SPIm_PWrite               (  1'b0                       ), // input
    .SPIm_PWdata               ( 32'h0                       ), // input  [31:0]
    .SPIm_Prdata               (                             ), // output [31:0]
    .SPIm_PReady               (                             ), // output
    .SPIm_PSlvErr              (                             ), // output
    //
    // Misc
    //
    .Device_ID                 ( Device_ID[19:4]             ), // input  [15:0]
    //
    // FBIO Signals
    //
    .FBIO_In                   (                             ), // output [13:0] <-- Do Not make any connections; Use Constraint manager in SpDE to sFBIO
    .FBIO_In_En                (                             ), // input  [13:0] <-- Do Not make any connections; Use Constraint manager in SpDE to sFBIO
    .FBIO_Out                  (                             ), // input  [13:0] <-- Do Not make any connections; Use Constraint manager in SpDE to sFBIO
    .FBIO_Out_En               (                             ), // input  [13:0] <-- Do Not make any connections; Use Constraint manager in SpDE to sFBIO
	//
	// ???
	//
    .SFBIO                     (                             ), // inout  [13:0]
    .Device_ID_6S              ( 1'b0                        ), // input
    .Device_ID_4S              ( 1'b0                        ), // input
    .SPIm_PWdata_26S           ( 1'b0                        ), // input
    .SPIm_PWdata_24S           ( 1'b0                        ), // input
    .SPIm_PWdata_14S           ( 1'b0                        ), // input
    .SPIm_PWdata_11S           ( 1'b0                        ), // input
    .SPIm_PWdata_0S            ( 1'b0                        ), // input
    .SPIm_Paddr_8S             ( 1'b0                        ), // input
    .SPIm_Paddr_6S             ( 1'b0                        ), // input
    .FB_PKfbPush_1S            ( 1'b0                        ), // input
    .FB_PKfbData_31S           ( 1'b0                        ), // input
    .FB_PKfbData_21S           ( 1'b0                        ), // input
    .FB_PKfbData_19S           ( 1'b0                        ), // input
    .FB_PKfbData_9S            ( 1'b0                        ), // input
    .FB_PKfbData_6S            ( 1'b0                        ), // input
    .Sys_PKfb_ClkS             ( 1'b0                        ), // input
    .FB_BusyS                  ( 1'b0                        ), // input
    .WB_CLKS                   ( 1'b0                        )  // input
                                                             );

//pragma attribute u_qlal4s3b_cell_macro         preserve_cell true
//pragma attribute u_AL4S3B_FPGA_IP            preserve_cell true

endmodule
