// ============================================================================
// FFs

module CESR_MUX(input CE, SR, output CE_OUT, SR_OUT);

parameter _TECHMAP_CONSTMSK_CE_ = 0;
parameter _TECHMAP_CONSTVAL_CE_ = 0;
parameter _TECHMAP_CONSTMSK_SR_ = 0;
parameter _TECHMAP_CONSTVAL_SR_ = 0;

localparam CEUSED = _TECHMAP_CONSTMSK_CE_ == 0 || _TECHMAP_CONSTVAL_CE_ == 0;
localparam SRUSED = _TECHMAP_CONSTMSK_SR_ == 0 || _TECHMAP_CONSTVAL_SR_ == 1;

if(CEUSED) begin
    assign CE_OUT = CE;
end else begin
    CE_VCC ce(
        .VCC(CE_OUT)
    );
end

if(SRUSED) begin
    assign SR_OUT = SR;
end else begin
    SR_GND sr(
        .GND(SR_OUT)
    );
end

endmodule

module FDRE (output reg Q, input C, CE, D, R);

parameter [0:0] INIT = 1'b0;

wire CE_SIG;
wire SR_SIG;

CESR_MUX cesr_mux(
    .CE(CE),
    .SR(R),
    .CE_OUT(CE_SIG),
    .SR_OUT(SR_SIG)
);

FDRE_ZINI #(.ZINI(!|INIT), .IS_C_INVERTED(|0))
  _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .CE(CE_SIG), .R(SR_SIG));

endmodule

module FDSE (output reg Q, input C, CE, D, S);

parameter [0:0] INIT = 1'b1;

wire CE_SIG;
wire SR_SIG;

CESR_MUX cesr_mux(
    .CE(CE),
    .SR(S),
    .CE_OUT(CE_SIG),
    .SR_OUT(SR_SIG)
);

FDSE_ZINI #(.ZINI(!|INIT), .IS_C_INVERTED(|0))
  _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .CE(CE_SIG), .S(SR_SIG));

endmodule

module FDCE (output reg Q, input C, CE, D, CLR);

parameter [0:0] INIT = 1'b0;

wire CE_SIG;
wire SR_SIG;

CESR_MUX cesr_mux(
    .CE(CE),
    .SR(CLR),
    .CE_OUT(CE_SIG),
    .SR_OUT(SR_SIG)
);

FDCE_ZINI #(.ZINI(!|INIT), .IS_C_INVERTED(|0))
  _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .CE(CE_SIG), .CLR(SR_SIG));

endmodule

module FDPE (output reg Q, input C, CE, D, PRE);
parameter [0:0] INIT = 1'b1;

wire CE_SIG;
wire SR_SIG;

CESR_MUX cesr_mux(
    .CE(CE),
    .SR(PRE),
    .CE_OUT(CE_SIG),
    .SR_OUT(SR_SIG)
);

FDPE_ZINI #(.ZINI(!|INIT), .IS_C_INVERTED(|0))
  _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .CE(CE_SIG), .PRE(SR_SIG));

endmodule


module FDRE_1 (output reg Q, input C, CE, D, R);

parameter [0:0] INIT = 1'b0;

wire CE_SIG;
wire SR_SIG;

CESR_MUX cesr_mux(
    .CE(CE),
    .SR(R),
    .CE_OUT(CE_SIG),
    .SR_OUT(SR_SIG)
);

FDRE_ZINI #(.ZINI(!|INIT), .IS_C_INVERTED(|1))
  _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .CE(CE_SIG), .R(SR_SIG));

endmodule

module FDSE_1 (output reg Q, input C, CE, D, S);
parameter [0:0] INIT = 1'b1;

wire CE_SIG;
wire SR_SIG;

CESR_MUX cesr_mux(
    .CE(CE),
    .SR(S),
    .CE_OUT(CE_SIG),
    .SR_OUT(SR_SIG)
);

FDSE_ZINI #(.ZINI(!|INIT), .IS_C_INVERTED(|1))
  _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .CE(CE_SIG), .S(SR_SIG));

endmodule

module FDCE_1 (output reg Q, input C, CE, D, CLR);
parameter [0:0] INIT = 1'b0;

wire CE_SIG;
wire SR_SIG;

CESR_MUX cesr_mux(
    .CE(CE),
    .SR(CLR),
    .CE_OUT(CE_SIG),
    .SR_OUT(SR_SIG)
);

FDCE_ZINI #(.ZINI(!|INIT), .IS_C_INVERTED(|1))
  _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .CE(CE_SIG), .CLR(SR_SIG));

endmodule

module FDPE_1 (output reg Q, input C, CE, D, PRE);

parameter [0:0] INIT = 1'b1;

wire CE_SIG;
wire SR_SIG;

CESR_MUX cesr_mux(
    .CE(CE),
    .SR(PRE),
    .CE_OUT(CE_SIG),
    .SR_OUT(SR_SIG)
);

FDPE_ZINI #(.ZINI(!|INIT), .IS_C_INVERTED(|1))
  _TECHMAP_REPLACE_ (.D(D), .Q(Q), .C(C), .CE(CE_SIG), .PRE(SR_SIG));

endmodule

// ============================================================================
// LUTs

module LUT1(output O, input I0);
  parameter [1:0] INIT = 0;
  \$lut #(
    .WIDTH(1),
    .LUT(INIT)
  ) _TECHMAP_REPLACE_ (
    .A(I0),
    .Y(O)
  );
