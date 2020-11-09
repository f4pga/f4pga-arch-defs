// -----------------------------------------------------------------------------
// title          : AL4S3B Example FPGA IP Top Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : AL4S3B_FPGA_top.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2016/02/01	
// last update    : 2016/02/01
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: The FPGA example IP design contains the essential logic for
//              interfacing the ASSP of the AL4S3B to IP located in the 
//              programmable FPGA.
// -----------------------------------------------------------------------------
// copyright (c) 2015
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         description
//
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps
module top ( 
			clk_out1,
			clk_out2,
			clk_out3,
			clk_out4,
			clk_out5,
			tff_out
           );


//------Port Parameters----------------
output			clk_out1;
output			clk_out2;
output			clk_out3;
output			clk_out4;
output			clk_out5; 
output			tff_out;

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

wire			Sys_Clk0;
wire			Sys_Clk0_Rst;
// Misc

wire			clk1;
wire			clk2;
wire			clk3;
wire			clk4;
wire			clk5;

reg 			clk2_r;
reg 			clk3_r;
reg 			clk4_r;
reg 			clk5_r; 
reg 			clk6_r; 

wire [15:0]		Device_ID;
//------Logic Operations---------------
//

// Determine the FPGA reset
//
// Note: Reset the FPGA IP on either the AHB or clock domain reset signals.

assign clk_out1 = clk1;
assign clk_out2 = clk2;
assign clk_out3 = clk3;
assign clk_out4 = clk4;
assign clk_out5 = clk5;
assign tff_out = clk6_r;

assign WB_RST_FPGA = Sys_Clk0_Rst | WB_RST;

gclkbuff u_gclkbuff_clock1 ( .A(Sys_Clk0) , .Z(clk1) );
gclkbuff u_gclkbuff_clock2 ( .A(clk2_r) , .Z(clk2) );
gclkbuff u_gclkbuff_clock3 ( .A(clk3_r) , .Z(clk3) );
gclkbuff u_gclkbuff_clock4 ( .A(clk4_r) , .Z(clk4) );
gclkbuff u_gclkbuff_clock5 ( .A(clk5_r) , .Z(clk5) );

always @( posedge clk1 or posedge WB_RST_FPGA)
begin
    if (WB_RST_FPGA)
    begin
		clk2_r	 	<= 1'b0;
    end  
    else
    begin
		clk2_r  <=  ~clk2_r ;
    end  
end

always @( posedge clk2 or posedge WB_RST_FPGA)
begin
    if (WB_RST_FPGA)
    begin
		clk3_r	 	<= 1'b0;
    end  
    else
    begin
		clk3_r  <=  ~clk3_r ;
    end  
end

always @( posedge clk3 or posedge WB_RST_FPGA)
begin
    if (WB_RST_FPGA)
    begin
		clk4_r	 	<= 1'b0;
    end  
    else
    begin
		clk4_r  <=  ~clk4_r ;
    end  
end

always @( posedge clk4 or posedge WB_RST_FPGA)
begin
    if (WB_RST_FPGA)
    begin
		clk5_r	 	<= 1'b0;
    end  
    else
    begin
		clk5_r  <=  ~clk5_r ;
    end  
end

always @( posedge clk5 or posedge WB_RST_FPGA)
begin
    if (WB_RST_FPGA)
    begin
		clk6_r	 	<= 1'b0;
    end  
    else
    begin
		clk6_r  <=  ~clk6_r ;
    end  
end

assign Device_ID = 16'hABCD ;

//------Instantiate Modules------------
//												 
// Verilog model of QLAL4S3B
//
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
    .SDMA_Req                  ({ 3'b000, 1'b0        }), // input   [3:0]
    .SDMA_Sreq                 (  4'b0000                   ), // input   [3:0]
    .SDMA_Done                 (), // output  [3:0]
    .SDMA_Active               (), // output  [3:0]
    //
    // FB Interrupts
    //
    .FB_msg_out                ({1'b0, 1'b0, 1'b0, 1'b0}), // input   [3:0]
    .FB_Int_Clr                (  8'h0                       ), // input   [7:0]
    .FB_Start                  (                             ), // output
    .FB_Busy                   (  1'b0                       ), // input
    //
    // FB Clocks
    //
    .Sys_Clk0                  ( Sys_Clk0                    ), // output
    .Sys_Clk0_Rst              ( Sys_Clk0_Rst                ), // output
    .Sys_Clk1                  (                     ), // output
    .Sys_Clk1_Rst              (                 ), // output
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
    .Device_ID                 ( Device_ID[15:0]             ), // input  [15:0]
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
