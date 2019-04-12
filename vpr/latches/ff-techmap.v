// Anlogic
module \$_DFF_N_     (input D, C,       output Q); AL_MAP_SEQ #(.DFFMODE("FF"), .REGSET(1'bx), .SRMUX("SR"),  .SRMODE("SYNC")) _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(~C), .ce(1'b1), .sr(1'b0)); endmodule
module \$_DFF_P_     (input D, C,       output Q); AL_MAP_SEQ #(.DFFMODE("FF"), .REGSET(1'bx), .SRMUX("SR"),  .SRMODE("SYNC")) _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(C),  .ce(1'b1), .sr(1'b0)); endmodule
module \$_DFFE_NN_   (input D, C, E,    output Q); AL_MAP_SEQ #(.DFFMODE("FF"), .REGSET(1'bx), .SRMUX("SR"),  .SRMODE("SYNC")) _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(~C), .ce(E),    .sr(1'b0)); endmodule
module \$_DFFE_NP_   (input D, C, E,    output Q); AL_MAP_SEQ #(.DFFMODE("FF"), .REGSET(1'bx), .SRMUX("SR"),  .SRMODE("SYNC")) _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(~C), .ce(E),    .sr(1'b0)); endmodule
module \$_DFFE_PN_   (input D, C, E,    output Q); AL_MAP_SEQ #(.DFFMODE("FF"), .REGSET(1'bx), .SRMUX("SR"),  .SRMODE("SYNC")) _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(C),  .ce(E),    .sr(1'b0)); endmodule
module \$_DFFE_PP_   (input D, C, E,    output Q); AL_MAP_SEQ #(.DFFMODE("FF"), .REGSET(1'bx), .SRMUX("SR"),  .SRMODE("SYNC")) _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(C),  .ce(E),    .sr(1'b0)); endmodule
module \$_DFF_NN0_   (input D, C,    R, output Q); AL_MAP_SEQ #(.DFFMODE("FF"), .REGSET(1'b0), .SRMUX("INV"), .SRMODE("SYNC")) _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(~C), .ce(1'b1), .sr(R)   ); endmodule
module \$_DFF_NN1_   (input D, C,    R, output Q); AL_MAP_SEQ #(.DFFMODE("FF"), .REGSET(1'b1), .SRMUX("INV"), .SRMODE("SYNC")) _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(~C), .ce(1'b1), .sr(R)   ); endmodule
module \$_DFF_NP0_   (input D, C,    R, output Q); AL_MAP_SEQ #(.DFFMODE("FF"), .REGSET(1'b0), .SRMUX("SR"),  .SRMODE("SYNC")) _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(~C), .ce(1'b1), .sr(R)   ); endmodule
module \$_DFF_NP1_   (input D, C,    R, output Q); AL_MAP_SEQ #(.DFFMODE("FF"), .REGSET(1'b1), .SRMUX("SR"),  .SRMODE("SYNC")) _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(~C), .ce(1'b1), .sr(R)   ); endmodule
module \$_DFF_PN0_   (input D, C,    R, output Q); AL_MAP_SEQ #(.DFFMODE("FF"), .REGSET(1'b0), .SRMUX("INV"), .SRMODE("SYNC")) _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(C) , .ce(1'b1), .sr(R)   ); endmodule
module \$_DFF_PN1_   (input D, C,    R, output Q); AL_MAP_SEQ #(.DFFMODE("FF"), .REGSET(1'b1), .SRMUX("INV"), .SRMODE("SYNC")) _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(C),  .ce(1'b1), .sr(R)   ); endmodule
module \$_DFF_PP0_   (input D, C,    R, output Q); AL_MAP_SEQ #(.DFFMODE("FF"), .REGSET(1'b0), .SRMUX("SR"),  .SRMODE("SYNC")) _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(C),  .ce(1'b1), .sr(R)   ); endmodule
module \$_DFF_PP1_   (input D, C,    R, output Q); AL_MAP_SEQ #(.DFFMODE("FF"), .REGSET(1'b1), .SRMUX("SR"), . SRMODE("SYNC")) _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(C),  .ce(1'b1), .sr(R)   ); endmodule
// Xilinx Coolrunner
module \$_DLATCH_P_  (input D,    E,    output Q); LDCP   _TECHMAP_REPLACE_ (.D(D), .G(E), .Q(Q), .PRE(1'b0), .CLR(1'b0)); endmodule
module \$_DLATCH_N_  (input D,    E,    output Q); LDCP_N _TECHMAP_REPLACE_ (.D(D), .G(E), .Q(Q), .PRE(1'b0), .CLR(1'b0)); endmodule
// Lattice ECP5
module \$_DFF_N_     (input D, C,       output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("1"),   .CLKMUX("INV"), .LSRMUX("LSR"), .REGSET("RESET"))                          _TECHMAP_REPLACE_ (.CLK(C),         .LSR(1'b0), .DI(D), .Q(Q)); endmodule
module \$_DFF_P_     (input D, C,       output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("1"),   .CLKMUX("CLK"), .LSRMUX("LSR"), .REGSET("RESET"))                          _TECHMAP_REPLACE_ (.CLK(C),         .LSR(1'b0), .DI(D), .Q(Q)); endmodule
module \$_DFFE_NN_   (input D, C, E,    output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("INV"), .CLKMUX("INV"), .LSRMUX("LSR"), .REGSET("RESET"))                          _TECHMAP_REPLACE_ (.CLK(C), .CE(E), .LSR(1'b0), .DI(D), .Q(Q)); endmodule
module \$_DFFE_PN_   (input D, C, E,    output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("INV"), .CLKMUX("CLK"), .LSRMUX("LSR"), .REGSET("RESET"))                          _TECHMAP_REPLACE_ (.CLK(C), .CE(E), .LSR(1'b0), .DI(D), .Q(Q)); endmodule
module \$_DFFE_NP_   (input D, C, E,    output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("CE"),  .CLKMUX("INV"), .LSRMUX("LSR"), .REGSET("RESET"))                          _TECHMAP_REPLACE_ (.CLK(C), .CE(E), .LSR(1'b0), .DI(D), .Q(Q)); endmodule
module \$_DFFE_PP_   (input D, C, E,    output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("CE"),  .CLKMUX("CLK"), .LSRMUX("LSR"), .REGSET("RESET"))                          _TECHMAP_REPLACE_ (.CLK(C), .CE(E), .LSR(1'b0), .DI(D), .Q(Q)); endmodule
module \$_DFF_NN0_   (input D, C,    R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("1"),   .CLKMUX("INV"), .LSRMUX("LSR"), .REGSET("RESET"), .SRMODE("ASYNC"))        _TECHMAP_REPLACE_ (.CLK(C),         .LSR(!R),   .DI(D), .Q(Q)); endmodule
module \$_DFF_NN1_   (input D, C,    R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("1"),   .CLKMUX("INV"), .LSRMUX("LSR"), .REGSET("SET"),   .SRMODE("ASYNC"))        _TECHMAP_REPLACE_ (.CLK(C),         .LSR(!R),   .DI(D), .Q(Q)); endmodule
module \$_DFF_PN0_   (input D, C,    R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("1"),   .CLKMUX("CLK"), .LSRMUX("LSR"), .REGSET("RESET"), .SRMODE("ASYNC"))        _TECHMAP_REPLACE_ (.CLK(C),         .LSR(!R),   .DI(D), .Q(Q)); endmodule
module \$_DFF_PN1_   (input D, C,    R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("1"),   .CLKMUX("CLK"), .LSRMUX("LSR"), .REGSET("SET"),   .SRMODE("ASYNC"))        _TECHMAP_REPLACE_ (.CLK(C),         .LSR(!R),   .DI(D), .Q(Q)); endmodule
module \$_DFF_NP0_   (input D, C,    R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("1"),   .CLKMUX("INV"), .LSRMUX("LSR"), .REGSET("RESET"), .SRMODE("ASYNC"))        _TECHMAP_REPLACE_ (.CLK(C),         .LSR(R),    .DI(D), .Q(Q)); endmodule
module \$_DFF_NP1_   (input D, C,    R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("1"),   .CLKMUX("INV"), .LSRMUX("LSR"), .REGSET("SET"),   .SRMODE("ASYNC"))        _TECHMAP_REPLACE_ (.CLK(C),         .LSR(R),    .DI(D), .Q(Q)); endmodule
module \$_DFF_PP0_   (input D, C,    R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("1"),   .CLKMUX("CLK"), .LSRMUX("LSR"), .REGSET("RESET"), .SRMODE("ASYNC"))        _TECHMAP_REPLACE_ (.CLK(C),         .LSR(R),    .DI(D), .Q(Q)); endmodule
module \$_DFF_PP1_   (input D, C,    R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("1"),   .CLKMUX("CLK"), .LSRMUX("LSR"), .REGSET("SET"),   .SRMODE("ASYNC"))        _TECHMAP_REPLACE_ (.CLK(C),         .LSR(R),    .DI(D), .Q(Q)); endmodule
module \$__DFFS_NN0_ (input D, C,    R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("1"),   .CLKMUX("INV"), .LSRMUX("LSR"), .REGSET("RESET"), .SRMODE("LSR_OVER_CE"))  _TECHMAP_REPLACE_ (.CLK(C),         .LSR(!R),   .DI(D), .Q(Q)); endmodule
module \$__DFFS_NN1_ (input D, C,    R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("1"),   .CLKMUX("INV"), .LSRMUX("LSR"), .REGSET("SET"),   .SRMODE("LSR_OVER_CE"))  _TECHMAP_REPLACE_ (.CLK(C),         .LSR(!R),   .DI(D), .Q(Q)); endmodule
module \$__DFFS_PN0_ (input D, C,    R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("1"),   .CLKMUX("CLK"), .LSRMUX("LSR"), .REGSET("RESET"), .SRMODE("LSR_OVER_CE"))  _TECHMAP_REPLACE_ (.CLK(C),         .LSR(!R),   .DI(D), .Q(Q)); endmodule
module \$__DFFS_PN1_ (input D, C,    R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("1"),   .CLKMUX("CLK"), .LSRMUX("LSR"), .REGSET("SET"),   .SRMODE("LSR_OVER_CE"))  _TECHMAP_REPLACE_ (.CLK(C),         .LSR(!R),   .DI(D), .Q(Q)); endmodule
module \$__DFFS_NP0_ (input D, C,    R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("1"),   .CLKMUX("INV"), .LSRMUX("LSR"), .REGSET("RESET"), .SRMODE("LSR_OVER_CE"))  _TECHMAP_REPLACE_ (.CLK(C),         .LSR(R),    .DI(D), .Q(Q)); endmodule
module \$__DFFS_NP1_ (input D, C,    R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("1"),   .CLKMUX("INV"), .LSRMUX("LSR"), .REGSET("SET"),   .SRMODE("LSR_OVER_CE"))  _TECHMAP_REPLACE_ (.CLK(C),         .LSR(R),    .DI(D), .Q(Q)); endmodule
module \$__DFFS_PP0_ (input D, C,    R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("1"),   .CLKMUX("CLK"), .LSRMUX("LSR"), .REGSET("RESET"), .SRMODE("LSR_OVER_CE"))  _TECHMAP_REPLACE_ (.CLK(C),         .LSR(R),    .DI(D), .Q(Q)); endmodule
module \$__DFFS_PP1_ (input D, C,    R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("1"),   .CLKMUX("CLK"), .LSRMUX("LSR"), .REGSET("SET"),   .SRMODE("LSR_OVER_CE"))  _TECHMAP_REPLACE_ (.CLK(C),         .LSR(R),    .DI(D), .Q(Q)); endmodule
module \$__DFFE_NN0  (input D, C, E, R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("CE"),  .CLKMUX("INV"), .LSRMUX("LSR"), .REGSET("RESET"), .SRMODE("ASYNC"))        _TECHMAP_REPLACE_ (.CLK(C), .CE(E), .LSR(!R),   .DI(D), .Q(Q)); endmodule
module \$__DFFE_NN1  (input D, C, E, R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("CE"),  .CLKMUX("INV"), .LSRMUX("LSR"), .REGSET("SET"),   .SRMODE("ASYNC"))        _TECHMAP_REPLACE_ (.CLK(C), .CE(E), .LSR(!R),   .DI(D), .Q(Q)); endmodule
module \$__DFFE_PN0  (input D, C, E, R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("CE"),  .CLKMUX("CLK"), .LSRMUX("LSR"), .REGSET("RESET"), .SRMODE("ASYNC"))        _TECHMAP_REPLACE_ (.CLK(C), .CE(E), .LSR(!R),   .DI(D), .Q(Q)); endmodule
module \$__DFFE_PN1  (input D, C, E, R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("CE"),  .CLKMUX("CLK"), .LSRMUX("LSR"), .REGSET("SET"),   .SRMODE("ASYNC"))        _TECHMAP_REPLACE_ (.CLK(C), .CE(E), .LSR(!R),   .DI(D), .Q(Q)); endmodule
module \$__DFFE_NP0  (input D, C, E, R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("CE"),  .CLKMUX("INV"), .LSRMUX("LSR"), .REGSET("RESET"), .SRMODE("ASYNC"))        _TECHMAP_REPLACE_ (.CLK(C), .CE(E), .LSR(R),    .DI(D), .Q(Q)); endmodule
module \$__DFFE_NP1  (input D, C, E, R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("CE"),  .CLKMUX("INV"), .LSRMUX("LSR"), .REGSET("SET"),   .SRMODE("ASYNC"))        _TECHMAP_REPLACE_ (.CLK(C), .CE(E), .LSR(R),    .DI(D), .Q(Q)); endmodule
module \$__DFFE_PP0  (input D, C, E, R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("CE"),  .CLKMUX("CLK"), .LSRMUX("LSR"), .REGSET("RESET"), .SRMODE("ASYNC"))        _TECHMAP_REPLACE_ (.CLK(C), .CE(E), .LSR(R),    .DI(D), .Q(Q)); endmodule
module \$__DFFE_PP1  (input D, C, E, R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("CE"),  .CLKMUX("CLK"), .LSRMUX("LSR"), .REGSET("SET"),   .SRMODE("ASYNC"))        _TECHMAP_REPLACE_ (.CLK(C), .CE(E), .LSR(R),    .DI(D), .Q(Q)); endmodule
module \$__DFFSE_NN0 (input D, C, E, R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("CE"),  .CLKMUX("INV"), .LSRMUX("LSR"), .REGSET("RESET"), .SRMODE("LSR_OVER_CE"))  _TECHMAP_REPLACE_ (.CLK(C), .CE(E), .LSR(!R),   .DI(D), .Q(Q)); endmodule
module \$__DFFSE_NN1 (input D, C, E, R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("CE"),  .CLKMUX("INV"), .LSRMUX("LSR"), .REGSET("SET"),   .SRMODE("LSR_OVER_CE"))  _TECHMAP_REPLACE_ (.CLK(C), .CE(E), .LSR(!R),   .DI(D), .Q(Q)); endmodule
module \$__DFFSE_PN0 (input D, C, E, R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("CE"),  .CLKMUX("CLK"), .LSRMUX("LSR"), .REGSET("RESET"), .SRMODE("LSR_OVER_CE"))  _TECHMAP_REPLACE_ (.CLK(C), .CE(E), .LSR(!R),   .DI(D), .Q(Q)); endmodule
module \$__DFFSE_PN1 (input D, C, E, R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("CE"),  .CLKMUX("CLK"), .LSRMUX("LSR"), .REGSET("SET"),   .SRMODE("LSR_OVER_CE"))  _TECHMAP_REPLACE_ (.CLK(C), .CE(E), .LSR(!R),   .DI(D), .Q(Q)); endmodule
module \$__DFFSE_NP0 (input D, C, E, R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("CE"),  .CLKMUX("INV"), .LSRMUX("LSR"), .REGSET("RESET"), .SRMODE("LSR_OVER_CE"))  _TECHMAP_REPLACE_ (.CLK(C), .CE(E), .LSR(R),    .DI(D), .Q(Q)); endmodule
module \$__DFFSE_NP1 (input D, C, E, R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("CE"),  .CLKMUX("INV"), .LSRMUX("LSR"), .REGSET("SET"),   .SRMODE("LSR_OVER_CE"))  _TECHMAP_REPLACE_ (.CLK(C), .CE(E), .LSR(R),    .DI(D), .Q(Q)); endmodule
module \$__DFFSE_PP0 (input D, C, E, R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("CE"),  .CLKMUX("CLK"), .LSRMUX("LSR"), .REGSET("RESET"), .SRMODE("LSR_OVER_CE"))  _TECHMAP_REPLACE_ (.CLK(C), .CE(E), .LSR(R),    .DI(D), .Q(Q)); endmodule
module \$__DFFSE_PP1 (input D, C, E, R, output Q); TRELLIS_FF #(.GSR("DISABLED"), .CEMUX("CE"),  .CLKMUX("CLK"), .LSRMUX("LSR"), .REGSET("SET"),   .SRMODE("LSR_OVER_CE"))  _TECHMAP_REPLACE_ (.CLK(C), .CE(E), .LSR(R),    .DI(D), .Q(Q)); endmodule
// Gowin
module \$_DFF_N_     (input D, C,       output Q); DFFN _TECHMAP_REPLACE_ (.D(D), .Q(Q), .CLK(C)); endmodule
module \$_DFF_P_     (input D, C,       output Q); DFF  _TECHMAP_REPLACE_ (.D(D), .Q(Q), .CLK(C)); endmodule
// Greenpack4
module \$_DLATCH_P_  (input D,    E,    output Q); GP_DLATCH _TECHMAP_REPLACE_ (.D(D), .nCLK(!E), .Q(Q)); endmodule
module \$_DLATCH_N_  (input D,    E,    output Q); GP_DLATCH _TECHMAP_REPLACE_ (.D(D), .nCLK(E),  .Q(Q)); endmodule
// Lattice iCE40
module \$_DFF_N_     (input D, C,       output Q); SB_DFFN             _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C)                        ); endmodule
module \$_DFF_P_     (input D, C,       output Q); SB_DFF              _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C)                        ); endmodule
module \$_DFFE_NN_   (input D, C, E,    output Q); SB_DFFNE            _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .E(!E)                ); endmodule
module \$_DFFE_PN_   (input D, C, E,    output Q); SB_DFFE             _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .E(!E)                ); endmodule
module \$_DFFE_NP_   (input D, C, E,    output Q); SB_DFFNE            _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .E(E)                 ); endmodule
module \$_DFFE_PP_   (input D, C, E,    output Q); SB_DFFE             _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .E(E)                 ); endmodule
module \$_DFF_NN0_   (input D, C,    R, output Q); SB_DFFNR            _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C),        .R(!R)         ); endmodule
module \$_DFF_NN1_   (input D, C,    R, output Q); SB_DFFNS            _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C),                 .S(!R)); endmodule
module \$_DFF_PN0_   (input D, C,    R, output Q); SB_DFFR             _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C),        .R(!R)         ); endmodule
module \$_DFF_PN1_   (input D, C,    R, output Q); SB_DFFS             _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C),                 .S(!R)); endmodule
module \$_DFF_NP0_   (input D, C,    R, output Q); SB_DFFNR            _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C),        .R(R)          ); endmodule
module \$_DFF_NP1_   (input D, C,    R, output Q); SB_DFFNS            _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C),                 .S(R) ); endmodule
module \$_DFF_PP0_   (input D, C,    R, output Q); SB_DFFR             _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C),        .R(R)          ); endmodule
module \$_DFF_PP1_   (input D, C,    R, output Q); SB_DFFS             _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C),                 .S(R) ); endmodule
module \$__DFFE_NN0  (input D, C, E, R, output Q); SB_DFFNER           _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .E(E), .R(!R)         ); endmodule
module \$__DFFE_NN1  (input D, C, E, R, output Q); SB_DFFNES           _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .E(E),          .S(!R)); endmodule
module \$__DFFE_PN0  (input D, C, E, R, output Q); SB_DFFER            _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .E(E), .R(!R)         ); endmodule
module \$__DFFE_PN1  (input D, C, E, R, output Q); SB_DFFES            _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .E(E),          .S(!R)); endmodule
module \$__DFFE_NP0  (input D, C, E, R, output Q); SB_DFFNER           _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .E(E), .R(R)          ); endmodule
module \$__DFFE_NP1  (input D, C, E, R, output Q); SB_DFFNES           _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .E(E),          .S(R) ); endmodule
module \$__DFFE_PP0  (input D, C, E, R, output Q); SB_DFFER            _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .E(E), .R(R)          ); endmodule
module \$__DFFE_PP1  (input D, C, E, R, output Q); SB_DFFES            _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .E(E),          .S(R) ); endmodule
// Intel MAX10
module \$_DFF_N_     (input D, C,       output Q); parameter WYSIWYG="TRUE"; parameter power_up=1'bx;                 dffeas #(.is_wysiwyg(WYSIWYG), .power_up(power_up))   _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(C), .clrn(1'b1), .prn(1'b1), .ena(1'b1), .asdata(1'b0), .aload(1'b0), .sclr(1'b0), .sload(1'b0)); endmodule
module \$_DFF_P_     (input D, C,       output Q); parameter WYSIWYG="TRUE"; parameter power_up=1'bx;                 dffeas #(.is_wysiwyg(WYSIWYG), .power_up(power_up))   _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(C), .clrn(1'b1), .prn(1'b1), .ena(1'b1), .asdata(1'b0), .aload(1'b0), .sclr(1'b0), .sload(1'b0)); endmodule
module \$_DFF_PN0_   (input D, C,    R, output Q); parameter WYSIWYG="TRUE"; parameter power_up=1'bx;                 dffeas #(.is_wysiwyg(WYSIWYG), .power_up("power_up")) _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(C), .clrn(R),    .prn(1'b1), .ena(1'b1), .asdata(1'b0), .aload(1'b0), .sclr(1'b0), .sload(1'b0)); endmodule
module \$_DFF_PP0_   (input D, C,    R, output Q); parameter WYSIWYG="TRUE"; parameter power_up=1'bx; wire R_i = ~ R; dffeas #(.is_wysiwyg(WYSIWYG), .power_up(power_up))   _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(C), .clrn(R_i),  .prn(1'b1), .ena(1'b1), .asdata(1'b0), .aload(1'b0), .sclr(1'b0), .sload(1'b0)); endmodule
module \$__DFFE_PP0  (input D, C, E, R, output Q); parameter WYSIWYG="TRUE"; parameter power_up=1'bx; wire E_i = ~ E; dffeas #(.is_wysiwyg(WYSIWYG), .power_up(power_up))   _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(C), .clrn(R),    .prn(1'b1), .ena(1'b1), .asdata(1'b0), .aload(1'b0), .sclr(E_i),  .sload(1'b0)); endmodule
// Intel Cyclone 10
module \$_DFF_N_     (input D, C,       output Q); parameter WYSIWYG="TRUE"; parameter power_up=1'bx;                 dffeas #(.is_wysiwyg(WYSIWYG), .power_up(power_up))   _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(C), .clrn(1'b1), .prn(1'b1), .ena(1'b1), .asdata(1'b0), .aload(1'b0), .sclr(1'b0), .sload(1'b0)); endmodule
module \$_DFF_P_     (input D, C,       output Q); parameter WYSIWYG="TRUE"; parameter power_up=1'bx;                 dffeas #(.is_wysiwyg(WYSIWYG), .power_up(power_up))   _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(C), .clrn(1'b1), .prn(1'b1), .ena(1'b1), .asdata(1'b0), .aload(1'b0), .sclr(1'b0), .sload(1'b0)); endmodule
module \$_DFF_PN0_   (input D, C,    R, output Q); parameter WYSIWYG="TRUE"; parameter power_up=1'bx;                 dffeas #(.is_wysiwyg(WYSIWYG), .power_up("power_up")) _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(C), .clrn(R),    .prn(1'b1), .ena(1'b1), .asdata(1'b0), .aload(1'b0), .sclr(1'b0), .sload(1'b0)); endmodule
module \$_DFF_PP0_   (input D, C,    R, output Q); parameter WYSIWYG="TRUE"; parameter power_up=1'bx; wire R_i = ~ R; dffeas #(.is_wysiwyg(WYSIWYG), .power_up(power_up))   _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(C), .clrn(R_i),  .prn(1'b1), .ena(1'b1), .asdata(1'b0), .aload(1'b0), .sclr(1'b0), .sload(1'b0)); endmodule
module \$__DFFE_PP0  (input D, C, E, R, output Q); parameter WYSIWYG="TRUE"; parameter power_up=1'bx; wire E_i = ~ E; dffeas #(.is_wysiwyg(WYSIWYG), .power_up(power_up))   _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(C), .clrn(R), .   prn(1'b1), .ena(1'b1), .asdata(1'b0), .aload(1'b0), .sclr(E_i),  .sload(1'b0)); endmodule
// Intel Cyclone IV (4)
module \$_DFF_N_     (input D, C,       output Q); parameter WYSIWYG="TRUE"; parameter power_up=1'bx;                 dffeas #(.is_wysiwyg(WYSIWYG), .power_up(power_up))   _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(C), .clrn(1'b1), .prn(1'b1), .ena(1'b1), .asdata(1'b0), .aload(1'b0), .sclr(1'b0), .sload(1'b0)); endmodule
module \$_DFF_P_     (input D, C,       output Q); parameter WYSIWYG="TRUE"; parameter power_up=1'bx;                 dffeas #(.is_wysiwyg(WYSIWYG), .power_up(power_up))   _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(C), .clrn(1'b1), .prn(1'b1), .ena(1'b1), .asdata(1'b0), .aload(1'b0), .sclr(1'b0), .sload(1'b0)); endmodule
module \$_DFF_PN0_   (input D, C,    R, output Q); parameter WYSIWYG="TRUE"; parameter power_up=1'bx;                 dffeas #(.is_wysiwyg(WYSIWYG), .power_up("power_up")) _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(C), .clrn(R),    .prn(1'b1), .ena(1'b1), .asdata(1'b0), .aload(1'b0), .sclr(1'b0), .sload(1'b0)); endmodule
module \$_DFF_PP0_   (input D, C,    R, output Q); parameter WYSIWYG="TRUE"; parameter power_up=1'bx; wire R_i = ~ R; dffeas #(.is_wysiwyg(WYSIWYG), .power_up(power_up))   _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(C), .clrn(R_i),  .prn(1'b1), .ena(1'b1), .asdata(1'b0), .aload(1'b0), .sclr(1'b0), .sload(1'b0)); endmodule
module \$__DFFE_PP0  (input D, C, E, R, output Q); parameter WYSIWYG="TRUE"; parameter power_up=1'bx; wire E_i = ~ E; dffeas #(.is_wysiwyg(WYSIWYG), .power_up(power_up))   _TECHMAP_REPLACE_ (.d(D), .q(Q), .clk(C), .clrn(R),    .prn(1'b1), .ena(1'b1), .asdata(1'b0), .aload(1'b0), .sclr(E_i),  .sload(1'b0)); endmodule

