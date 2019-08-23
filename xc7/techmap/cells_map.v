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

    // DPRAM64_for_RAM128X1D is used here because RAM128X1S only consumes half of the
    // slice, but WA7USED is slice wide.  The packer should be able to pack two
    // RAM128X1S in a slice, but it should not be able to pack RAM128X1S and
    // a RAM64X1[SD]. It is unclear if RAM32X1[SD] or RAM32X2S can be packed
    // with a RAM128X1S, so for now it is forbidden.
    //
    // Note that a RAM128X1D does not require [SD]PRAM128 because it consumes
    // the entire slice.
    DPRAM64_for_RAM128X1D #(
        .INIT(INIT[63:0]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED),
        .HIGH_WA7_SELECT(0)
    ) ram0 (
        .DI(D),
        .A(A),
        .WA(A),
        .WA7(A6),
        .CLK(WCLK),
        .WE(WE),
        .O(low_lut_o6)
    );

    DPRAM64_for_RAM128X1D #(
        .INIT(INIT[127:64]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED),
        .HIGH_WA7_SELECT(1)
    ) ram1 (
        .DI(D),
        .A(A),
        .WA(A),
        .WA7(A6),
        .CLK(WCLK),
        .WE(WE),
        .O(high_lut_o6)
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

    DPRAM64_for_RAM128X1D #(
        .INIT(INIT[63:0]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED),
        .HIGH_WA7_SELECT(0)
    ) ram0 (
        .DI(D),
        .A(A[5:0]),
        .WA(A[5:0]),
        .WA7(A[6]),
        .CLK(WCLK),
        .WE(WE),
        .O(dlut_o6)
    );

    DPRAM64_for_RAM128X1D #(
        .INIT(INIT[127:64]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED),
        .HIGH_WA7_SELECT(1)
    ) ram1 (
        .DI(D),
        .A(A[5:0]),
        .WA(A[5:0]),
        .WA7(A[6]),
        .CLK(WCLK),
        .WE(WE),
        .O(clut_o6)
    );

    DPRAM64_for_RAM128X1D #(
        .INIT(INIT[63:0]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED),
        .HIGH_WA7_SELECT(0)
    ) ram2 (
        .DI(D),
        .A(DPRA[5:0]),
        .WA(A[5:0]),
        .WA7(A[6]),
        .CLK(WCLK),
        .WE(WE),
        .O(blut_o6)
    );

    DPRAM64_for_RAM128X1D #(
        .INIT(INIT[127:64]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED),
        .HIGH_WA7_SELECT(0)
    ) ram3 (
        .DI(D),
        .A(DPRA[5:0]),
        .WA(A[5:0]),
        .WA7(A[6]),
        .CLK(WCLK),
        .WE(WE),
        .O(alut_o6)
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

    DPRAM64 #(
        .INIT(INIT[63:0]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED),
        .WA7USED(1),
        .WA8USED(1),
        .HIGH_WA7_SELECT(0),
        .HIGH_WA8_SELECT(0)
    ) ram0 (
        .DI(D),
        .A(A[5:0]),
        .WA(A[5:0]),
        .WA7(A[6]),
        .WA8(A[7]),
        .CLK(WCLK),
        .WE(WE),
        .O(dlut_o6)
    );

    DPRAM64 #(
        .INIT(INIT[127:64]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED),
        .WA7USED(1),
        .WA8USED(1),
        .HIGH_WA7_SELECT(1),
        .HIGH_WA8_SELECT(0)
    ) ram1 (
        .DI(D),
        .A(A[5:0]),
        .WA(A[5:0]),
        .WA7(A[6]),
        .WA8(A[7]),
        .CLK(WCLK),
        .WE(WE),
        .O(clut_o6)
    );

    DPRAM64 #(
        .INIT(INIT[191:128]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED),
        .WA7USED(1),
        .WA8USED(1),
        .HIGH_WA7_SELECT(0),
        .HIGH_WA8_SELECT(1)
    ) ram2 (
        .DI(D),
        .A(A[5:0]),
        .WA(A[5:0]),
        .WA7(A[6]),
        .WA8(A[7]),
        .CLK(WCLK),
        .WE(WE),
        .O(blut_o6)
    );

    DPRAM64 #(
        .INIT(INIT[255:192]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED),
        .WA7USED(1),
        .WA8USED(1),
        .HIGH_WA7_SELECT(1),
        .HIGH_WA8_SELECT(1)
    ) ram3 (
        .DI(D),
        .A(A[5:0]),
        .WA(A[5:0]),
        .WA7(A[6]),
        .WA8(A[7]),
        .CLK(WCLK),
        .WE(WE),
        .O(alut_o6)
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

    DPRAM32 #(
        .INIT_00(INIT),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) ram0 (
        .DI(D),
        .A(WA),
        .WA(WA),
        .CLK(WCLK),
        .WE(WE),
        .O(SPO_FORCE)
    );
    DPRAM32 #(
        .INIT_00(INIT),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) ram1 (
        .DI(D),
        .A(DPRA),
        .WA(WA),
        .CLK(WCLK),
        .WE(WE),
        .O(DPO_FORCE)
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

    DPRAM32 #(
        .INIT_00(INIT),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) dram_S (
        .DI(D),
        .A({A4, A3, A2, A1, A0}),
        .WA({A4, A3, A2, A1, A0}),
        .CLK(WCLK),
        .WE(WE),
        .O(O)
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

    DPRAM32 #(
        .INIT_00(INIT_00),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) ram0 (
        .DI(D0),
        .A({A4, A3, A2, A1, A0}),
        .WA({A4, A3, A2, A1, A0}),
        .CLK(WCLK),
        .WE(WE),
        .O(O0)
    );

    DPRAM32 #(
        .INIT_00(INIT_01),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) ram1 (
        .DI(D1),
        .A({A4, A3, A2, A1, A0}),
        .WA({A4, A3, A2, A1, A0}),
        .CLK(WCLK),
        .WE(WE),
        .O(O1),
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
    parameter IS_WCLK_INVERTED = 0;

    wire [1:0] DOD_TO_STUB;
    wire [1:0] DOC_TO_STUB;
    wire [1:0] DOB_TO_STUB;
    wire [1:0] DOA_TO_STUB;

    DPRAM32 #(
        .INIT_00(INIT_A[63:32]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) ram_a1 (
         .DI(DIA[1]),
         .A(ADDRA),
         .WA(ADDRD),
         .CLK(WCLK),
         .WE(WE),
         .O(DOA_TO_STUB[1])
    );

    DPRAM32 #(
        .INIT_00(INIT_A[31:0]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) ram_a0 (
         .DI(DIA[0]),
         .A(ADDRA),
         .WA(ADDRD),
         .CLK(WCLK),
         .WE(WE),
         .O(DOA_TO_STUB[0])
    );

    DPRAM32 #(
        .INIT_00(INIT_B[63:32]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) ram_b1 (
         .DI(DIB[1]),
         .A(ADDRB),
         .WA(ADDRD),
         .CLK(WCLK),
         .WE(WE),
         .O(DOB_TO_STUB[1])
    );

    DPRAM32 #(
        .INIT_00(INIT_B[31:0]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) ram_b0 (
         .DI(DIB[0]),
         .A(ADDRB),
         .WA(ADDRD),
         .CLK(WCLK),
         .WE(WE),
         .O(DOB_TO_STUB[0])
    );

    DPRAM32 #(
        .INIT_00(INIT_C[63:32]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) ram_c1 (
         .DI(DIC[1]),
         .A(ADDRC),
         .WA(ADDRD),
         .CLK(WCLK),
         .WE(WE),
         .O(DOC_TO_STUB[1])
    );

    DPRAM32 #(
        .INIT_00(INIT_C[31:0]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) ram_c0 (
         .DI(DIC[0]),
         .A(ADDRC),
         .WA(ADDRD),
         .CLK(WCLK),
         .WE(WE),
         .O(DOC_TO_STUB[0])
    );

    DPRAM32 #(
        .INIT_00(INIT_D[63:32]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) ram_d1 (
         .DI(DID[1]),
         .A(ADDRD),
         .WA(ADDRD),
         .CLK(WCLK),
         .WE(WE),
         .O(DOD_TO_STUB[1])
    );

    DPRAM32 #(
        .INIT_00(INIT_D[31:0]),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) ram_d0 (
         .DI(DID[0]),
         .A(ADDRD),
         .WA(ADDRD),
         .CLK(WCLK),
         .WE(WE),
         .O(DOD_TO_STUB[0])
    );

    DRAM_8_OUTPUT_STUB stub (
        .DOD1(DOD_TO_STUB[1]), .DOD1_OUT(DOD[1]),
        .DOC1(DOC_TO_STUB[1]), .DOC1_OUT(DOC[1]),
        .DOB1(DOB_TO_STUB[1]), .DOB1_OUT(DOB[1]),
        .DOA1(DOA_TO_STUB[1]), .DOA1_OUT(DOA[1]),
        .DOD0(DOD_TO_STUB[0]), .DOD0_OUT(DOD[0]),
        .DOC0(DOC_TO_STUB[0]), .DOC0_OUT(DOC[0]),
        .DOB0(DOB_TO_STUB[0]), .DOB0_OUT(DOB[0]),
        .DOA0(DOA_TO_STUB[0]), .DOA0_OUT(DOA[0])
    );

