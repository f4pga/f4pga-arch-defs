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

  BIDIR_IBUF _TECHMAP_REPLACE_ (
  .P(P),
  .O(Q),
  .E(1'b1)
  );

endmodule

module outpad(output P, input A);

  BIDIR_OBUF _TECHMAP_REPLACE_ (
  .P(P),
  .I(A),
  .E(1'b1)
  );

endmodule

module ckpad(output Q, input P);

  // TODO: Map this to a cell that would have two modes: one for BIDIR and
  // one for CLOCK. For now just make it a BIDIR input.
  BIDIR_IBUF _TECHMAP_REPLACE_ (
  .P(P),
  .O(Q),
  .E(1'b1)
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

  wire TSL = I1;
  wire TAB = I0;

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
  wire TAB = I0;

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
    default: assign TA1 = I2;
  endcase endgenerate

  generate case(INIT[3:2])
    2'b00:   assign TA2 = 1'b0;
    2'b11:   assign TA2 = 1'b0;
    default: assign TA2 = I2;
  endcase endgenerate

  generate case(INIT[5:4])
    2'b00:   assign TB1 = 1'b0;
    2'b11:   assign TB1 = 1'b0;
    default: assign TB1 = I2;
  endcase endgenerate

  generate case(INIT[7:6])
    2'b00:   assign TB2 = 1'b0;
    2'b11:   assign TB2 = 1'b0;
    default: assign TB2 = I2;
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

  wire TSL = I2;
  wire BSL = I2;
  wire TAB = I1;
  wire BAB = I1;
  wire TBS = I0;

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
    default: assign TA1 = I3;
  endcase endgenerate

  generate case(INIT[ 3: 2])
    2'b00:   assign TA2 = 1'b0;
    2'b11:   assign TA2 = 1'b0;
    default: assign TA2 = I3;
  endcase endgenerate

  generate case(INIT[ 5: 4])
    2'b00:   assign TB1 = 1'b0;
    2'b11:   assign TB1 = 1'b0;
    default: assign TB1 = I3;
  endcase endgenerate

  generate case(INIT[ 7: 6])
    2'b00:   assign TB2 = 1'b0;
    2'b11:   assign TB2 = 1'b0;
    default: assign TB2 = I3;
  endcase endgenerate

  generate case(INIT[ 9: 8])
    2'b00:   assign BA1 = 1'b0;
    2'b11:   assign BA1 = 1'b0;
    default: assign BA1 = I3;
  endcase endgenerate

  generate case(INIT[11:10])
    2'b00:   assign BA2 = 1'b0;
    2'b11:   assign BA2 = 1'b0;
    default: assign BA2 = I3;
  endcase endgenerate

  generate case(INIT[13:12])
    2'b00:   assign BB1 = 1'b0;
    2'b11:   assign BB1 = 1'b0;
    default: assign BB1 = I3;
  endcase endgenerate

  generate case(INIT[15:14])
    2'b00:   assign BB2 = 1'b0;
    2'b11:   assign BB2 = 1'b0;
    default: assign BB2 = I3;
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
  .INIT (INIT)
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
