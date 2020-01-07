module LUT1 (
  output O,
  input  I0
);
  parameter [1:0] INIT = 0;

  // The F-frag mux
  MUX mux_f (
  .S (I0),      // FS
  .I0(INIT[0]), // F1
  .I1(INIT[1]), // F2
  .O (O),       // FZ
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

  wire ta, tb, tab;

  // Muxes for T-frag
  MUX mux_ta (.I0(TA1),.I1(TA2),.S(TSL),.O(ta));
  MUX mux_tb (.I0(TB1),.I1(TB2),.S(TSL),.O(tb));
  MUX mux_tab(.I0(ta), .I1(tb), .S(TAB),.O(tab));

  assign O = tab;

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

  wire _TA1;
  wire _TA2;
  wire _TB1;
  wire _TB2;

  generate case(INIT[1:0])
    2'b00:   assign _TA1 = 1'b0;
    2'b11:   assign _TA1 = 1'b0;
    default: assign _TA1 = I0;
  endcase endgenerate

  generate case(INIT[3:2])
    2'b00:   assign _TA2 = 1'b0;
    2'b11:   assign _TA2 = 1'b0;
    default: assign _TA2 = I0;
  endcase endgenerate

  generate case(INIT[5:4])
    2'b00:   assign _TB1 = 1'b0;
    2'b11:   assign _TB1 = 1'b0;
    default: assign _TB1 = I0;
  endcase endgenerate

  generate case(INIT[7:6])
    2'b00:   assign _TB2 = 1'b0;
    2'b11:   assign _TB2 = 1'b0;
    default: assign _TB2 = I0;
  endcase endgenerate

  localparam TAS1 = INIT[0];
  localparam TAS2 = INIT[2];
  localparam TBS1 = INIT[4];
  localparam TBS2 = INIT[6];

  // Insert inverters or not
  wire TA1, TA2;
  wire TB1, TB2;

  generate if (TAS1 == 1)
    NOT inv_tas1 (.I(_TA1), .O(TA1));
  else
    assign TA1 = _TA1;
  endgenerate

  generate if (TAS2 == 1)
    NOT inv_tas2 (.I(_TA2), .O(TA2));
  else
    assign TA2 = _TA2;
  endgenerate

  generate if (TBS1 == 1)
    NOT inv_tbs1 (.I(_TB1), .O(TB1));
  else
    assign TB1 = _TB1;
  endgenerate

  generate if (TBS2 == 1)
    NOT inv_tbs2 (.I(_TB2), .O(TB2));
  else
    assign TB2 = _TB2;
  endgenerate

  // Muxes for T-frag
  wire ta, tb, tab;

  MUX mux_ta (.I0(TA1),.I1(TA2),.S(TSL),.O(ta));
  MUX mux_tb (.I0(TB1),.I1(TB2),.S(TSL),.O(tb));
  MUX mux_tab(.I0(ta), .I1(tb), .S(TAB),.O(tab));

  assign O = tab;

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

  wire _TA1;
  wire _TA2;
  wire _TB1;
  wire _TB2;
  wire _BA1;
  wire _BA2;
  wire _BB1;
  wire _BB2;

  generate case(INIT[ 1: 0])
    2'b00:   assign _TA1 = 1'b0;
    2'b11:   assign _TA1 = 1'b0;
    default: assign _TA1 = I0;
  endcase endgenerate

  generate case(INIT[ 3: 2])
    2'b00:   assign _TA2 = 1'b0;
    2'b11:   assign _TA2 = 1'b0;
    default: assign _TA2 = I0;
  endcase endgenerate

  generate case(INIT[ 5: 4])
    2'b00:   assign _TB1 = 1'b0;
    2'b11:   assign _TB1 = 1'b0;
    default: assign _TB1 = I0;
  endcase endgenerate

  generate case(INIT[ 7: 6])
    2'b00:   assign _TB2 = 1'b0;
    2'b11:   assign _TB2 = 1'b0;
    default: assign _TB2 = I0;
  endcase endgenerate

  generate case(INIT[ 9: 8])
    2'b00:   assign _BA1 = 1'b0;
    2'b11:   assign _BA1 = 1'b0;
    default: assign _BA1 = I0;
  endcase endgenerate

  generate case(INIT[11:10])
    2'b00:   assign _BA2 = 1'b0;
    2'b11:   assign _BA2 = 1'b0;
    default: assign _BA2 = I0;
  endcase endgenerate

  generate case(INIT[13:12])
    2'b00:   assign _BB1 = 1'b0;
    2'b11:   assign _BB1 = 1'b0;
    default: assign _BB1 = I0;
  endcase endgenerate

  generate case(INIT[15:14])
    2'b00:   assign _BB2 = 1'b0;
    2'b11:   assign _BB2 = 1'b0;
    default: assign _BB2 = I0;
  endcase endgenerate

  localparam TAS1 = INIT[ 0];
  localparam TAS2 = INIT[ 2];
  localparam TBS1 = INIT[ 4];
  localparam TBS2 = INIT[ 6];
  localparam BAS1 = INIT[ 8];
  localparam BAS2 = INIT[10];
  localparam BBS1 = INIT[12];
  localparam BBS2 = INIT[14];

  // Insert inverters or not
  wire TA1, TA2;
  wire TB1, TB2;
  wire BA1, BA2;
  wire BB1, BB2;

  generate if (TAS1 == 1)
    NOT inv_tas1 (.I(_TA1), .O(TA1));
  else
    assign TA1 = _TA1;
  endgenerate

  generate if (TAS2 == 1)
    NOT inv_tas2 (.I(_TA2), .O(TA2));
  else
    assign TA2 = _TA2;
  endgenerate

  generate if (TBS1 == 1)
    NOT inv_tbs1 (.I(_TB1), .O(TB1));
  else
    assign TB1 = _TB1;
  endgenerate

  generate if (TBS2 == 1)
    NOT inv_tbs2 (.I(_TB2), .O(TB2));
  else
    assign TB2 = _TB2;
  endgenerate

  generate if (BAS1 == 1)
    NOT inv_bas1 (.I(_BA1), .O(BA1));
  else
    assign BA1 = _BA1;
  endgenerate

  generate if (BAS2 == 1)
    NOT inv_bas2 (.I(_BA2), .O(BA2));
  else
    assign BA2 = _BA2;
  endgenerate

  generate if (BBS1 == 1)
    NOT inv_bbs1 (.I(_BB1), .O(BB1));
  else
    assign BB1 = _BB1;
  endgenerate

  generate if (BBS2 == 1)
    NOT inv_bbs2 (.I(_BB2), .O(BB2));
  else
    assign BB2 = _BB2;
  endgenerate

  // Muxes for C-frag
  wire ta, tb, tab;
  wire ba, bb, bab;
  wire tbs;

  MUX mux_ta (.I0(TA1),.I1(TA2),.S(TSL),.O(ta));
  MUX mux_tb (.I0(TB1),.I1(TB2),.S(TSL),.O(tb));
  MUX mux_tab(.I0(ta), .I1(tb), .S(TAB),.O(tab));

  MUX mux_ba (.I0(BA1),.I1(BA2),.S(BSL),.O(ba));
  MUX mux_bb (.I0(BB1),.I1(BB2),.S(BSL),.O(bb));
  MUX mux_bab(.I0(ba), .I1(bb), .S(BAB),.O(bab));

  MUX mux_tbs(.I0(tab),.I1(bab),.S(TBS),.O(tbs));

  assign O = tbs;

endmodule
