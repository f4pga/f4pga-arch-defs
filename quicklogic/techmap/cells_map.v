// ============================================================================
// Constant sources

// Reduce logic_0 and logic_1 cells to 1'b0 and 1'b1. Const sources suitable
// for VPR will be added by Yosys during EBLIF write.
module logic_0(output a);
    assign a = 0;
endmodule

module logic_1(output a);
    assign a = 1;
endmodule


// ============================================================================
// IO and clock buffers

module inpad(output Q, input P);

  IOBUF # (
  .ESEL     (1'b1),
  .OSEL     (1'b1),
  .FIXHOLD  (1'b0),
  .WPD      (1'b0),
  .DS       (1'b0)
  ) _TECHMAP_REPLACE_ (
  .I_PAD(P),
  .I_DAT(Q),
  .I_EN (1'b1),
  .O_PAD(),
  .O_DAT(),
  .O_EN (1'b0)
  );

endmodule

module outpad(output P, input A);

  IOBUF # (
  .ESEL     (1'b1),
  .OSEL     (1'b1),
  .FIXHOLD  (1'b0),
  .WPD      (1'b0),
  .DS       (1'b0)
  ) _TECHMAP_REPLACE_ (
  .I_PAD(),
  .I_DAT(),
  .I_EN (1'b0),
  .O_PAD(P),
  .O_DAT(A),
  .O_EN (1'b1)
  );

endmodule

module ckpad(output Q, input P);

  // TODO: Map this to a cell that would have two modes: one for BIDIR and
  // one for CLOCK. For now just make it a BIDIR input.
  IOBUF # (
  .ESEL     (1'b1),
  .OSEL     (1'b1),
  .FIXHOLD  (1'b0),
  .WPD      (1'b0),
  .DS       (1'b0)
  ) _TECHMAP_REPLACE_ (
  .I_PAD(P),
  .I_DAT(Q),
  .I_EN (1'b1),
  .O_PAD(),
  .O_DAT(),
  .O_EN (1'b0)
  );

endmodule

// ============================================================================

module gclkbuff(input A, output Z);

  // TODO: Map this to a VPR global clock buffer once the global clocn network
  // is supported.
  assign Z = A;

endmodule

// ============================================================================
// basic logic elements

module inv (
  output Q,
  input A,
);

  // The F-Frag
  F_FRAG f_frag (
  .F1(1'b1),
  .F2(1'b0),
  .FS(A),
  .FZ(Q)
  );
endmodule

// ============================================================================
// LUTs

module LUT1 (
  output O,
  input  I0
);
  parameter [1:0] INIT = 0;

  // The F-Frag
  F_FRAG f_frag (
  .F1(INIT[0]),
  .F2(INIT[1]),
  .FS(I0),
  .FZ(O)
  );

endmodule


module LUT2 (
  output O,
  input  I0,
  input  I1
);
  parameter [3:0] INIT = 0;

  wire TSL = I0;
  wire TAB = I1;

  wire TA1 = INIT[0];
  wire TA2 = INIT[1];
  wire TB1 = INIT[2];
  wire TB2 = INIT[3];

  // The C-Frag as T-Frag
  C_FRAG # (
  .TAS1(1'b0),
  .TAS2(1'b0),
  .TBS1(1'b0),
  .TBS2(1'b0),
  .BAS1(1'b0),
  .BAS2(1'b0),
  .BBS1(1'b0),
  .BBS2(1'b0)
  )
  c_frag
  (
  .TBS(1'b0),
  .TAB(TAB),
  .TSL(TSL),
  .TA1(TA1),
  .TA2(TA2),
  .TB1(TB1),
  .TB2(TB2),
  .BAB(1'b0),
  .BSL(1'b0),
  .BA1(1'b0),
  .BA2(1'b0),
  .BB1(1'b0),
  .BB2(1'b0),
  .TZ (O),
  .CZ ()
  );

endmodule


module LUT3 (
  output O,
  input  I0,
  input  I1,
  input  I2
);
  parameter [7:0] INIT = 0;

  wire TSL = I1;
  wire TAB = I2;

  // Two bit group [H,L]
  // H =0:  T[AB]S[12] = GND, H=1:   VCC
  // HL=00: T[AB][12]  = GND, HL=11: VCC, else I0

  wire TA1;
  wire TA2;
  wire TB1;
  wire TB2;

  generate case(INIT[1:0])
    2'b00:   assign TA1 = 1'b0;
    2'b11:   assign TA1 = 1'b0;
    default: assign TA1 = I0;
  endcase endgenerate

  generate case(INIT[3:2])
    2'b00:   assign TA2 = 1'b0;
    2'b11:   assign TA2 = 1'b0;
    default: assign TA2 = I0;
  endcase endgenerate

  generate case(INIT[5:4])
    2'b00:   assign TB1 = 1'b0;
    2'b11:   assign TB1 = 1'b0;
    default: assign TB1 = I0;
  endcase endgenerate

  generate case(INIT[7:6])
    2'b00:   assign TB2 = 1'b0;
    2'b11:   assign TB2 = 1'b0;
    default: assign TB2 = I0;
  endcase endgenerate

  localparam TAS1 = INIT[0];
  localparam TAS2 = INIT[2];
  localparam TBS1 = INIT[4];
  localparam TBS2 = INIT[6];

  // The C-Frag as T-Frag
  C_FRAG # (
  .TAS1(TAS1),
  .TAS2(TAS2),
  .TBS1(TBS1),
  .TBS2(TBS2),
  .BAS1(1'b0),
  .BAS2(1'b0),
  .BBS1(1'b0),
  .BBS2(1'b0)
  )
  c_frag
  (
  .TBS(1'b0),
  .TAB(TAB),
  .TSL(TSL),
  .TA1(TA1),
  .TA2(TA2),
  .TB1(TB1),
  .TB2(TB2),
  .BAB(1'b0),
  .BSL(1'b0),
  .BA1(1'b0),
  .BA2(1'b0),
  .BB1(1'b0),
  .BB2(1'b0),
  .TZ (O),
  .CZ ()
  );

endmodule


module LUT4 (
  output O,
  input  I0,
  input  I1,
  input  I2,
  input  I3
);
  parameter [15:0] INIT = 0;

  wire TSL = I1;
  wire BSL = I1;
  wire TAB = I2;
  wire BAB = I2;
  wire TBS = I3;

  // Two bit group [H,L]
  // H =0:  [TB][AB]S[12] = GND, H=1:   VCC
  // HL=00: [TB][AB][12]  = GND, HL=11: VCC, else I0

  wire TA1;
  wire TA2;
  wire TB1;
  wire TB2;
  wire BA1;
  wire BA2;
  wire BB1;
  wire BB2;

  generate case(INIT[ 1: 0])
    2'b00:   assign TA1 = 1'b0;
    2'b11:   assign TA1 = 1'b0;
    default: assign TA1 = I0;
  endcase endgenerate

  generate case(INIT[ 3: 2])
    2'b00:   assign TA2 = 1'b0;
    2'b11:   assign TA2 = 1'b0;
    default: assign TA2 = I0;
  endcase endgenerate

  generate case(INIT[ 5: 4])
    2'b00:   assign TB1 = 1'b0;
    2'b11:   assign TB1 = 1'b0;
    default: assign TB1 = I0;
  endcase endgenerate

  generate case(INIT[ 7: 6])
    2'b00:   assign TB2 = 1'b0;
    2'b11:   assign TB2 = 1'b0;
    default: assign TB2 = I0;
  endcase endgenerate

  generate case(INIT[ 9: 8])
    2'b00:   assign BA1 = 1'b0;
    2'b11:   assign BA1 = 1'b0;
    default: assign BA1 = I0;
  endcase endgenerate

  generate case(INIT[11:10])
    2'b00:   assign BA2 = 1'b0;
    2'b11:   assign BA2 = 1'b0;
    default: assign BA2 = I0;
  endcase endgenerate

  generate case(INIT[13:12])
    2'b00:   assign BB1 = 1'b0;
    2'b11:   assign BB1 = 1'b0;
    default: assign BB1 = I0;
  endcase endgenerate

  generate case(INIT[15:14])
    2'b00:   assign BB2 = 1'b0;
    2'b11:   assign BB2 = 1'b0;
    default: assign BB2 = I0;
  endcase endgenerate

  localparam TAS1 = INIT[ 0];
  localparam TAS2 = INIT[ 2];
  localparam TBS1 = INIT[ 4];
  localparam TBS2 = INIT[ 6];
  localparam BAS1 = INIT[ 8];
  localparam BAS2 = INIT[10];
  localparam BBS1 = INIT[12];
  localparam BBS2 = INIT[14];

  // The C-Frag
  C_FRAG # (
  .TAS1(TAS1),
  .TAS2(TAS2),
  .TBS1(TBS1),
  .TBS2(TBS2),
  .BAS1(BAS1),
  .BAS2(BAS2),
  .BBS1(BBS1),
  .BBS2(BBS2)
  )
  c_frag
  (
  .TBS(TBS),
  .TAB(TAB),
  .TSL(TSL),
  .TA1(TA1),
  .TA2(TA2),
  .TB1(TB1),
  .TB2(TB2),
  .BAB(BAB),
  .BSL(BSL),
  .BA1(BA1),
  .BA2(BA2),
  .BB1(BB1),
  .BB2(BB2),
  .TZ (),
  .CZ (O)
  );

endmodule

// ============================================================================
// Flip-Flops

module dff(
  output Q,
  input  D,
  input  CLK
);

  parameter [0:0] INIT = 1'b0;

  Q_FRAG # (
  .Z_QCKS (1'b1)
  )
  _TECHMAP_REPLACE_
  (
  .QCK(CLK),
  .QST(1'b0),
  .QRT(1'b0),
  .QEN(1'b1),
  .QDI(D),
  .QDS(1'b1), // FIXME: Always select QDI as the FF's input
  .CZI(),
  .QZ (Q)
  );

endmodule

module dffc(
  output Q,
  input  D,
  input  CLK,
  input  CLR
);

  parameter [0:0] INIT = 1'b0;

  Q_FRAG # (
  .Z_QCKS (1'b1)
  )
  _TECHMAP_REPLACE_
  (
  .QCK(CLK),
  .QST(1'b0),
  .QRT(CLR),
  .QEN(1'b1),
  .QDI(D),
  .QDS(1'b1), // FIXME: Always select QDI as the FF's input
  .CZI(),
  .QZ (Q)
  );

endmodule
// ============================================================================
// The "qlal4s3b_cell_macro" macro

module qlal4s3b_cell_macro (
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
  input  [15:0] Device_ID,
  input  [13:0] FBIO_In_En,
  input  [13:0] FBIO_Out,
  input  [13:0] FBIO_Out_En,
  output [13:0] FBIO_In,
  inout  [13:0] SFBIO,
  input         Device_ID_6S, 
  input         Device_ID_4S, 
  input         SPIm_PWdata_26S, 
  input         SPIm_PWdata_24S,  
  input         SPIm_PWdata_14S, 
  input         SPIm_PWdata_11S, 
  input         SPIm_PWdata_0S, 
  input         SPIm_Paddr_8S, 
  input         SPIm_Paddr_6S, 
  input         FB_PKfbPush_1S, 
  input         FB_PKfbData_31S, 
  input         FB_PKfbData_21S,
  input         FB_PKfbData_19S,
  input         FB_PKfbData_9S,
  input         FB_PKfbData_6S,
  input         Sys_PKfb_ClkS,
  input         FB_BusyS,
  input         WB_CLKS
);

  ASSP #() _TECHMAP_REPLACE_
  (
  .WB_CLK           (WB_CLK         ),
  .WBs_ACK          (WBs_ACK        ),
  .WBs_RD_DAT       (WBs_RD_DAT     ),
  .WBs_BYTE_STB     (WBs_BYTE_STB   ),
  .WBs_CYC          (WBs_CYC        ),
  .WBs_WE           (WBs_WE         ),
  .WBs_RD           (WBs_RD         ),
  .WBs_STB          (WBs_STB        ),
  .WBs_ADR          (WBs_ADR        ),
  .SDMA_Req         (SDMA_Req       ),
  .SDMA_Sreq        (SDMA_Sreq      ),
  .SDMA_Done        (SDMA_Done      ),
  .SDMA_Active      (SDMA_Active    ),
  .FB_msg_out       (FB_msg_out     ),
  .FB_Int_Clr       (FB_Int_Clr     ),
  .FB_Start         (FB_Start       ),
  .FB_Busy          (FB_Busy        ),
  .WB_RST           (WB_RST         ),
  .Sys_PKfb_Rst     (Sys_PKfb_Rst   ),
  .Sys_Clk0         (Sys_Clk0       ),
  .Sys_Clk0_Rst     (Sys_Clk0_Rst   ),
  .Sys_Clk1         (Sys_Clk1       ),
  .Sys_Clk1_Rst     (Sys_Clk1_Rst   ),
  .Sys_Pclk         (Sys_Pclk       ),
  .Sys_Pclk_Rst     (Sys_Pclk_Rst   ),
  .Sys_PKfb_Clk     (Sys_PKfb_Clk   ),
  .FB_PKfbData      (FB_PKfbData    ),
  .WBs_WR_DAT       (WBs_WR_DAT     ),
  .FB_PKfbPush      (FB_PKfbPush    ),
  .FB_PKfbSOF       (FB_PKfbSOF     ),
  .FB_PKfbEOF       (FB_PKfbEOF     ),
  .Sensor_Int       (Sensor_Int     ),
  .FB_PKfbOverflow  (FB_PKfbOverflow),
  .TimeStamp        (TimeStamp      ),
  .Sys_PSel         (Sys_PSel       ),
  .SPIm_Paddr       (SPIm_Paddr     ),
  .SPIm_PEnable     (SPIm_PEnable   ),
  .SPIm_PWrite      (SPIm_PWrite    ),
  .SPIm_PWdata      (SPIm_PWdata    ),
  .SPIm_PReady      (SPIm_PReady    ),
  .SPIm_PSlvErr     (SPIm_PSlvErr   ),
  .SPIm_Prdata      (SPIm_Prdata    ),
  .Device_ID        (Device_ID      ),
  .FBIO_In_En       (FBIO_In_En     ),
  .FBIO_Out         (FBIO_Out       ),
  .FBIO_Out_En      (FBIO_Out_En    ),
  .FBIO_In          (FBIO_In        )
  );

  // TODO: SFBIO signals are inout and not actually present in the physical
  // ASSP cell. Figure out how to handle that.

  // TODO: The macro "qlal4s3b_cell_macro" has a bunch of non-routable signals
  // Figure out what they are responsible for and if there are any bits they
  // control.

endmodule
