(* whitebox *)
(* keep *)
module ASSP (
  input         WB_CLK,
  input         WBs_ACK,
  input  [31:0] WBs_RD_DAT,
  output [3:0]  WBs_BYTE_STB,
  output        WBs_CYC,
  output        WBs_WE,
  output        WBs_RD,
  output        WBs_STB,
  output [16:0] WBs_ADR,
  input  [3:0]  SDMA_Req,
  input  [3:0]  SDMA_Sreq,
  output [3:0]  SDMA_Done,
  output [3:0]  SDMA_Active,
  input  [3:0]  FB_msg_out,
  input  [7:0]  FB_Int_Clr,
  output        FB_Start,
  input         FB_Busy,
  output        WB_RST,
  output        Sys_PKfb_Rst,
  output        Sys_Clk0,
  output        Sys_Clk0_Rst,
  output        Sys_Clk1,
  output        Sys_Clk1_Rst,
  output        Sys_Pclk,
  output        Sys_Pclk_Rst,
  input         Sys_PKfb_Clk,
  input  [31:0] FB_PKfbData,
  output [31:0] WBs_WR_DAT,
  input  [3:0]  FB_PKfbPush,
  input         FB_PKfbSOF,
  input         FB_PKfbEOF,
  output [7:0]  Sensor_Int,
  output        FB_PKfbOverflow,
  output [23:0] TimeStamp,
  input         Sys_PSel,
  input  [15:0] SPIm_Paddr,
  input         SPIm_PEnable,
  input         SPIm_PWrite,
  input  [31:0] SPIm_PWdata,
  output        SPIm_PReady,
  output        SPIm_PSlvErr,
  output [31:0] SPIm_Prdata,
  input  [15:0] Device_ID
);


wire        WB_CLK;
wire        WBs_ACK;
wire [31:0] WBs_RD_DAT;
wire [3:0]  WBs_BYTE_STB;
wire        WBs_CYC;
wire        WBs_WE;
wire        WBs_RD;
wire        WBs_STB;
wire [16:0] WBs_ADR;
wire [3:0]  SDMA_Req;
wire [3:0]  SDMA_Sreq;
wire [3:0]  SDMA_Done;
wire [3:0]  SDMA_Active;
wire [3:0]  FB_msg_out;
wire [7:0]  FB_Int_Clr;
wire        FB_Start;
wire        FB_Busy;
wire        WB_RST;
wire        Sys_PKfb_Rst;
wire        Sys_Clk0;
wire        Sys_Clk0_Rst;
wire        Sys_Clk1;
wire        Sys_Clk1_Rst;
wire        Sys_Pclk;
wire        Sys_Pclk_Rst;
wire        Sys_PKfb_Clk;
wire [31:0] FB_PKfbData;
wire [31:0] WBs_WR_DAT;
wire [3:0]  FB_PKfbPush;
wire        FB_PKfbSOF;
wire        FB_PKfbEOF;
wire [7:0]  Sensor_Int;

(* DELAY_MATRIX_FB_PKfbPush="{iopath_FB_PKfbPush0_FB_PKfbOverflow} {iopath_FB_PKfbPush1_FB_PKfbOverflow} {iopath_FB_PKfbPush2_FB_PKfbOverflow} {iopath_FB_PKfbPush3_FB_PKfbOverflow}" *)

wire        FB_PKfbOverflow;
wire [23:0] TimeStamp;
wire        Sys_PSel;
wire [15:0] SPIm_Paddr;
wire        SPIm_PEnable;
wire        SPIm_PWrite;
wire [31:0] SPIm_PWdata;

(* DELAY_CONST_Sys_PSel="{iopath_Sys_PSel_SPIm_PReady}" *)

wire        SPIm_PReady;

(* DELAY_CONST_Sys_PSel="{iopath_Sys_PSel_SPIm_PSlvErr}" *)

wire        SPIm_PSlvErr;

(* DELAY_MATRIX_Sys_PSel= "{iopath_Sys_PSel_SPIm_Prdata0} {iopath_Sys_PSel_SPIm_Prdata1} {iopath_Sys_PSel_SPIm_Prdata2} {iopath_Sys_PSel_SPIm_Prdata3} {iopath_Sys_PSel_SPIm_Prdata4} {iopath_Sys_PSel_SPIm_Prdata5} {iopath_Sys_PSel_SPIm_Prdata6} {iopath_Sys_PSel_SPIm_Prdata7} {iopath_Sys_PSel_SPIm_Prdata8} {iopath_Sys_PSel_SPIm_Prdata9} {iopath_Sys_PSel_SPIm_Prdata10} {iopath_Sys_PSel_SPIm_Prdata11} {iopath_Sys_PSel_SPIm_Prdata12} {iopath_Sys_PSel_SPIm_Prdata13} {iopath_Sys_PSel_SPIm_Prdata14} {iopath_Sys_PSel_SPIm_Prdata15} {iopath_Sys_PSel_SPIm_Prdata16} {iopath_Sys_PSel_SPIm_Prdata17} {iopath_Sys_PSel_SPIm_Prdata18} {iopath_Sys_PSel_SPIm_Prdata19} {iopath_Sys_PSel_SPIm_Prdata20} {iopath_Sys_PSel_SPIm_Prdata21} {iopath_Sys_PSel_SPIm_Prdata22} {iopath_Sys_PSel_SPIm_Prdata23} {iopath_Sys_PSel_SPIm_Prdata24} {iopath_Sys_PSel_SPIm_Prdata25} {iopath_Sys_PSel_SPIm_Prdata26} {iopath_Sys_PSel_SPIm_Prdata27} {iopath_Sys_PSel_SPIm_Prdata28} {iopath_Sys_PSel_SPIm_Prdata29} {iopath_Sys_PSel_SPIm_Prdata30} {iopath_Sys_PSel_SPIm_Prdata31}" *)

wire [31:0] SPIm_Prdata;
wire [15:0] Device_ID;

// dummy assignents to mark combinational depenedencies
assign SPIm_Prdata = (Sys_PSel == 1'b1) ? 32'h00000000 : 32'h00000000;
assign SPIm_PReady = (Sys_PSel == 1'b1) ? 1'b0 : 1'b0;
assign SPIm_PSlvErr = (Sys_PSel == 1'b1) ? 1'b0 : 1'b0;
assign FB_PKfbOverflow = (FB_PKfbPush != 4'b0000) ? 1'b0 : 1'b0;

endmodule