endmodule

module RAM64M (
  output DOA, DOB, DOC, DOD,
  input DIA, DIB, DIC, DID,
  input [5:0] ADDRA, ADDRB, ADDRC, ADDRD,
  input WE, WCLK
);
    parameter [63:0] INIT_A = 64'bx;
    parameter [63:0] INIT_B = 64'bx;
    parameter [63:0] INIT_C = 64'bx;
    parameter [63:0] INIT_D = 64'bx;
    parameter IS_WCLK_INVERTED = 0;

    wire DOD_TO_STUB;
    wire DOC_TO_STUB;
    wire DOB_TO_STUB;
    wire DOA_TO_STUB;

    DPRAM64 #(
        .INIT(INIT_D),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) dram_d (
        .DI(DID),
        .A(ADDRD),
        .WA(ADDRD),
        .CLK(WCLK),
        .WE(WE),
        .O(DOD_TO_STUB)
    );

    DPRAM64 #(
        .INIT(INIT_C),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) dram_c (
        .DI(DIC),
        .A(ADDRC),
        .WA(ADDRD),
        .CLK(WCLK),
        .WE(WE),
        .O(DOC_TO_STUB)
    );

    DPRAM64 #(
        .INIT(INIT_B),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) dram_b (
        .DI(DIB),
        .A(ADDRB),
        .WA(ADDRD),
        .CLK(WCLK),
        .WE(WE),
        .O(DOB_TO_STUB)
    );

    DPRAM64 #(
        .INIT(INIT_A),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) dram_a (
        .DI(DIA),
        .A(ADDRA),
        .WA(ADDRD),
        .CLK(WCLK),
        .WE(WE),
        .O(DOA_TO_STUB)
    );

    DRAM_4_OUTPUT_STUB stub (
        .DOD(DOD_TO_STUB), .DOD_OUT(DOD),
        .DOC(DOC_TO_STUB), .DOC_OUT(DOC),
        .DOB(DOB_TO_STUB), .DOB_OUT(DOB),
        .DOA(DOA_TO_STUB), .DOA_OUT(DOA)
    );
