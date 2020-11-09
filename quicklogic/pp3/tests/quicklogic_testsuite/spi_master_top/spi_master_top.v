// -----------------------------------------------------------------------------
// title          : SPI Master	
// project        : SPI Master PSB
// -----------------------------------------------------------------------------
// file           : spi_master_top.v , Top Level File
// author         : XXXXXX		
// company        : QuickLogic Corp
// created        : 2015/06/21
// last update    : 
// platform       : 
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: Top module
// -----------------------------------------------------------------------------
// copyright (c) 2012
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author              description
// 2008/xx/xx      1.0        XXXXX               created
// -----------------------------------------------------------------------------
// Comments: 
// -----------------------------------------------------------------------------
// ---------- Design Unit Header ---------- //
`timescale 1ns / 10ps

module top ( MISO_i, MOSI_o, SCLK_o, SSn0_o, SSn1_o, SSn2_o, SSn3_o, SSn4_o, SSn5_o, SSn6_o, SSn7_o);

// spi interface signals
input 		 MISO_i;
output 		 MOSI_o;
output 		 SCLK_o;
output 		 SSn0_o;
output 		 SSn1_o;
output 		 SSn2_o;
output 		 SSn3_o;
output 		 SSn4_o;
output 		 SSn5_o;
output 		 SSn6_o;
output 		 SSn7_o;


// ----------- Signal declarations -------- //
wire CPHA;
wire CPOL;
wire IRQ_read;
wire IRQ_write;
wire LSBFE;
wire BIDIROEn;
wire SPC0;
wire SPE;
wire [15:0] divisor;
wire [7:0] SPI_Read_Data;
wire [7:0] SPI_Write_Data;
wire [7:0] SPI_CS_Reg;
wire [2:0] SPI_Bit_Ctrl;
wire [2:0] Ext_SPI_Clk_Cnt;
wire Ext_SPI_Clk_En;

reg wb_ack_r;

wire wb_wacc;
wire rst;
wire trnfer_cmplte;
wire start; 
wire stop;
wire read; 
wire write;

wire [3:0] WBs_BYTE_STB;
wire [16:0] WBs_ADR; 
wire [31:0] WBs_WR_DAT; 
wire [31:0] WBs_RD_DAT;
wire [2:0] wb_adr;
wire [7:0] wb_dat;
wire [7:0] wb_rd_dat;

wire WBs_CYC;
wire WBs_WE;	
wire WBs_RD;
wire WBs_STB; 
wire wb_clk;
wire wb_cyc;
wire wb_we;
wire wb_stb;
wire wb_ack;

wire Sys_Clk0_Rst;
wire wb_rst;
wire Sys_Clk0;

wire wb_inta;  
wire TIP; 

wire [15:0] Device_ID;

assign Device_ID = 16'h1234;
	
gclkbuff u_gclkbuff_reset ( .A(Sys_Clk0_Rst) , .Z(rst) );
gclkbuff u_gclkbuff_clock ( .A(Sys_Clk0             ) , .Z(wb_clk       ) );


assign wb_cyc = WBs_CYC;
assign wb_stb = WBs_STB;
assign wb_we  = WBs_WE;


// generate wishbone signals
assign wb_wacc = wb_we & wb_ack_r;

// generate acknowledge output signal
always @(posedge wb_clk or posedge rst)
  if (rst)
    wb_ack_r <= 1'b0;
  else if (wb_rst)
    wb_ack_r <= 1'b0;
  else
    wb_ack_r <= #1 wb_cyc & wb_stb & ~wb_ack_r; // because timing is always honored
	
assign wb_ack = wb_ack_r;

assign wb_adr = WBs_ADR[4:2];
assign wb_dat = WBs_WR_DAT[7:0];
assign WBs_RD_DAT = {24'h0, wb_rd_dat};

// -------- Component instantiations -------//
registers spi_register (
			.AD_i(wb_adr),
			.CLK_i(wb_clk),
			.RST_i(rst),
			.RST_SYNC_i(wb_rst),
			.WR_i(wb_wacc),

			.Data_i(wb_dat),
			.Data_o(wb_rd_dat),
			
			.Divisor_o(divisor),
			.SPE_o(SPE),
			.BIDIROEn_o(BIDIROEn),
			.SPC0_o(SPC0),
			.CPOL_o(CPOL),
			.CPHA_o(CPHA),
			.LSBFE_o(LSBFE),
			
			.trnfer_cmplte_i(trnfer_cmplte),
			.start_o(start),
			.stop_o(stop),
			.read_o(read),
			.write_o(write),
			
			.SPI_Bit_Ctrl_o(SPI_Bit_Ctrl),
			.Ext_SPI_Clk_Cnt_o(Ext_SPI_Clk_Cnt),
			.Ext_SPI_Clk_En_o(Ext_SPI_Clk_En),

			.SPI_Read_Data_i(SPI_Read_Data),
			.SPI_Write_Data_o(SPI_Write_Data),
			.SPI_CS_Reg_o(SPI_CS_Reg),
			.IRQ_read_i(IRQ_read),
			.IRQ_write_i(IRQ_write),
			.INTR_o(wb_inta),
			.TIP_o(TIP)
			);


serializer_deserializer ser_des(
			.MOSI_o(MOSI_o),
			.MISO_i(MISO_i),
			.SCK_o(SCLK_o),
			.SSn0_o(SSn0_o),
			.SSn1_o(SSn1_o),
			.SSn2_o(SSn2_o),
			.SSn3_o(SSn3_o),
			.SSn4_o(SSn4_o),
			.SSn5_o(SSn5_o),
			.SSn6_o(SSn6_o),
			.SSn7_o(SSn7_o),
			
			.Divisor_i(divisor),
			.SPE_i(SPE),
			.BIDIROEn_i(BIDIROEn),
			.SPC0_i(SPC0),
			.CPOL_i(CPOL),
			.CPHA_i(CPHA),
			.LSBFE_i(LSBFE),
			
			.trnfer_cmplte_o(trnfer_cmplte),
			.start_i(start),
			.stop_i(stop),
			.read_i(read),
			.write_i(write),
			
			.SPI_Bit_Ctrl_i(SPI_Bit_Ctrl),
			.Ext_SPI_Clk_Cnt_i(Ext_SPI_Clk_Cnt),
			.Ext_SPI_Clk_En_i(Ext_SPI_Clk_En),

			.Bus_CLK_i(wb_clk),
			.RST_i(rst),
			.RST_SYNC_i(wb_rst),
			
			.SPI_Read_Data_o(SPI_Read_Data),
			.SPI_Write_Data_i(SPI_Write_Data),
        	.SPI_CS_Reg_i(SPI_CS_Reg),

			.IRQ_read_o(IRQ_read),
			.IRQ_write_o(IRQ_write),
			.Baud_Clk_o()
			);
			
			
			
// Verilog model of QLAL4S3B
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
    .WB_CLK                    ( wb_clk                      ), // input         | FPGA Clock               from FPGA
    .WB_RST                    ( wb_rst                      ), // output        | FPGA Reset               to   FPGA
    .WBs_RD_DAT                ( WBs_RD_DAT                  ), // input  [31:0] | Read Data Bus              from FPGA
    .WBs_ACK                   ( wb_ack                      ), // input         | Transfer Cycle Acknowledge from FPGA
    //
    // SDMA Signals
    //
    .SDMA_Req                  (  4'b0000      				), // input   [3:0]
    .SDMA_Sreq                 (  4'b0000                   ), // input   [3:0]
    .SDMA_Done                 (							), // output  [3:0]
    .SDMA_Active               (							), // output  [3:0]
    //
    // FB Interrupts
    //
    .FB_msg_out                ({2'b00, TIP, wb_inta  }), // input   [3:0]
    .FB_Int_Clr                (  8'h0                       ), // input   [7:0]
    .FB_Start                  (                             ), // output
    .FB_Busy                   (  1'b0                       ), // input
    //
    // FB Clocks
    //
    .Sys_Clk0                  ( Sys_Clk0                    ), // output
    .Sys_Clk0_Rst              ( Sys_Clk0_Rst                ), // output
    .Sys_Clk1                  ( Sys_Clk1                    ), // output
    .Sys_Clk1_Rst              ( Sys_Clk1_Rst                ), // output
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

endmodule 