// Microsemi SmartFusion 2
module \$_DFF_N_     (input D, C,       output Q); SLE                 _TECHMAP_REPLACE_ (.D(D), .CLK(!C), .EN(1'b1), .ALn(1'b1), .ADn(1'b1), .SLn(1'b1), .SD(1'b0), .LAT(1'b0), .Q(Q)); endmodule
module \$_DFF_P_     (input D, C,       output Q); SLE                 _TECHMAP_REPLACE_ (.D(D), .CLK(C),  .EN(1'b1), .ALn(1'b1), .ADn(1'b1), .SLn(1'b1), .SD(1'b0), .LAT(1'b0), .Q(Q)); endmodule
module \$_DFF_NN0_   (input D, C,    R, output Q); SLE                 _TECHMAP_REPLACE_ (.D(D), .CLK(!C), .EN(1'b1), .ALn(R),    .ADn(1'b1), .SLn(1'b1), .SD(1'b0), .LAT(1'b0), .Q(Q)); endmodule
module \$_DFF_NN1_   (input D, C,    R, output Q); SLE                 _TECHMAP_REPLACE_ (.D(D), .CLK(!C), .EN(1'b1), .ALn(R),    .ADn(1'b0), .SLn(1'b1), .SD(1'b0), .LAT(1'b0), .Q(Q)); endmodule
module \$_DFF_NP0_   (input D, C,    R, output Q); SLE                 _TECHMAP_REPLACE_ (.D(D), .CLK(!C), .EN(1'b1), .ALn(!R),   .ADn(1'b1), .SLn(1'b1), .SD(1'b0), .LAT(1'b0), .Q(Q)); endmodule
module \$_DFF_NP1_   (input D, C,    R, output Q); SLE                 _TECHMAP_REPLACE_ (.D(D), .CLK(!C), .EN(1'b1), .ALn(!R),   .ADn(1'b0), .SLn(1'b1), .SD(1'b0), .LAT(1'b0), .Q(Q)); endmodule
module \$_DFF_PN0_   (input D, C,    R, output Q); SLE                 _TECHMAP_REPLACE_ (.D(D), .CLK(C),  .EN(1'b1), .ALn(R),    .ADn(1'b1), .SLn(1'b1), .SD(1'b0), .LAT(1'b0), .Q(Q)); endmodule
module \$_DFF_PN1_   (input D, C,    R, output Q); SLE                 _TECHMAP_REPLACE_ (.D(D), .CLK(C),  .EN(1'b1), .ALn(R),    .ADn(1'b0), .SLn(1'b1), .SD(1'b0), .LAT(1'b0), .Q(Q)); endmodule
module \$_DFF_PP0_   (input D, C,    R, output Q); SLE                 _TECHMAP_REPLACE_ (.D(D), .CLK(C),  .EN(1'b1), .ALn(!R),   .ADn(1'b1), .SLn(1'b1), .SD(1'b0), .LAT(1'b0), .Q(Q)); endmodule
module \$_DFF_PP1_   (input D, C,    R, output Q); SLE                 _TECHMAP_REPLACE_ (.D(D), .CLK(C),  .EN(1'b1), .ALn(!R),   .ADn(1'b0), .SLn(1'b1), .SD(1'b0), .LAT(1'b0), .Q(Q)); endmodule
// Xilinx Series 7
module \$_DFF_N_     (input D, C,       output Q); FDRE_1 #(.INIT(|0)) _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .CE(1'b1), .R(1'b0)); endmodule
module \$_DFF_P_     (input D, C,       output Q); FDRE   #(.INIT(|0)) _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .CE(1'b1), .R(1'b0)); endmodule
module \$_DFFE_NP_   (input D, C, E,    output Q); FDRE_1 #(.INIT(|0)) _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .CE(E),    .R(1'b0)); endmodule
module \$_DFFE_PP_   (input D, C, E,    output Q); FDRE   #(.INIT(|0)) _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .CE(E),    .R(1'b0)); endmodule
module \$_DFF_NN0_   (input D, C,    R, output Q); FDCE_1 #(.INIT(|0)) _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .CE(1'b1), .CLR(!R)); endmodule
module \$_DFF_NP0_   (input D, C,    R, output Q); FDCE_1 #(.INIT(|0)) _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .CE(1'b1), .CLR( R)); endmodule
module \$_DFF_PN0_   (input D, C,    R, output Q); FDCE   #(.INIT(|0)) _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .CE(1'b1), .CLR(!R)); endmodule
module \$_DFF_PP0_   (input D, C,    R, output Q); FDCE   #(.INIT(|0)) _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .CE(1'b1), .CLR( R)); endmodule
module \$_DFF_NN1_   (input D, C,    R, output Q); FDPE_1 #(.INIT(|0)) _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .CE(1'b1), .PRE(!R)); endmodule
module \$_DFF_NP1_   (input D, C,    R, output Q); FDPE_1 #(.INIT(|0)) _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .CE(1'b1), .PRE( R)); endmodule
module \$_DFF_PN1_   (input D, C,    R, output Q); FDPE   #(.INIT(|0)) _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .CE(1'b1), .PRE(!R)); endmodule
module \$_DFF_PP1_   (input D, C,    R, output Q); FDPE   #(.INIT(|0)) _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .CE(1'b1), .PRE( R)); endmodule