endmodule

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

    DPRAM64 #(
        .INIT(INIT),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) dram1 (
        .DI(D),
        .A(WA),
        .WA(WA),
        .CLK(WCLK),
        .WE(WE),
        .O(SPO_FORCE)
    );
    DPRAM64 #(
        .INIT(INIT),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) dram0 (
        .DI(D),
        .A(DPRA),
        .WA(WA),
        .CLK(WCLK),
        .WE(WE),
        .O(DPO_FORCE)
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

    DPRAM64 #(
        .INIT(INIT),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) dram0 (
        .DI(D),
        .A({A5, A4, A3, A2, A1, A0}),
        .WA({A5, A4, A3, A2, A1, A0}),
        .CLK(WCLK),
        .WE(WE),
        .O(O)
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
        && READ_WIDTH_A != 36)
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
        && WRITE_WIDTH_B != 36)
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

  wire [7:0] WEBWE_WIDE;
  wire [3:0] WEA_WIDE;

  if(WRITE_WIDTH_A < 18) begin
      assign WEA_WIDE[3] = WEA[0];
      assign WEA_WIDE[2] = WEA[0];
      assign WEA_WIDE[1] = WEA[0];
      assign WEA_WIDE[0] = WEA[0];
  end else if(WRITE_WIDTH_A == 18) begin
      assign WEA_WIDE[3] = WEA[1];
      assign WEA_WIDE[2] = WEA[1];
      assign WEA_WIDE[1] = WEA[0];
      assign WEA_WIDE[0] = WEA[0];
  end

  if(WRITE_WIDTH_B < 18) begin
      assign WEBWE_WIDE[7:4] = 4'b0;
      assign WEBWE_WIDE[3] = WEBWE[0];
      assign WEBWE_WIDE[2] = WEBWE[0];
      assign WEBWE_WIDE[1] = WEBWE[0];
      assign WEBWE_WIDE[0] = WEBWE[0];
  end else if(WRITE_WIDTH_B == 18) begin
      assign WEBWE_WIDE[7:4] = 4'b0;
      assign WEBWE_WIDE[3] = WEBWE[1];
      assign WEBWE_WIDE[2] = WEBWE[1];
      assign WEBWE_WIDE[1] = WEBWE[0];
      assign WEBWE_WIDE[0] = WEBWE[0];
  end else begin
      assign WEA_WIDE[3:0] = 4'b0;
      assign WEBWE_WIDE[7] = WEBWE[3];
      assign WEBWE_WIDE[6] = WEBWE[3];
      assign WEBWE_WIDE[5] = WEBWE[2];
      assign WEBWE_WIDE[4] = WEBWE[2];
      assign WEBWE_WIDE[3] = WEBWE[1];
      assign WEBWE_WIDE[2] = WEBWE[1];
      assign WEBWE_WIDE[1] = WEBWE[0];
      assign WEBWE_WIDE[0] = WEBWE[0];
  end

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
      .WRITE_MODE_B_READ_FIRST(WRITE_MODE_B == "READ_FIRST")
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