endmodule

module LUT2(output O, input I0, I1);
  parameter [3:0] INIT = 0;
  \$lut #(
    .WIDTH(2),
    .LUT(INIT)
  ) _TECHMAP_REPLACE_ (
    .A({I1, I0}),
    .Y(O)
  );
endmodule

module LUT3(output O, input I0, I1, I2);
  parameter [7:0] INIT = 0;
  \$lut #(
    .WIDTH(3),
    .LUT(INIT)
  ) _TECHMAP_REPLACE_ (
    .A({I2, I1, I0}),
    .Y(O)
  );
endmodule

module LUT4(output O, input I0, I1, I2, I3);
  parameter [15:0] INIT = 0;
  \$lut #(
    .WIDTH(4),
    .LUT(INIT)
  ) _TECHMAP_REPLACE_ (
    .A({I3, I2, I1, I0}),
    .Y(O)
  );
endmodule

module LUT5(output O, input I0, I1, I2, I3, I4);
  parameter [31:0] INIT = 0;
  \$lut #(
    .WIDTH(5),
    .LUT(INIT)
  ) _TECHMAP_REPLACE_ (
    .A({I4, I3, I2, I1, I0}),
    .Y(O)
  );
endmodule

module LUT6(output O, input I0, I1, I2, I3, I4, I5);
  parameter [63:0] INIT = 0;
  wire T0, T1;
  \$lut #(
    .WIDTH(5),
    .LUT(INIT[31:0])
  ) fpga_lut_0 (
    .A({I4, I3, I2, I1, I0}),
    .Y(T0)
  );
  \$lut #(
    .WIDTH(5),
    .LUT(INIT[63:32])
  ) fpga_lut_1 (
    .A({I4, I3, I2, I1, I0}),
    .Y(T1)
  );
  MUXF6 fpga_mux_0 (.O(O), .I0(T0), .I1(T1), .S(I5));
endmodule

// ============================================================================
// Distributed RAMs

module RAM128X1S (
  output       O,
  input        D, WCLK, WE,
  input        A6, A5, A4, A3, A2, A1, A0
);
    parameter [127:0] INIT = 128'bx;
    parameter IS_WCLK_INVERTED = 0;
    wire low_lut_o6;
    wire high_lut_o6;

    wire [5:0] A = {A5, A4, A3, A2, A1, A0};

    // SPRAM128 is used here because RAM128X1S only consumes half of the
    // slice, but WA7USED is slice wide.  The packer should be able to pack two
    // RAM128X1S in a slice, but it should not be able to pack RAM128X1S and
    // a RAM64X1[SD]. It is unclear if RAM32X1[SD] or RAM32X2S can be packed
    // with a RAM128X1S, so for now it is forbidden.
    //
    // Note that a RAM128X1D does not require [SD]PRAM128 because it consumes
    // the entire slice.
    SPRAM128 #(
        .INIT(INIT[63:0]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED),
        .HIGH_WA7_SELECT(0)
    ) ram0 (
        .DI1(D),
        .A(A),
        .WA7(A6),
        .CLK(WCLK),
        .WE(WE),
        .O6(low_lut_o6)
    );

    DPRAM128 #(
        .INIT(INIT[127:64]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED),
        .HIGH_WA7_SELECT(1)
    ) ram1 (
        .DI1(D),
        .A(A),
        .WA(A),
        .WA7(A6),
        .CLK(WCLK),
        .WE(WE),
        .O6(high_lut_o6)
    );

    MUXF7 ram_f7_mux (.O(O), .I0(low_lut_o6), .I1(high_lut_o6), .S(A6));
endmodule

module RAM128X1D (
  output       DPO, SPO,
  input        D, WCLK, WE,
  input  [6:0] A, DPRA
);
    parameter [127:0] INIT = 128'bx;
    parameter IS_WCLK_INVERTED = 0;
    wire dlut_o6;
    wire clut_o6;
    wire blut_o6;
    wire alut_o6;

    SPRAM128 #(
        .INIT(INIT[63:0]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED),
        .HIGH_WA7_SELECT(0)
    ) ram0 (
        .DI1(D),
        .A(A[5:0]),
        .WA7(A[6]),
        .CLK(WCLK),
        .WE(WE),
        .O6(dlut_o6)
    );

    DPRAM128 #(
        .INIT(INIT[127:64]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED),
        .HIGH_WA7_SELECT(1)
    ) ram1 (
        .DI1(D),
        .A(A[5:0]),
        .WA(A[5:0]),
        .WA7(A[6]),
        .CLK(WCLK),
        .WE(WE),
        .O6(clut_o6)
    );

    DPRAM128 #(
        .INIT(INIT[63:0]),
        .IS_WCLK_INVERTED(1'b0),
        .HIGH_WA7_SELECT(0)
    ) ram2 (
        .DI1(D),
        .A(DPRA[5:0]),
        .WA(A[5:0]),
        .WA7(A[6]),
        .CLK(WCLK),
        .WE(WE),
        .O6(blut_o6)
    );

    DPRAM128 #(
        .INIT(INIT[127:64]),
        .IS_WCLK_INVERTED(1'b0),
        .HIGH_WA7_SELECT(0)
    ) ram3 (
        .DI1(D),
        .A(DPRA[5:0]),
        .WA(A[5:0]),
        .WA7(A[6]),
        .CLK(WCLK),
        .WE(WE),
        .O6(alut_o6)
    );

    wire SPO_FORCE;
    wire DPO_FORCE;

    MUXF7 f7b_mux (.O(SPO_FORCE), .I0(dlut_o6), .I1(clut_o6), .S(A[6]));
    MUXF7 f7a_mux (.O(DPO_FORCE), .I0(blut_o6), .I1(alut_o6), .S(DPRA[6]));

    DRAM_2_OUTPUT_STUB stub (
        .SPO(SPO_FORCE), .DPO(DPO_FORCE),
        .SPO_OUT(SPO), .DPO_OUT(DPO));
