`timescale 1ns/10ps
(* whitebox *)
(* keep *)
module ASSP (
			WB_CLK,
			WBs_ACK,
			WBs_RD_DAT,
			WBs_BYTE_STB,
			WBs_CYC,
			WBs_WE,
			WBs_RD,
			WBs_STB,
			WBs_ADR,
			SDMA_Req,
			SDMA_Sreq,
			SDMA_Done,
			SDMA_Active,
			FB_msg_out,
			FB_Int_Clr,
			FB_Start,
			FB_Busy,
			WB_RST,
			Sys_PKfb_Rst,
			Sys_Clk0,
			Sys_Clk0_Rst,
			Sys_Clk1,
			Sys_Clk1_Rst,
			Sys_Pclk,
			Sys_Pclk_Rst,
			Sys_PKfb_Clk,
			FB_PKfbData,
			WBs_WR_DAT,
			FB_PKfbPush,
			FB_PKfbSOF,
			FB_PKfbEOF,
			Sensor_Int,
			FB_PKfbOverflow,
			TimeStamp,
			Sys_PSel,
			SPIm_Paddr,
			SPIm_PEnable,
			SPIm_PWrite,
			SPIm_PWdata,
			SPIm_PReady,
			SPIm_PSlvErr,
			SPIm_Prdata,
			Device_ID
			);

  input wire         WB_CLK;
  input	wire         WBs_ACK;
  input	wire  [31:0] WBs_RD_DAT;
  output wire [3:0]  WBs_BYTE_STB;
  output wire        WBs_CYC;
  output wire        WBs_WE;
  output wire        WBs_RD;
  output wire        WBs_STB;
  output wire [16:0] WBs_ADR;
  input wire  [3:0]  SDMA_Req;
  input wire  [3:0]  SDMA_Sreq;
  output wire [3:0]  SDMA_Done;
  output wire [3:0]  SDMA_Active;
  input wire  [3:0]  FB_msg_out;
  input wire  [7:0]  FB_Int_Clr;
  output wire        FB_Start;
  input wire         FB_Busy;
  output wire        WB_RST;
  output wire        Sys_PKfb_Rst;
  output wire        Sys_Clk0;
  output wire        Sys_Clk0_Rst;
  output wire        Sys_Clk1;
  output wire        Sys_Clk1_Rst;
  output wire        Sys_Pclk;
  output wire        Sys_Pclk_Rst;
  input wire         Sys_PKfb_Clk;
  input wire  [31:0] FB_PKfbData;
  output wire [31:0] WBs_WR_DAT;
  input wire  [3:0]  FB_PKfbPush;
  input wire         FB_PKfbSOF;
  input wire         FB_PKfbEOF;
  output wire [7:0]  Sensor_Int;

  (* DELAY_MATRIX_FB_PKfbPush="{iopath_FB_PKfbPush0_FB_PKfbOverflow} {iopath_FB_PKfbPush1_FB_PKfbOverflow} {iopath_FB_PKfbPush2_FB_PKfbOverflow} {iopath_FB_PKfbPush3_FB_PKfbOverflow}" *)
  output wire        FB_PKfbOverflow;

  output wire [23:0] TimeStamp;
  input wire         Sys_PSel;
  input wire  [15:0] SPIm_Paddr;
  input wire         SPIm_PEnable;
  input wire         SPIm_PWrite;
  input wire  [31:0] SPIm_PWdata;

  (* DELAY_CONST_Sys_PSel="{iopath_Sys_PSel_SPIm_PReady}" *)
  output wire        SPIm_PReady;

 (* DELAY_CONST_Sys_PSel="{iopath_Sys_PSel_SPIm_PSlvErr}" *)
  output wire        SPIm_PSlvErr;

  (* DELAY_MATRIX_Sys_PSel= "{iopath_Sys_PSel_SPIm_Prdata0} {iopath_Sys_PSel_SPIm_Prdata1} {iopath_Sys_PSel_SPIm_Prdata2} {iopath_Sys_PSel_SPIm_Prdata3} {iopath_Sys_PSel_SPIm_Prdata4} {iopath_Sys_PSel_SPIm_Prdata5} {iopath_Sys_PSel_SPIm_Prdata6} {iopath_Sys_PSel_SPIm_Prdata7} {iopath_Sys_PSel_SPIm_Prdata8} {iopath_Sys_PSel_SPIm_Prdata9} {iopath_Sys_PSel_SPIm_Prdata10} {iopath_Sys_PSel_SPIm_Prdata11} {iopath_Sys_PSel_SPIm_Prdata12} {iopath_Sys_PSel_SPIm_Prdata13} {iopath_Sys_PSel_SPIm_Prdata14} {iopath_Sys_PSel_SPIm_Prdata15} {iopath_Sys_PSel_SPIm_Prdata16} {iopath_Sys_PSel_SPIm_Prdata17} {iopath_Sys_PSel_SPIm_Prdata18} {iopath_Sys_PSel_SPIm_Prdata19} {iopath_Sys_PSel_SPIm_Prdata20} {iopath_Sys_PSel_SPIm_Prdata21} {iopath_Sys_PSel_SPIm_Prdata22} {iopath_Sys_PSel_SPIm_Prdata23} {iopath_Sys_PSel_SPIm_Prdata24} {iopath_Sys_PSel_SPIm_Prdata25} {iopath_Sys_PSel_SPIm_Prdata26} {iopath_Sys_PSel_SPIm_Prdata27} {iopath_Sys_PSel_SPIm_Prdata28} {iopath_Sys_PSel_SPIm_Prdata29} {iopath_Sys_PSel_SPIm_Prdata30} {iopath_Sys_PSel_SPIm_Prdata31}" *)
  output wire [31:0] SPIm_Prdata;

  input wire  [15:0] Device_ID;

  // dummy assignents to mark combinational depenedencies
  assign SPIm_Prdata = (Sys_PSel == 1'b1) ? 32'h00000000 : 32'h00000000;
  assign SPIm_PReady = (Sys_PSel == 1'b1) ? 1'b0 : 1'b0;
  assign SPIm_PSlvErr = (Sys_PSel == 1'b1) ? 1'b0 : 1'b0;
  assign FB_PKfbOverflow = (FB_PKfbPush != 4'b0000) ? 1'b0 : 1'b0;

endmodule