function [255:0] every_other_bit;
   input [511:0] in;
   input         odd;
   integer       i;
   for (i = 0; i < 256; i = i + 1) begin
      every_other_bit[i] = in[i * 2 + odd];
   end
endfunction

module RAMB36E1 (
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

    input [14:0] ADDRARDADDR,
    input [14:0] ADDRBWRADDR,
    input [31:0] DIADI,
    input [31:0] DIBDI,
    input [3:0] DIPADIP,
    input [3:0] DIPBDIP,
    input [3:0] WEA,
    input [7:0] WEBWE,

    output [31:0] DOADO,
    output [31:0] DOBDO,
    output [3:0] DOPADOP,
    output [3:0] DOPBDOP
);
    parameter INIT_A = 36'h0;
    parameter INIT_B = 36'h0;

    parameter SRVAL_A = 36'h0;
    parameter SRVAL_B = 36'h0;

   `define INIT_BLOCK(pre) \
    parameter ``pre``0 = 256'h0000000000000000000000000000000000000000000000000000000000000000; \
    parameter ``pre``1 = 256'h0000000000000000000000000000000000000000000000000000000000000000; \
    parameter ``pre``2 = 256'h0000000000000000000000000000000000000000000000000000000000000000; \
    parameter ``pre``3 = 256'h0000000000000000000000000000000000000000000000000000000000000000; \
    parameter ``pre``4 = 256'h0000000000000000000000000000000000000000000000000000000000000000; \
    parameter ``pre``5 = 256'h0000000000000000000000000000000000000000000000000000000000000000; \
    parameter ``pre``6 = 256'h0000000000000000000000000000000000000000000000000000000000000000; \
    parameter ``pre``7 = 256'h0000000000000000000000000000000000000000000000000000000000000000; \
    parameter ``pre``8 = 256'h0000000000000000000000000000000000000000000000000000000000000000; \
    parameter ``pre``9 = 256'h0000000000000000000000000000000000000000000000000000000000000000; \
    parameter ``pre``A = 256'h0000000000000000000000000000000000000000000000000000000000000000; \
    parameter ``pre``B = 256'h0000000000000000000000000000000000000000000000000000000000000000; \
    parameter ``pre``C = 256'h0000000000000000000000000000000000000000000000000000000000000000; \
    parameter ``pre``D = 256'h0000000000000000000000000000000000000000000000000000000000000000; \
    parameter ``pre``E = 256'h0000000000000000000000000000000000000000000000000000000000000000; \
    parameter ``pre``F = 256'h0000000000000000000000000000000000000000000000000000000000000000

    `INIT_BLOCK(INITP_0);
    `INIT_BLOCK(INIT_0);
    `INIT_BLOCK(INIT_1);
    `INIT_BLOCK(INIT_2);
    `INIT_BLOCK(INIT_3);
    `INIT_BLOCK(INIT_4);
    `INIT_BLOCK(INIT_5);
    `INIT_BLOCK(INIT_6);
    `INIT_BLOCK(INIT_7);

    `undef INIT_BLOCK

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

  `define INVALID_WIDTH(x) \
          ((x) != 0 \
        && (x) != 1 \
        && (x) != 2 \
        && (x) != 4 \
        && (x) != 9 \
        && (x) != 18 \
        && (x) != 36)
  `define INVALID_WIDTH_WIDE(x) \
     (`INVALID_WIDTH(x) \
        && (x) != 72)

    if(`INVALID_WIDTH_WIDE(READ_WIDTH_A))
        $error("Invalid READ_WIDTH_A: ", READ_WIDTH_A);
    if(`INVALID_WIDTH(READ_WIDTH_B))
        $error("Invalid READ_WIDTH_B: ", READ_WIDTH_B);
    if(`INVALID_WIDTH(WRITE_WIDTH_A))
        $error("Invalid WRITE_WIDTH_A: ", WRITE_WIDTH_A);
    if(`INVALID_WIDTH_WIDE(WRITE_WIDTH_B))
        $error("Invalid WRITE_WIDTH_B: ", WRITE_WIDTH_B);

    `undef INVALID_WIDTH
    `undef INVALID_WIDTH_WIDE

    if(READ_WIDTH_A > 36 && RAM_MODE != "SDP") begin
        $error("READ_WIDTH_A > 36 requires SDP mode.");
    end

    if(WRITE_WIDTH_B > 36 && RAM_MODE != "SDP") begin
        $error("WRITE_WIDTH_B > 36 requires SDP mode.");
    end

    if(WRITE_MODE_A != "WRITE_FIRST" && WRITE_MODE_A != "NO_CHANGE" && WRITE_MODE_A != "READ_FIRST")
        $error("Invalid WRITE_MODE_A", WRITE_MODE_A);
    if(WRITE_MODE_B != "WRITE_FIRST" && WRITE_MODE_B != "NO_CHANGE" && WRITE_MODE_B != "READ_FIRST")
        $error("Invalid WRITE_MODE_B", WRITE_MODE_B);

  end