endmodule

module RAM256X1S (
  output       O,
  input        D, WCLK, WE,
  input  [7:0] A
);
    parameter [256:0] INIT = 256'bx;
    parameter IS_WCLK_INVERTED = 0;
    wire dlut_o6;
    wire clut_o6;
    wire blut_o6;
    wire alut_o6;
    wire f7b_o;
    wire f7a_o;

    SPRAM64 #(
        .INIT(INIT[63:0]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED),
        .WA7USED(1),
        .WA8USED(1),
        .HIGH_WA7_SELECT(0),
        .HIGH_WA8_SELECT(0)
    ) ram0 (
        .DI1(D),
        .A(A[5:0]),
        .WA7(A[6]),
        .WA8(A[7]),
        .CLK(WCLK),
        .WE(WE),
        .O6(dlut_o6)
    );

    DPRAM64 #(
        .INIT(INIT[127:64]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED),
        .WA7USED(1),
        .WA8USED(1),
        .HIGH_WA7_SELECT(1),
        .HIGH_WA8_SELECT(0)
    ) ram1 (
        .DI1(D),
        .A(A[5:0]),
        .WA(A[5:0]),
        .WA7(A[6]),
        .WA8(A[7]),
        .CLK(WCLK),
        .WE(WE),
        .O6(clut_o6)
    );

    DPRAM64 #(
        .INIT(INIT[191:128]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED),
        .WA7USED(1),
        .WA8USED(1),
        .HIGH_WA7_SELECT(0),
        .HIGH_WA8_SELECT(1)
    ) ram2 (
        .DI1(D),
        .A(A[5:0]),
        .WA(A[5:0]),
        .WA7(A[6]),
        .WA8(A[7]),
        .CLK(WCLK),
        .WE(WE),
        .O6(blut_o6)
    );

    DPRAM64 #(
        .INIT(INIT[255:192]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED),
        .WA7USED(1),
        .WA8USED(1),
        .HIGH_WA7_SELECT(1),
        .HIGH_WA8_SELECT(1)
    ) ram3 (
        .DI1(D),
        .A(A[5:0]),
        .WA(A[5:0]),
        .WA7(A[6]),
        .WA8(A[7]),
        .CLK(WCLK),
        .WE(WE),
        .O6(alut_o6)
    );

    MUXF7 f7b_mux (.O(f7b_o), .I0(dlut_o6), .I1(clut_o6), .S(A[6]));
    MUXF7 f7a_mux (.O(f7a_o), .I0(blut_o6), .I1(alut_o6), .S(A[6]));
    MUXF8 f8_mux (.O(O), .I0(f7b_o), .I1(f7a_o), .S(A[7]));
endmodule

module RAM32X1D (
  output DPO, SPO,
  input  D, WCLK, WE,
  input  A0, A1, A2, A3, A4,
  input  DPRA0, DPRA1, DPRA2, DPRA3, DPRA4
);
    parameter [31:0] INIT = 32'bx;
    parameter IS_WCLK_INVERTED = 0;

    wire [4:0] WA = {A4, A3, A2, A1, A0};
    wire [4:0] DPRA = {DPRA4, DPRA3, DPRA2, DPRA1, DPRA0};

    wire SPO_FORCE, DPO_FORCE;

    SPRAM32 #(
        .INIT_00(INIT),
        .IS_WCLK_INVERTED(1'b0)
    ) ram0 (
        .DI1(D),
        .A(WA),
        .CLK(WCLK),
        .WE(WE),
        .O6(SPO_FORCE)
    );
    DPRAM32 #(
        .INIT_00(INIT),
        .IS_WCLK_INVERTED(1'b0)
    ) ram1 (
        .DI1(D),
        .A(DPRA),
        .WA(WA),
        .CLK(WCLK),
        .WE(WE),
        .O6(DPO_FORCE)
    );

    DRAM_2_OUTPUT_STUB stub (
        .SPO(SPO_FORCE), .DPO(DPO_FORCE),
        .SPO_OUT(SPO), .DPO_OUT(DPO));
endmodule

module RAM32X1S (
  output O,
  input  D, WCLK, WE,
  input  A0, A1, A2, A3, A4
);
    parameter [31:0] INIT = 32'bx;
    parameter IS_WCLK_INVERTED = 0;

    SPRAM32 #(
        .INIT_00(INIT),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) dram_S (
        .DI1(D),
        .A({A4, A3, A2, A1, A0}),
        .CLK(WCLK),
        .WE(WE),
        .O6(O)
    );
endmodule

