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

  parameter IO_PAD  = "";
  parameter IO_LOC  = "";
  parameter IO_TYPE = "";

  generate if (IO_TYPE == "SDIOMUX") begin

      SDIOMUX_CELL _TECHMAP_REPLACE_ (
      .I_PAD_$inp(P),
      .I_DAT(Q),
      .I_EN (1'b1),
      .O_PAD_$out(),
      .O_DAT(),
      .O_EN (1'b1)
      );

  end else begin

      BIDIR_CELL # (
      .ESEL     (1'b1),
      .OSEL     (1'b1),
      .FIXHOLD  (1'b0),
      .WPD      (1'b0),
      .DS       (1'b0)
      ) _TECHMAP_REPLACE_ (
      .I_PAD_$inp(P),
      .I_DAT(Q),
      .I_EN (1'b1),
      .O_PAD_$out(),
      .O_DAT(),
      .O_EN (1'b0)
      );

  end endgenerate

endmodule

module outpad(output P, input A);

  parameter IO_PAD  = "";
  parameter IO_LOC  = "";
  parameter IO_TYPE = "";

  generate if (IO_TYPE == "SDIOMUX") begin

      SDIOMUX_CELL _TECHMAP_REPLACE_ (
      .I_PAD_$inp(),
      .I_DAT(),
      .I_EN (1'b1),
      .O_PAD_$out(P),
      .O_DAT(A),
      .O_EN (1'b0)
      );

  end else begin

      BIDIR_CELL # (
      .ESEL     (1'b1),
      .OSEL     (1'b1),
      .FIXHOLD  (1'b0),
      .WPD      (1'b0),
      .DS       (1'b0)
      ) _TECHMAP_REPLACE_ (
      .I_PAD_$inp(),
      .I_DAT(),
      .I_EN (1'b0),
      .O_PAD_$out(P),
      .O_DAT(A),
      .O_EN (1'b1)
      );

  end endgenerate

endmodule

module bipad(input A, input EN, output Q, inout P);

  parameter IO_PAD  = "";
  parameter IO_LOC  = "";
  parameter IO_TYPE = "";

  generate if (IO_TYPE == "SDIOMUX") begin

      wire nEN;

      inv INV (
      .A(EN),
      .Q(nEN)
      );

      SDIOMUX_CELL SDIOMUX (
      .I_PAD_$inp(P),
      .I_DAT(Q),
      .I_EN (1'b1),
      .O_PAD_$out(P),
      .O_DAT(A),
      .O_EN (nEN)
      );

  end else begin

      BIDIR_CELL # (
      .ESEL     (1'b1),
      .OSEL     (1'b1),
      .FIXHOLD  (1'b0),
      .WPD      (1'b0),
      .DS       (1'b0)
      ) _TECHMAP_REPLACE_ (
      .I_PAD_$inp(P),
      .I_DAT(Q),
      .I_EN (1'b1),
      .O_PAD_$out(P),
      .O_DAT(A),
      .O_EN (EN)
      );

  end endgenerate

endmodule

module ckpad(output Q, input P);

  parameter IO_PAD  = "";
  parameter IO_LOC  = "";
  parameter IO_TYPE = "";

  // TODO: Map this to a cell that would have two modes: one for BIDIR and
  // one for CLOCK. For now just make it a BIDIR input.
  BIDIR_CELL # (
  .ESEL     (1'b1),
  .OSEL     (1'b1),
  .FIXHOLD  (1'b0),
  .WPD      (1'b0),
  .DS       (1'b0)
  ) _TECHMAP_REPLACE_ (
  .I_PAD_$inp(P),
  .I_DAT(Q),
  .I_EN (1'b1),
  .O_PAD_$out(),
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

  wire XSL = I0;
  wire XAB = I1;

  wire XA1 = INIT[0];
  wire XA2 = INIT[1];
  wire XB1 = INIT[2];
  wire XB2 = INIT[3];

  // T_FRAG to be packed either into T_FRAG or B_FRAG.
  T_FRAG # (
  .XAS1(1'b0),
  .XAS2(1'b0),
  .XBS1(1'b0),
  .XBS2(1'b0)
  )
  t_frag
  (
  .TBS(1'b1), // Always route to const1
  .XAB(XAB),
  .XSL(XSL),
  .XA1(XA1),
  .XA2(XA2),
  .XB1(XB1),
  .XB2(XB2),
  .XZ (O)
  );

endmodule


module LUT3 (
  output O,
  input  I0,
  input  I1,
  input  I2
);
  parameter [7:0] INIT = 0;

  wire XSL = I1;
  wire XAB = I2;

  // Two bit group [H,L]
  // H =0:  T[AB]S[12] = GND, H=1:   VCC
  // HL=00: T[AB][12]  = GND, HL=11: VCC, else I0

  wire XA1;
  wire XA2;
  wire XB1;
  wire XB2;

  generate case(INIT[1:0])
    2'b00:   assign XA1 = 1'b0;
    2'b11:   assign XA1 = 1'b0;
    default: assign XA1 = I0;
  endcase endgenerate

  generate case(INIT[3:2])
    2'b00:   assign XA2 = 1'b0;
    2'b11:   assign XA2 = 1'b0;
    default: assign XA2 = I0;
  endcase endgenerate

  generate case(INIT[5:4])
    2'b00:   assign XB1 = 1'b0;
    2'b11:   assign XB1 = 1'b0;
    default: assign XB1 = I0;
  endcase endgenerate

  generate case(INIT[7:6])
    2'b00:   assign XB2 = 1'b0;
    2'b11:   assign XB2 = 1'b0;
    default: assign XB2 = I0;
  endcase endgenerate

  localparam XAS1 = INIT[0];
  localparam XAS2 = INIT[2];
  localparam XBS1 = INIT[4];
  localparam XBS2 = INIT[6];

  // T_FRAG to be packed either into T_FRAG or B_FRAG.
  T_FRAG # (
  .XAS1(XAS1),
  .XAS2(XAS2),
  .XBS1(XBS1),
  .XBS2(XBS2)
  )
  t_frag
  (
  .TBS(1'b1), // Always route to const1
  .XAB(XAB),
  .XSL(XSL),
  .XA1(XA1),
  .XA2(XA2),
  .XB1(XB1),
  .XB2(XB2),
  .XZ (O)
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

  // Split a LUT4 into 2xLUT3 + F_FRAG
  wire t;
  wire b;

  LUT3 #(.INIT(INIT[7:0])) t_lut (
    .I0(I0),
    .I1(I1),
    .I2(I2),
    .O (t)
  );

  LUT3 #(.INIT(INIT[15:8])) b_lut (
    .I0(I0),
    .I1(I1),
    .I2(I2),
    .O (b)
  );

  // The F-Frag
  F_FRAG f_frag (
    .F1(t),
    .F2(b),
    .FS(I3),
    .FZ(O)
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

module dffp(
  output Q,
  input  D,
  input  CLK,
  input  PRE
);

  parameter [0:0] INIT = 1'b0;

  Q_FRAG # (
  .Z_QCKS (1'b1)
  )
  _TECHMAP_REPLACE_
  (
  .QCK(CLK),
  .QST(PRE),
  .QRT(1'b0),
  .QEN(1'b1),
  .QDI(D),
  .QDS(1'b1), // FIXME: Always select QDI as the FF's input
  .CZI(),
  .QZ (Q)
  );

endmodule

module dffpc(
  output Q,
  input  D,
  input  CLK,
  input  CLR,
  input  PRE
);

  parameter [0:0] INIT = 1'b0;

  Q_FRAG # (
  .Z_QCKS (1'b1)
  )
  _TECHMAP_REPLACE_
  (
  .QCK(CLK),
  .QST(PRE),
  .QRT(CLR),
  .QEN(1'b1),
  .QDI(D),
  .QDS(1'b1), // FIXME: Always select QDI as the FF's input
  .CZI(),
  .QZ (Q)
  );

endmodule

module dffe(
  output Q,
  input  D,
  input  CLK,
  input  EN
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
  .QEN(EN),
  .QDI(D),
  .QDS(1'b1), // FIXME: Always select QDI as the FF's input
  .CZI(),
  .QZ (Q)
  );

endmodule

module dffec(
  output Q,
  input  D,
  input  CLK,
  input  EN,
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
  .QEN(EN),
  .QDI(D),
  .QDS(1'b1), // FIXME: Always select QDI as the FF's input
  .CZI(),
  .QZ (Q)
  );

endmodule

module dffepc(
  output Q,
  input  D,
  input  CLK,
  input  EN,
  input  CLR,
  input  PRE
);

  parameter [0:0] INIT = 1'b0;

  Q_FRAG # (
  .Z_QCKS (1'b1)
  )
  _TECHMAP_REPLACE_
  (
  .QCK(CLK),
  .QST(PRE),
  .QRT(CLR),
  .QEN(EN),
  .QDI(D),
  .QDS(1'b1), // FIXME: Always select QDI as the FF's input
  .CZI(),
  .QZ (Q)
  );

endmodule

module dffsc(
  output Q,
  input  D,
  input  CLK,
  input  CLR,
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
  .Device_ID        (Device_ID      )
  );

  // TODO: The macro "qlal4s3b_cell_macro" has a bunch of non-routable signals
  // Figure out what they are responsible for and if there are any bits they
  // control.

endmodule

module qlal4s3_mult_32x32_cell (
    input [31:0] Amult,
    input [31:0] Bmult,
    input [1:0] Valid_mult,
    output [63:0] Cmult);

    MULT #() _TECHMAP_REPLACE_
    (
      .Amult(Amult),
      .Bmult(Bmult),
      .Valid_mult(Valid_mult),
      .Cmult(Cmult),
      .sel_mul_32x32(1'b1)
    );

endmodule /* qlal4s3_32x32_mult_cell */

module qlal4s3_mult_16x16_cell (
    input [15:0] Amult,
    input [15:0] Bmult,
    input [1:0] Valid_mult,
    output [31:0] Cmult);

    wire [31:0] Amult_int;
    wire [31:0] Bmult_int;
    wire [63:0] Cmult_int;

    assign Amult_int = {16'b0, Amult};
    assign Bmult_int = {16'b0, Bmult};
    assign Cmult = Cmult_int[15:0];

    MULT #() _TECHMAP_REPLACE_
    (
      .Amult(Amult_int),
      .Bmult(Bmult_int),
      .Valid_mult(Valid_mult),
      .Cmult(Cmult_int),
      .sel_mul_32x32(1'b0)
    );

endmodule /* qlal4s3_16x16_mult_cell */

module qlal4s3_mult_cell_macro(
    input [31:0] Amult,
    input [31:0] Bmult,
    input [1:0] Valid_mult,
    input sel_mul_32x32,
    output [63:0] Cmult);

    MULT #() _TECHMAP_REPLACE_
    (
      .Amult(Amult),
      .Bmult(Bmult),
      .Valid_mult(Valid_mult),
      .Cmult(Cmult),
      .sel_mul_32x32(sel_mul_32x32)
    );
endmodule