if(RAM_MODE == "SDP" && READ_WIDTH_A > 36) begin
    localparam EFF_READ_WIDTH_A = 36;
    localparam EFF_READ_WIDTH_B = 36;
end else begin
    localparam EFF_READ_WIDTH_A = READ_WIDTH_A;
    localparam EFF_READ_WIDTH_B = READ_WIDTH_B;
end

if(RAM_MODE == "SDP" && WRITE_WIDTH_B > 36) begin
    localparam EFF_WRITE_WIDTH_A = 36;
    localparam EFF_WRITE_WIDTH_B = 36;
end else begin
    localparam EFF_WRITE_WIDTH_A = WRITE_WIDTH_A;
    localparam EFF_WRITE_WIDTH_B = WRITE_WIDTH_B;
end

  wire REGCLKA;
  wire REGCLKB;

  if (DOA_REG) begin
      assign REGCLKA = CLKARDCLK;
      localparam ZINV_REGCLKARDRCLK = !IS_CLKARDCLK_INVERTED;
  end else begin
      assign REGCLKA = 1'b0;
      localparam ZINV_REGCLKARDRCLK = 1'b0;
  end

  if (DOB_REG) begin
      assign REGCLKB = CLKBWRCLK;
      localparam ZINV_REGCLKB = !IS_CLKBWRCLK_INVERTED;
  end else begin
      assign REGCLKB = 1'b0;
      localparam ZINV_REGCLKB = 1'b0;
  end

  RAMB36E1_PRIM #(
      .IN_USE(READ_WIDTH_A != 0 || READ_WIDTH_B != 0 || WRITE_WIDTH_A != 0 || WRITE_WIDTH_B != 0),

      .ZINIT_A(INIT_A ^ {36{1'b1}}),
      .ZINIT_B(INIT_B ^ {36{1'b1}}),

      .ZSRVAL_A(SRVAL_A ^ {36{1'b1}}),
      .ZSRVAL_B(SRVAL_B ^ {36{1'b1}}),

      `define INIT_PARAM_BLOCK_L(pre, n, d, upper) \
      .``pre``_``n``0(every_other_bit({``pre``_``d``1, ``pre``_``d``0}, upper)), \
      .``pre``_``n``1(every_other_bit({``pre``_``d``3, ``pre``_``d``2}, upper)), \
      .``pre``_``n``2(every_other_bit({``pre``_``d``5, ``pre``_``d``4}, upper)), \
      .``pre``_``n``3(every_other_bit({``pre``_``d``7, ``pre``_``d``6}, upper)), \
      .``pre``_``n``4(every_other_bit({``pre``_``d``9, ``pre``_``d``8}, upper)), \
      .``pre``_``n``5(every_other_bit({``pre``_``d``B, ``pre``_``d``A}, upper)), \
      .``pre``_``n``6(every_other_bit({``pre``_``d``D, ``pre``_``d``C}, upper)), \
      .``pre``_``n``7(every_other_bit({``pre``_``d``F, ``pre``_``d``E}, upper))

      `define INIT_PARAM_BLOCK_H(pre, n, d, upper) \
      .``pre``_``n``8(every_other_bit({``pre``_``d``1, ``pre``_``d``0}, upper)), \
      .``pre``_``n``9(every_other_bit({``pre``_``d``3, ``pre``_``d``2}, upper)), \
      .``pre``_``n``A(every_other_bit({``pre``_``d``5, ``pre``_``d``4}, upper)), \
      .``pre``_``n``B(every_other_bit({``pre``_``d``7, ``pre``_``d``6}, upper)), \
      .``pre``_``n``C(every_other_bit({``pre``_``d``9, ``pre``_``d``8}, upper)), \
      .``pre``_``n``D(every_other_bit({``pre``_``d``B, ``pre``_``d``A}, upper)), \
      .``pre``_``n``E(every_other_bit({``pre``_``d``D, ``pre``_``d``C}, upper)), \
      .``pre``_``n``F(every_other_bit({``pre``_``d``F, ``pre``_``d``E}, upper))

      `define INIT_PARAM_BLOCK(pre, n, lo, hi, upper) \
      `INIT_PARAM_BLOCK_L(pre, n, lo, upper), \
      `INIT_PARAM_BLOCK_H(pre, n, hi, upper)

      `INIT_PARAM_BLOCK_L(INITP, 0, 0, 0),
      `INIT_PARAM_BLOCK_H(INITP, 0, 0, 1),
      `INIT_PARAM_BLOCK(INIT, 0, 0, 1, 0),
      `INIT_PARAM_BLOCK(INIT, 1, 2, 3, 0),
      `INIT_PARAM_BLOCK(INIT, 2, 4, 5, 0),
      `INIT_PARAM_BLOCK(INIT, 3, 6, 7, 0),
      `INIT_PARAM_BLOCK(INIT, 4, 0, 1, 1),
      `INIT_PARAM_BLOCK(INIT, 5, 2, 3, 1),
      `INIT_PARAM_BLOCK(INIT, 6, 4, 5, 1),
      `INIT_PARAM_BLOCK(INIT, 7, 6, 7, 1),

      `undef INIT_PARAM_BLOCK_L
      `undef INIT_PARAM_BLOCK_H
      `undef INIT_PARAM_BLOCK

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

      `define WIDTH_PARAM(name) \
      .``name``_1(EFF_``name`` == 2 || EFF_``name`` == 1 || EFF_``name`` == 0), \
      .``name``_2(EFF_``name`` == 4), \
      .``name``_4(EFF_``name`` == 9), \
      .``name``_9(EFF_``name`` == 18), \
      .``name``_18(EFF_``name`` == 36)

      `WIDTH_PARAM(READ_WIDTH_A),
      .SDP_READ_WIDTH_36(READ_WIDTH_A > 36),
      `WIDTH_PARAM(READ_WIDTH_B),
      `WIDTH_PARAM(WRITE_WIDTH_A),
      `WIDTH_PARAM(WRITE_WIDTH_B),
      `undef WIDTH_PARAM

      .SDP_WRITE_WIDTH_36(WRITE_WIDTH_B > 36),
      .WRITE_MODE_A_NO_CHANGE(WRITE_MODE_A == "NO_CHANGE" || (WRITE_MODE_A == "WRITE_FIRST" && RAM_MODE == "SDP")),
      .WRITE_MODE_A_READ_FIRST(WRITE_MODE_A == "READ_FIRST"),
      .WRITE_MODE_B_NO_CHANGE(WRITE_MODE_B == "NO_CHANGE" || (WRITE_MODE_B == "WRITE_FIRST" && RAM_MODE == "SDP")),
      .WRITE_MODE_B_READ_FIRST(WRITE_MODE_B == "READ_FIRST"),
      .RSTREG_PRIORITY_A_RSTREG(1'b1),
      .RSTREG_PRIORITY_B_RSTREG(1'b1),
      .RAM_EXTENSION_A_NONE_OR_UPPER(1'b1),
      .RAM_EXTENSION_B_NONE_OR_UPPER(1'b1),
      .RDADDR_COLLISION_HWCONFIG_DELAYED_WRITE(1'b1),
      .ZALMOST_EMPTY_OFFSET(13'b1111111111111),
      .ZALMOST_FULL_OFFSET(13'b1111111111111)
  ) _TECHMAP_REPLACE_ (
    `define DUP(pre, in) .``pre``U(in), .``pre``L(in)
    `DUP(CLKARDCLK, CLKARDCLK),
    `DUP(REGCLKARDRCLK, REGCLKA),
    `DUP(CLKBWRCLK, CLKBWRCLK ^ INV_CLKBWRCLK),
    `DUP(REGCLKB, REGCLKB),
    `DUP(ENARDEN, ENARDEN),
    `DUP(ENBWREN, ENBWREN),
    `DUP(REGCEAREGCE, REGCEAREGCE),
    `DUP(REGCEB, REGCEB),
    .RSTRAMARSTRAMU(RSTRAMARSTRAM ^ INV_RSTRAMARSTRAM),
    .RSTRAMARSTRAMLRST(RSTRAMARSTRAM ^ INV_RSTRAMARSTRAM),
    `DUP(RSTRAMB, RSTRAMB ^ INV_RSTRAMB),
    `DUP(RSTREGARSTREG, RSTREGARSTREG ^ INV_RSTREGARSTREG),
    `DUP(RSTREGB, RSTREGB ^ INV_RSTREGB),
    .ADDRARDADDRU(ADDRARDADDR),
    .ADDRARDADDRL({1'b1, ADDRARDADDR}),
    .ADDRBWRADDRU(ADDRBWRADDR),
    .ADDRBWRADDRL({1'b1, ADDRBWRADDR}),
    .DIADI(DIADI),
    .DIBDI(DIBDI),
    .DIPADIP(DIPADIP),
    .DIPBDIP(DIPBDIP),
    `DUP(WEA, WEA),
    `DUP(WEBWE, WEBWE),

    .DOADO(DOADO),
    .DOBDO(DOBDO),
    .DOPADOP(DOPADOP),
    .DOPBDOP(DOPBDOP)
    `undef DUP
  );
endmodule // RAMB36E1

module CARRY_COUT_PLUG(input CIN, output COUT);

assign COUT = CIN;

endmodule

module CARRY4_COUT(output [3:0] CO, O, output COUT, input CI, CYINIT, input [3:0] DI, S);
  parameter _TECHMAP_CONSTMSK_CI_ = 1;
  parameter _TECHMAP_CONSTVAL_CI_ = 1'b0;
  parameter _TECHMAP_CONSTMSK_CYINIT_ = 1;
  parameter _TECHMAP_CONSTVAL_CYINIT_ = 1'b0;

  localparam [0:0] IS_CI_ZERO = (
      _TECHMAP_CONSTMSK_CI_ == 1 && _TECHMAP_CONSTVAL_CI_ == 0 &&
      _TECHMAP_CONSTMSK_CYINIT_ == 1 && _TECHMAP_CONSTVAL_CYINIT_ == 0);
  localparam [0:0] IS_CI_ONE = (
      _TECHMAP_CONSTMSK_CI_ == 1 && _TECHMAP_CONSTVAL_CI_ == 0 &&
      _TECHMAP_CONSTMSK_CYINIT_ == 1 && _TECHMAP_CONSTVAL_CYINIT_ == 1);
  localparam [0:0] IS_CYINIT_FABRIC = _TECHMAP_CONSTMSK_CYINIT_ == 0;
  localparam [0:0] IS_CI_DISCONNECTED = _TECHMAP_CONSTMSK_CI_ == 1 &&
    _TECHMAP_CONSTVAL_CI_ != 1;
  localparam [0:0] IS_CYINIT_DISCONNECTED = _TECHMAP_CONSTMSK_CYINIT_ == 1 &&
    _TECHMAP_CONSTVAL_CYINIT_ != 1;

  wire [1023:0] _TECHMAP_DO_ = "proc; clean";

  if(IS_CYINIT_FABRIC) begin
    CARRY4_VPR #(
        .CYINIT_AX(1'b1),
        .CYINIT_C0(1'b0),
        .CYINIT_C1(1'b0)
    ) _TECHMAP_REPLACE_ (
        .CO_CHAIN(COUT),
        .CO_FABRIC0(CO[0]),
        .CO_FABRIC1(CO[1]),
        .CO_FABRIC2(CO[2]),
        .CO_FABRIC3(CO[3]),
        .O0(O[0]),
        .O1(O[1]),
        .O2(O[2]),
        .O3(O[3]),
        .CYINIT(CYINIT),
        .DI0(DI[0]),
        .DI1(DI[1]),
        .DI2(DI[2]),
        .DI3(DI[3]),
        .S0(S[0]),
        .S1(S[1]),
        .S2(S[2]),
        .S3(S[3])
    );
  end else if(IS_CI_ZERO || IS_CI_ONE) begin
    CARRY4_VPR #(
        .CYINIT_AX(1'b0),
        .CYINIT_C0(IS_CI_ZERO),
        .CYINIT_C1(IS_CI_ONE)
    ) _TECHMAP_REPLACE_ (
        .CO_CHAIN(COUT),
        .CO_FABRIC0(CO[0]),
        .CO_FABRIC1(CO[1]),
        .CO_FABRIC2(CO[2]),
        .CO_FABRIC3(CO[3]),
        .O0(O[0]),
        .O1(O[1]),
        .O2(O[2]),
        .O3(O[3]),
        .DI0(DI[0]),
        .DI1(DI[1]),
        .DI2(DI[2]),
        .DI3(DI[3]),
        .S0(S[0]),
        .S1(S[1]),
        .S2(S[2]),
        .S3(S[3])
    );
  end else begin
    CARRY4_VPR #(
        .CYINIT_AX(1'b0),
        .CYINIT_C0(1'b0),
        .CYINIT_C1(1'b0)
    ) _TECHMAP_REPLACE_ (
        .CO_CHAIN(COUT),
        .CO_FABRIC0(CO[0]),
        .CO_FABRIC1(CO[1]),
        .CO_FABRIC2(CO[2]),
        .CO_FABRIC3(CO[3]),
        .O0(O[0]),
        .O1(O[1]),
        .O2(O[2]),
        .O3(O[3]),
        .DI0(DI[0]),
        .DI1(DI[1]),
        .DI2(DI[2]),
        .DI3(DI[3]),
        .S0(S[0]),
        .S1(S[1]),
        .S2(S[2]),
        .S3(S[3]),
        .CIN(CI)
    );
  end
endmodule

// ============================================================================
// SRLs

module SRLC32E (
  output Q,
  output Q31,
  input [4:0] A,
  input CE, CLK, D
);
  parameter [31:0] INIT = 32'h00000000;
  parameter [0:0] IS_CLK_INVERTED = 1'b0;

  // Duplicate bits of the init parameter to match the actual INIT data
  // representation.
  function [63:0] duplicate_bits;
    input [31:0] bits;
    integer i;
    begin
      for (i=0; i<32; i=i+1) begin
        duplicate_bits[2*i+0] = bits[i];
        duplicate_bits[2*i+1] = bits[i];
      end
    end
  endfunction

  localparam [63:0] INIT_VPR = duplicate_bits(INIT);

  // Substitute
  SRLC32E_VPR #
  (
  .INIT(INIT_VPR)
  )
  _TECHMAP_REPLACE_
  (
  .CLK(CLK),
  .CE(CE),
  .A(A),
  .D(D),
  .Q(Q),
  .Q31(Q31)
  );

endmodule

module SRL16E (
  output Q,
  input A0, A1, A2, A3,
  input CE, CLK, D
);
  parameter [15:0] INIT = 16'h0000;
  parameter [ 0:0] IS_CLK_INVERTED = 1'b0;

  // Duplicate bits of the init parameter to match the actual INIT data
  // representation.
  function [31:0] duplicate_bits;
    input [15:0] bits;
    integer i;
    begin
      for (i=0; i<15; i=i+1) begin
        duplicate_bits[2*i+0] = bits[i];
        duplicate_bits[2*i+1] = bits[i];
      end
    end
  endfunction

  localparam [31:0] INIT_VPR = duplicate_bits(INIT);

  // Substitute
  SRLC16E_VPR #
  (
  .INIT(INIT_VPR)
  )
  _TECHMAP_REPLACE_
  (
  .CLK(CLK),
  .CE(CE),
  .A0(A0),
  .A1(A1),
  .A2(A2),
  .A3(A3),
  .D(D),
  .Q(Q),
  .Q15()
  );

endmodule