module RAM32X2S (
  output O0, O1,
  input  D0, D1, WCLK, WE,
  input  A0, A1, A2, A3, A4
);
    parameter [31:0] INIT_00 = 32'bx;
    parameter [31:0] INIT_01 = 32'bx;
    parameter IS_WCLK_INVERTED = 0;

    SPRAM32 #(
        .INIT_00(INIT_00),
        .INIT_01(INIT_01),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) dram_S (
        .DI1(D0),
        .DI2(D1),
        .A({A4, A3, A2, A1, A0}),
        .CLK(WCLK),
        .WE(WE),
        .O5(O1),
        .O6(O0)
    );
endmodule

module RAM32M (
  output [1:0] DOA, DOB, DOC, DOD,
  input [1:0] DIA, DIB, DIC, DID,
  input [4:0] ADDRA, ADDRB, ADDRC, ADDRD,
  input WE, WCLK
);
    parameter [63:0] INIT_A = 64'bx;
    parameter [63:0] INIT_B = 64'bx;
    parameter [63:0] INIT_C = 64'bx;
    parameter [63:0] INIT_D = 64'bx;

endmodule

//module RAM64M (
//  output DOA, DOB, DOC, DOD,
//  input DIA, DIB, DIC, DID,
//  input [5:0] ADDRA, ADDRB, ADDRC, ADDRD,
//  input WE, WCLK
//);
//    parameter [63:0] INIT_A = 64'bx;
//    parameter [63:0] INIT_B = 64'bx;
//    parameter [63:0] INIT_C = 64'bx;
//    parameter [63:0] INIT_D = 64'bx;
//    parameter IS_WCLK_INVERTED = 0;
//
//    parameter _TECHMAP_BITS_CONNMAP_ = 0;
//    parameter _TECHMAP_CONNMAP_DIA_ = 0;
//    parameter _TECHMAP_CONNMAP_DIB_ = 0;
//    parameter _TECHMAP_CONNMAP_DIC_ = 0;
//    parameter _TECHMAP_CONNMAP_DID_ = 0;
//    parameter _TECHMAP_CONNMAP_ADDRA_ = 0;
//    parameter _TECHMAP_CONNMAP_ADDRB_ = 0;
//    parameter _TECHMAP_CONNMAP_ADDRC_ = 0;
//    parameter _TECHMAP_CONNMAP_ADDRD_ = 0;
//
//    wire COMMON_DI_PORT = (_TECHMAP_CONNMAP_DIA_ == _TECHMAP_CONNMAP_DIB_) &
//        (_TECHMAP_CONNMAP_DIA_ == _TECHMAP_CONNMAP_DIB_) &
//        (_TECHMAP_CONNMAP_DIA_ == _TECHMAP_CONNMAP_DID_);
//
//    wire COMMON_ADDR_PORT = (_TECHMAP_CONNMAP_ADDRA_ == _TECHMAP_CONNMAP_ADDRB_) &
//        (_TECHMAP_CONNMAP_ADDRA_ == _TECHMAP_CONNMAP_ADDRC_) &
//        (_TECHMAP_CONNMAP_ADDRA_ == _TECHMAP_CONNMAP_ADDRD_);
//
//    wire DOD_TO_STUB;
//    wire DOC_TO_STUB;
//    wire DOB_TO_STUB;
//    wire DOA_TO_STUB;
//
//    wire GROUNDED_DID_PORT = (_TECHMAP_CONNMAP_DID_ == 0);
//
//    if(!GROUNDED_DID_PORT) begin
//        SPRAM64 #(
//            .INIT(INIT_D),
//            .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
//        ) dram1 (
//            .DI1(DID_IN),
//            .A(ADDRD),
//            .CLK(WCLK),
//            .WE(WE),
//            .O6(DOD_TO_STUB)
//        );
//    end
//
//    if(!GROUNDED_DID_PORT) begin
//        DRAM_4_OUTPUT_STUB stub (
//            .DOD(DOD_TO_STUB), .DOD_OUT(DOD),
//            .DOC(DOC_TO_STUB), .DOC_OUT(DOC),
//            .DOB(DOB_TO_STUB), .DOB_OUT(DOB),
//            .DOA(DOA_TO_STUB), .DOA_OUT(DOA)
//        );
//    end else begin
//        DRAM_4_OUTPUT_STUB stub (
//            .DOC(DOC_TO_STUB), .DOC_OUT(DOC),
//            .DOB(DOB_TO_STUB), .DOB_OUT(DOB),
//            .DOA(DOA_TO_STUB), .DOA_OUT(DOA)
//        );
//    end
//endmodule

module RAM64X1D (
  output DPO, SPO,
  input  D, WCLK, WE,
  input  A0, A1, A2, A3, A4, A5,
  input  DPRA0, DPRA1, DPRA2, DPRA3, DPRA4, DPRA5
);
    parameter [63:0] INIT = 64'bx;
    parameter IS_WCLK_INVERTED = 0;

    wire [5:0] WA = {A5, A4, A3, A2, A1, A0};
    wire [5:0] DPRA = {DPRA5, DPRA4, DPRA3, DPRA2, DPRA1, DPRA0};
    wire SPO_FORCE, DPO_FORCE;

    SPRAM64 #(
        .INIT(INIT),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) dram1 (
        .DI1(D),
        .A(WA),
        .CLK(WCLK),
        .WE(WE),
        .O6(SPO_FORCE)
    );
    DPRAM64 #(
        .INIT(INIT),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) dram0 (
        .DI1(D),
        .A(DPRA),
        .WA(WA),
        .CLK(WCLK),
        .WE(WE),
        .O6(DPO_FORCE)
    );

    DRAM_2_OUTPUT_STUB stub (
        .SPO(SPO_FORCE), .DPO(DPO_FORCE),
        .SPO_OUT(SPO), .DPO_OUT(DPO));
endmodule

module RAM64X1S (
  output O,
  input  D, WCLK, WE,
  input  A0, A1, A2, A3, A4, A5
);
    parameter [63:0] INIT = 64'bx;
    parameter IS_WCLK_INVERTED = 0;

    SPRAM64 #(
        .INIT(INIT),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) dram_S (
        .DI1(D),
        .A({A5, A4, A3, A2, A1, A0}),
        .CLK(WCLK),
        .WE(WE),
        .O6(O)
    );
endmodule

// ============================================================================
// Block RAMs

module RAMB18E1 (
    input CLKARDCLK,
    input CLKBWRCLK,
    input ENARDEN,
    input ENBWREN,
    input REGCEAREGCE,
    input REGCEB,
    input RSTRAMARSTRAM,
    input RSTRAMB,
    input RSTREGARSTREG,
    input RSTREGB,

    input [13:0] ADDRARDADDR,
    input [13:0] ADDRBWRADDR,
    input [15:0] DIADI,
    input [15:0] DIBDI,
    input [1:0] DIPADIP,
    input [1:0] DIPBDIP,
    input [1:0] WEA,
    input [3:0] WEBWE,

    output [15:0] DOADO,
    output [15:0] DOBDO,
    output [1:0] DOPADOP,
    output [1:0] DOPBDOP
);
    parameter INIT_A = 18'h0;
    parameter INIT_B = 18'h0;

    parameter SRVAL_A = 18'h0;
    parameter SRVAL_B = 18'h0;

    parameter INITP_00 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INITP_01 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INITP_02 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INITP_03 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INITP_04 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INITP_05 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INITP_06 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INITP_07 = 256'h0000000000000000000000000000000000000000000000000000000000000000;

    parameter INIT_00 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_01 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_02 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_03 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_04 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_05 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_06 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_07 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_08 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_09 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_0A = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_0B = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_0C = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_0D = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_0E = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_0F = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_10 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_11 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_12 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_13 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_14 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_15 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_16 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_17 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_18 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_19 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_1A = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_1B = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_1C = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_1D = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_1E = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_1F = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_20 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_21 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_22 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_23 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_24 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_25 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_26 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_27 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_28 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_29 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_2A = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_2B = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_2C = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_2D = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_2E = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_2F = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_30 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_31 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_32 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_33 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_34 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_35 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_36 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_37 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_38 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_39 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_3A = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_3B = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_3C = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_3D = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_3E = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT_3F = 256'h0000000000000000000000000000000000000000000000000000000000000000;

    parameter IS_CLKARDCLK_INVERTED = 1'b0;
    parameter IS_CLKBWRCLK_INVERTED = 1'b0;
    parameter IS_ENARDEN_INVERTED = 1'b0;
    parameter IS_ENBWREN_INVERTED = 1'b0;
    parameter IS_RSTRAMARSTRAM_INVERTED = 1'b0;
    parameter IS_RSTRAMB_INVERTED = 1'b0;
    parameter IS_RSTREGARSTREG_INVERTED = 1'b0;
    parameter IS_RSTREGB_INVERTED = 1'b0;

    parameter _TECHMAP_CONSTMSK_CLKBWRCLK_ = 0;
    parameter _TECHMAP_CONSTVAL_CLKBWRCLK_ = 0;
    parameter _TECHMAP_CONSTMSK_REGCLKARDRCLK_ = 0;
    parameter _TECHMAP_CONSTVAL_REGCLKARDRCLK_ = 0;
    parameter _TECHMAP_CONSTMSK_RSTRAMARSTRAM_ = 0;
    parameter _TECHMAP_CONSTVAL_RSTRAMARSTRAM_ = 0;
    parameter _TECHMAP_CONSTMSK_RSTRAMB_ = 0;
    parameter _TECHMAP_CONSTVAL_RSTRAMB_ = 0;
    parameter _TECHMAP_CONSTMSK_RSTREGARSTREG_ = 0;
    parameter _TECHMAP_CONSTVAL_RSTREGARSTREG_ = 0;
    parameter _TECHMAP_CONSTMSK_RSTREGB_ = 0;
    parameter _TECHMAP_CONSTVAL_RSTREGB_ = 0;

    parameter RAM_MODE = "TDP";
    parameter SIM_DEVICE = "7SERIES";
    parameter DOA_REG = 1'b0;
    parameter DOB_REG = 1'b0;

    parameter integer READ_WIDTH_A = 0;
    parameter integer READ_WIDTH_B = 0;
    parameter integer WRITE_WIDTH_A = 0;
    parameter integer WRITE_WIDTH_B = 0;

    parameter WRITE_MODE_A = "WRITE_FIRST";
    parameter WRITE_MODE_B = "WRITE_FIRST";

  reg _TECHMAP_FAIL_;
  wire [1023:0] _TECHMAP_DO_ = "proc; clean";

  localparam INV_CLKBWRCLK = (
      _TECHMAP_CONSTMSK_CLKBWRCLK_ == 1 &&
      _TECHMAP_CONSTVAL_CLKBWRCLK_ == 0 &&
      IS_CLKBWRCLK_INVERTED == 0);
  localparam INV_RSTRAMARSTRAM = (
      _TECHMAP_CONSTMSK_RSTRAMARSTRAM_ == 1 &&
      _TECHMAP_CONSTVAL_RSTRAMARSTRAM_ == 0 &&
      IS_RSTRAMARSTRAM_INVERTED == 0);
  localparam INV_RSTRAMB = (
      _TECHMAP_CONSTMSK_RSTRAMB_ == 1 &&
      _TECHMAP_CONSTVAL_RSTRAMB_ == 0 &&
      IS_RSTRAMB_INVERTED == 0);
  localparam INV_RSTREGARSTREG = (
      _TECHMAP_CONSTMSK_RSTREGARSTREG_ == 1 &&
      _TECHMAP_CONSTVAL_RSTREGARSTREG_ == 0 &&
      IS_RSTREGARSTREG_INVERTED == 0);
  localparam INV_RSTREGB = (
      _TECHMAP_CONSTMSK_RSTREGB_ == 1 &&
      _TECHMAP_CONSTVAL_RSTREGB_ == 0 &&
      IS_RSTREGB_INVERTED == 0);

  initial begin
    _TECHMAP_FAIL_ <= 0;
    if(READ_WIDTH_A != 0
        && READ_WIDTH_A != 1
        && READ_WIDTH_A != 4
        && READ_WIDTH_A != 9
        && READ_WIDTH_A != 18
        && READ_WIDTH_A != 36
        && READ_WIDTH_A != 72)
        $error("Invalid READ_WIDTH_A: ", READ_WIDTH_A);
    if(READ_WIDTH_B != 0
        && READ_WIDTH_B != 1
        && READ_WIDTH_B != 4
        && READ_WIDTH_B != 9
        && READ_WIDTH_B != 18)
        $error("Invalid READ_WIDTH_B: ", READ_WIDTH_B);
    if(WRITE_WIDTH_A != 0
        && WRITE_WIDTH_A != 1
        && WRITE_WIDTH_A != 4
        && WRITE_WIDTH_A != 9
        && WRITE_WIDTH_A != 18)
        $error("Invalid WRITE_WIDTH_A: ", WRITE_WIDTH_A);
    if(WRITE_WIDTH_B != 0
        && WRITE_WIDTH_B != 1
        && WRITE_WIDTH_B != 4
        && WRITE_WIDTH_B != 9
        && WRITE_WIDTH_B != 18
        && WRITE_WIDTH_B != 36
        && WRITE_WIDTH_B != 72)
        $error("Invalid WRITE_WIDTH_B: ", WRITE_WIDTH_B);

    if(READ_WIDTH_A > 18 && RAM_MODE != "SDP") begin
        $error("READ_WIDTH_A > 18 requires SDP mode.");
    end

    if(WRITE_WIDTH_B > 18 && RAM_MODE != "SDP") begin
        $error("WRITE_WIDTH_B > 18 requires SDP mode.");
    end

    if(WRITE_MODE_A != "WRITE_FIRST" && WRITE_MODE_A != "NO_CHANGE" && WRITE_MODE_A != "READ_FIRST")
        $error("Invalid WRITE_MODE_A", WRITE_MODE_A);
    if(WRITE_MODE_B != "WRITE_FIRST" && WRITE_MODE_B != "NO_CHANGE" && WRITE_MODE_B != "READ_FIRST")
        $error("Invalid WRITE_MODE_B", WRITE_MODE_B);

  end

if(RAM_MODE == "SDP" && READ_WIDTH_A == 36) begin
    localparam EFF_READ_WIDTH_A = 18;
    localparam EFF_READ_WIDTH_B = 18;
end else begin
    localparam EFF_READ_WIDTH_A = READ_WIDTH_A;
    localparam EFF_READ_WIDTH_B = READ_WIDTH_B;
end

if(RAM_MODE == "SDP" && WRITE_WIDTH_B == 36) begin
    localparam EFF_WRITE_WIDTH_A = 18;
    localparam EFF_WRITE_WIDTH_B = 18;
end else begin
    localparam EFF_WRITE_WIDTH_A = WRITE_WIDTH_A;
    localparam EFF_WRITE_WIDTH_B = WRITE_WIDTH_B;
end

  wire REGCLKA;
  wire REGCLKB;

  wire [7:0] WEBWE_WIDE = {
      WEBWE[3], WEBWE[3], WEBWE[2], WEBWE[2],
      WEBWE[1], WEBWE[1], WEBWE[0], WEBWE[0]};

  wire [3:0] WEA_WIDE = {WEA[1], WEA[1], WEA[0], WEA[0]};


  if (DOA_REG) begin
      assign REGCLKA = CLKARDCLK;
      localparam ZINV_REGCLKARDRCLK = !IS_CLKARDCLK_INVERTED;
  end else begin
      assign REGCLKA = 1'b1;
      localparam ZINV_REGCLKARDRCLK = 1'b0;
  end

  if (DOB_REG) begin
      assign REGCLKB = CLKBWRCLK;
      localparam ZINV_REGCLKB = !IS_CLKBWRCLK_INVERTED;
  end else begin
      assign REGCLKB = 1'b1;
      localparam ZINV_REGCLKB = 1'b0;
  end

  RAMB18E1_VPR #(
      .IN_USE(READ_WIDTH_A != 0 || READ_WIDTH_B != 0 || WRITE_WIDTH_A != 0 || WRITE_WIDTH_B != 0),

      .ZINIT_A(INIT_A ^ {18{1'b1}}),
      .ZINIT_B(INIT_B ^ {18{1'b1}}),

      .ZSRVAL_A(SRVAL_A ^ {18{1'b1}}),
      .ZSRVAL_B(SRVAL_B ^ {18{1'b1}}),

      .INITP_00(INITP_00),
      .INITP_01(INITP_01),
      .INITP_02(INITP_02),
      .INITP_03(INITP_03),
      .INITP_04(INITP_04),
      .INITP_05(INITP_05),
      .INITP_06(INITP_06),
      .INITP_07(INITP_07),

      .INIT_00(INIT_00),
      .INIT_01(INIT_01),
      .INIT_02(INIT_02),
      .INIT_03(INIT_03),
      .INIT_04(INIT_04),
      .INIT_05(INIT_05),
      .INIT_06(INIT_06),
      .INIT_07(INIT_07),
      .INIT_08(INIT_08),
      .INIT_09(INIT_09),
      .INIT_0A(INIT_0A),
      .INIT_0B(INIT_0B),
      .INIT_0C(INIT_0C),
      .INIT_0D(INIT_0D),
      .INIT_0E(INIT_0E),
      .INIT_0F(INIT_0F),
      .INIT_10(INIT_10),
      .INIT_11(INIT_11),
      .INIT_12(INIT_12),
      .INIT_13(INIT_13),
      .INIT_14(INIT_14),
      .INIT_15(INIT_15),
      .INIT_16(INIT_16),
      .INIT_17(INIT_17),
      .INIT_18(INIT_18),
      .INIT_19(INIT_19),
      .INIT_1A(INIT_1A),
      .INIT_1B(INIT_1B),
      .INIT_1C(INIT_1C),
      .INIT_1D(INIT_1D),
      .INIT_1E(INIT_1E),
      .INIT_1F(INIT_1F),
      .INIT_20(INIT_20),
      .INIT_21(INIT_21),
      .INIT_22(INIT_22),
      .INIT_23(INIT_23),
      .INIT_24(INIT_24),
      .INIT_25(INIT_25),
      .INIT_26(INIT_26),
      .INIT_27(INIT_27),
      .INIT_28(INIT_28),
      .INIT_29(INIT_29),
      .INIT_2A(INIT_2A),
      .INIT_2B(INIT_2B),
      .INIT_2C(INIT_2C),
      .INIT_2D(INIT_2D),
      .INIT_2E(INIT_2E),
      .INIT_2F(INIT_2F),
      .INIT_30(INIT_30),
      .INIT_31(INIT_31),
      .INIT_32(INIT_32),
      .INIT_33(INIT_33),
      .INIT_34(INIT_34),
      .INIT_35(INIT_35),
      .INIT_36(INIT_36),
      .INIT_37(INIT_37),
      .INIT_38(INIT_38),
      .INIT_39(INIT_39),
      .INIT_3A(INIT_3A),
      .INIT_3B(INIT_3B),
      .INIT_3C(INIT_3C),
      .INIT_3D(INIT_3D),
      .INIT_3E(INIT_3E),
      .INIT_3F(INIT_3F),

      .ZINV_CLKARDCLK(!IS_CLKARDCLK_INVERTED),
      .ZINV_CLKBWRCLK(!IS_CLKBWRCLK_INVERTED ^ INV_CLKBWRCLK),
      .ZINV_ENARDEN(!IS_ENARDEN_INVERTED),
      .ZINV_ENBWREN(!IS_ENBWREN_INVERTED),
      .ZINV_RSTRAMARSTRAM(!IS_RSTRAMARSTRAM_INVERTED ^ INV_RSTRAMARSTRAM),
      .ZINV_RSTRAMB(!IS_RSTRAMB_INVERTED ^ INV_RSTRAMB),
      .ZINV_RSTREGARSTREG(!IS_RSTREGARSTREG_INVERTED ^ INV_RSTREGARSTREG),
      .ZINV_RSTREGB(!IS_RSTREGB_INVERTED ^ INV_RSTREGB),
      .ZINV_REGCLKARDRCLK(ZINV_REGCLKARDRCLK),
      .ZINV_REGCLKB(ZINV_REGCLKB),

      .DOA_REG(DOA_REG),
      .DOB_REG(DOB_REG),

      .READ_WIDTH_A_1(EFF_READ_WIDTH_A == 1 || EFF_READ_WIDTH_A == 0),
      .READ_WIDTH_A_2(EFF_READ_WIDTH_A == 2),
      .READ_WIDTH_A_4(EFF_READ_WIDTH_A == 4),
      .READ_WIDTH_A_9(EFF_READ_WIDTH_A == 9),
      .READ_WIDTH_A_18(EFF_READ_WIDTH_A == 18),
      .SDP_READ_WIDTH_36(READ_WIDTH_A == 36),
      .READ_WIDTH_B_1(EFF_READ_WIDTH_B == 1 || EFF_READ_WIDTH_B == 0),
      .READ_WIDTH_B_2(EFF_READ_WIDTH_B == 2),
      .READ_WIDTH_B_4(EFF_READ_WIDTH_B == 4),
      .READ_WIDTH_B_9(EFF_READ_WIDTH_B == 9),
      .READ_WIDTH_B_18(EFF_READ_WIDTH_B == 18),
      .WRITE_WIDTH_A_1(EFF_WRITE_WIDTH_A == 1 || EFF_WRITE_WIDTH_A == 0),
      .WRITE_WIDTH_A_2(EFF_WRITE_WIDTH_A == 2),
      .WRITE_WIDTH_A_4(EFF_WRITE_WIDTH_A == 4),
      .WRITE_WIDTH_A_9(EFF_WRITE_WIDTH_A == 9),
      .WRITE_WIDTH_A_18(EFF_WRITE_WIDTH_A == 18),
      .WRITE_WIDTH_B_1(EFF_WRITE_WIDTH_B == 1 || EFF_WRITE_WIDTH_B == 0),
      .WRITE_WIDTH_B_2(EFF_WRITE_WIDTH_B == 2),
      .WRITE_WIDTH_B_4(EFF_WRITE_WIDTH_B == 4),
      .WRITE_WIDTH_B_9(EFF_WRITE_WIDTH_B == 9),
      .WRITE_WIDTH_B_18(EFF_WRITE_WIDTH_B == 18 || EFF_WRITE_WIDTH_B == 36),
      .SDP_WRITE_WIDTH_36(WRITE_WIDTH_B == 36),
      .WRITE_MODE_A_NO_CHANGE(WRITE_MODE_A == "NO_CHANGE" || (WRITE_MODE_A == "WRITE_FIRST" && RAM_MODE == "SDP")),
      .WRITE_MODE_A_READ_FIRST(WRITE_MODE_A == "READ_FIRST"),
      .WRITE_MODE_B_NO_CHANGE(WRITE_MODE_B == "NO_CHANGE" || (WRITE_MODE_B == "WRITE_FIRST" && RAM_MODE == "SDP")),
      .WRITE_MODE_B_READ_FIRST(WRITE_MODE_B == "READ_FIRST"),
  ) _TECHMAP_REPLACE_ (
    .CLKARDCLK(CLKARDCLK),
    .REGCLKARDRCLK(REGCLKA),
    .CLKBWRCLK(CLKBWRCLK ^ INV_CLKBWRCLK),
    .REGCLKB(REGCLKB),
    .ENARDEN(ENARDEN),
    .ENBWREN(ENBWREN),
    .REGCEAREGCE(REGCEAREGCE),
    .REGCEB(REGCEB),
    .RSTRAMARSTRAM(RSTRAMARSTRAM ^ INV_RSTRAMARSTRAM),
    .RSTRAMB(RSTRAMB ^ INV_RSTRAMB),
    .RSTREGARSTREG(RSTREGARSTREG ^ INV_RSTREGARSTREG),
    .RSTREGB(RSTREGB ^ INV_RSTREGB),

    .ADDRATIEHIGH(2'b11),
    .ADDRARDADDR(ADDRARDADDR),
    .ADDRBTIEHIGH(2'b11),
    .ADDRBWRADDR(ADDRBWRADDR),
    .DIADI(DIADI),
    .DIBDI(DIBDI),
    .DIPADIP(DIPADIP),
    .DIPBDIP(DIPBDIP),
    .WEA(WEA_WIDE),
    .WEBWE(WEBWE_WIDE),

    .DOADO(DOADO),
    .DOBDO(DOBDO),
    .DOPADOP(DOPADOP),
    .DOPBDOP(DOPBDOP)
  );
endmodule

module CARRY0(output CO_CHAIN, CO_FABRIC, O, input CI, CI_INIT, DI, S);
  parameter CYINIT_FABRIC = 0;
  parameter _TECHMAP_CONSTMSK_CI_INIT_ = 0;
  parameter _TECHMAP_CONSTVAL_CI_INIT_ = 0;

  // Only connect CI_INIT for non-constant signals.
  wire CI_INIT_INNER;
  if(_TECHMAP_CONSTMSK_CI_INIT_ == 0 && CYINIT_FABRIC) begin
    CARRY0_CONST #(
        .CYINIT_AX(1'b1),
        .CYINIT_C0(1'b0),
        .CYINIT_C1(1'b0)
    ) _TECHMAP_REPLACE_ (
        .CO_CHAIN(CO_CHAIN),
        .CO_FABRIC(CO_FABRIC),
        .O(O),
        .CI_INIT(CI_INIT),
        .DI(DI),
        .S(S)
    );
  end else if(!CYINIT_FABRIC) begin
    CARRY0_CONST #(
        .CYINIT_AX(1'b0),
        .CYINIT_C0(1'b0),
        .CYINIT_C1(1'b0)
    ) _TECHMAP_REPLACE_ (
        .CO_CHAIN(CO_CHAIN),
        .CO_FABRIC(CO_FABRIC),
        .O(O),
        .CI(CI),
        .DI(DI),
        .S(S)
    );
  end else begin
    CARRY0_CONST #(
        .CYINIT_AX(1'b0),
        .CYINIT_C0(_TECHMAP_CONSTVAL_CI_INIT_ == 0),
        .CYINIT_C1(_TECHMAP_CONSTVAL_CI_INIT_ == 1)
    ) _TECHMAP_REPLACE_ (
        .CO_CHAIN(CO_CHAIN),
        .CO_FABRIC(CO_FABRIC),
        .O(O),
        .DI(DI),
        .S(S)
    );
  end
endmodule
