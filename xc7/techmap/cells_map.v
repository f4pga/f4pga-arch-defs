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

function [31:0] every_other_bit_32;
   input [63:0] in;
   input         odd;
   integer       i;
   for (i = 0; i < 32; i = i + 1) begin
      every_other_bit_32[i] = in[i * 2 + odd];
   end
endfunction


    DPRAM32 #(
        .INIT_00(every_other_bit_32(INIT_A, 1'b1)),
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
        .INIT_00(every_other_bit_32(INIT_A, 1'b0)),
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
        .INIT_00(every_other_bit_32(INIT_B, 1'b1)),
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
        .INIT_00(every_other_bit_32(INIT_B, 1'b0)),
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
        .INIT_00(every_other_bit_32(INIT_C, 1'b1)),
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
        .INIT_00(every_other_bit_32(INIT_C, 1'b0)),
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
        .INIT_00(every_other_bit_32(INIT_D, 1'b1)),
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
        .INIT_00(every_other_bit_32(INIT_D, 0)),
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

    parameter _TECHMAP_CONSTMSK_CLKARDCLK_ = 0;
    parameter _TECHMAP_CONSTVAL_CLKARDCLK_ = 0;
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

  localparam INV_CLKARDCLK = (
      _TECHMAP_CONSTMSK_CLKARDCLK_ == 1 &&
      _TECHMAP_CONSTVAL_CLKARDCLK_ == 0 &&
      IS_CLKARDCLK_INVERTED == 0);
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
    localparam EFF_READ_WIDTH_A = 1;
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

      .ZINV_CLKARDCLK(!IS_CLKARDCLK_INVERTED ^ INV_CLKARDCLK),
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
    .CLKARDCLK(CLKARDCLK ^ INV_CLKARDCLK),
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

function [255:0] every_other_bit_256;
   input [511:0] in;
   input         odd;
   integer       i;
   for (i = 0; i < 256; i = i + 1) begin
      every_other_bit_256[i] = in[i * 2 + odd];
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

    parameter _TECHMAP_CONSTMSK_CLKARDCLK_ = 0;
    parameter _TECHMAP_CONSTVAL_CLKARDCLK_ = 0;
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

  localparam INV_CLKARDCLK = (
      _TECHMAP_CONSTMSK_CLKARDCLK_ == 1 &&
      _TECHMAP_CONSTVAL_CLKARDCLK_ == 0 &&
      IS_CLKARDCLK_INVERTED == 0);
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
    localparam EFF_READ_WIDTH_A = 1;
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

  wire [7:0] WEBWE_WIDE;
  wire [3:0] WEA_WIDE;

  if(WRITE_WIDTH_A < 18) begin
      assign WEA_WIDE = {4{WEA[0]}};
  end else if(WRITE_WIDTH_A == 18) begin
      assign WEA_WIDE[3:2] = {2{WEA[1]}};
      assign WEA_WIDE[1:0] = {2{WEA[0]}};
  end else if(WRITE_WIDTH_A == 36) begin
      assign WEA_WIDE = WEA;
  end

  if(WRITE_WIDTH_B < 18) begin
      assign WEBWE_WIDE[7:4] = 4'b0;
      assign WEBWE_WIDE[3:0] = {4{WEBWE[0]}};
  end else if(WRITE_WIDTH_B == 18) begin
      assign WEBWE_WIDE[7:4] = 4'b0;
      assign WEBWE_WIDE[3:2] = {2{WEBWE[1]}};
      assign WEBWE_WIDE[1:0] = {2{WEBWE[0]}};
  end else if(WRITE_WIDTH_B == 36) begin
      assign WEBWE_WIDE = WEBWE;
  end else if(WRITE_WIDTH_B == 72) begin
      assign WEA_WIDE = 4'b0;
      assign WEBWE_WIDE = WEBWE;
  end

  RAMB36E1_PRIM #(
      .IN_USE(READ_WIDTH_A != 0 || READ_WIDTH_B != 0 || WRITE_WIDTH_A != 0 || WRITE_WIDTH_B != 0),

      .ZINIT_A(INIT_A ^ {36{1'b1}}),
      .ZINIT_B(INIT_B ^ {36{1'b1}}),

      .ZSRVAL_A(SRVAL_A ^ {36{1'b1}}),
      .ZSRVAL_B(SRVAL_B ^ {36{1'b1}}),

      `define INIT_PARAM_BLOCK_L(pre, n, d, upper) \
      .``pre``_``n``0(every_other_bit_256({``pre``_``d``1, ``pre``_``d``0}, upper)), \
      .``pre``_``n``1(every_other_bit_256({``pre``_``d``3, ``pre``_``d``2}, upper)), \
      .``pre``_``n``2(every_other_bit_256({``pre``_``d``5, ``pre``_``d``4}, upper)), \
      .``pre``_``n``3(every_other_bit_256({``pre``_``d``7, ``pre``_``d``6}, upper)), \
      .``pre``_``n``4(every_other_bit_256({``pre``_``d``9, ``pre``_``d``8}, upper)), \
      .``pre``_``n``5(every_other_bit_256({``pre``_``d``B, ``pre``_``d``A}, upper)), \
      .``pre``_``n``6(every_other_bit_256({``pre``_``d``D, ``pre``_``d``C}, upper)), \
      .``pre``_``n``7(every_other_bit_256({``pre``_``d``F, ``pre``_``d``E}, upper))

      `define INIT_PARAM_BLOCK_H(pre, n, d, upper) \
      .``pre``_``n``8(every_other_bit_256({``pre``_``d``1, ``pre``_``d``0}, upper)), \
      .``pre``_``n``9(every_other_bit_256({``pre``_``d``3, ``pre``_``d``2}, upper)), \
      .``pre``_``n``A(every_other_bit_256({``pre``_``d``5, ``pre``_``d``4}, upper)), \
      .``pre``_``n``B(every_other_bit_256({``pre``_``d``7, ``pre``_``d``6}, upper)), \
      .``pre``_``n``C(every_other_bit_256({``pre``_``d``9, ``pre``_``d``8}, upper)), \
      .``pre``_``n``D(every_other_bit_256({``pre``_``d``B, ``pre``_``d``A}, upper)), \
      .``pre``_``n``E(every_other_bit_256({``pre``_``d``D, ``pre``_``d``C}, upper)), \
      .``pre``_``n``F(every_other_bit_256({``pre``_``d``F, ``pre``_``d``E}, upper))

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

      .ZINV_CLKARDCLK(!IS_CLKARDCLK_INVERTED ^ INV_CLKARDCLK),
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
    `DUP(CLKARDCLK, CLKARDCLK ^ INV_CLKARDCLK),
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
    `DUP(WEA, WEA_WIDE),
    `DUP(WEBWE, WEBWE_WIDE),

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

// The following three techmaps map SRLC32E, SRLC16E and SRL16E to their VPR
// counterparts.
//
// The initialization data for VPR SRLs need to have each bit duplicated and
// this is what these techmaps do. For now there is no support for CLK inversion
// as it is slice wide so the parameters is only there for compatibility.
//
// SRLC32E and SRLC16E are mapped directly to SRLC32E_VPR and SRLC16E_VPR
// respectively. Both of those primitives have Q31 (or Q15) outputs which
// correspond to the MC31 output of the physical bel. SRL16E does not
// provide that output hence it is mapped to SRLC16E with Q15 disconnected.
// It is then mapped to SRLC16E_VPR later on.

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

module SRLC16E (
  output Q, Q15,
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
  .Q15(Q15)
  );

endmodule

module SRL16E (
  output Q,
  input A0, A1, A2, A3,
  input CE, CLK, D
);
  parameter [15:0] INIT = 16'h0000;
  parameter [ 0:0] IS_CLK_INVERTED = 1'b0;

  // Substitute with Q15 disconnected.
  SRLC16E #
  (
  .INIT(INIT),
  .IS_CLK_INVERTED(IS_CLK_INVERTED)
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

// ============================================================================
// IO

module IBUF (
  input I,
  output O
  );

   INBUF_VPR _TECHMAP_REPLACE_ (
     .PAD(I),
     .OUT(O)
   );

endmodule

module OBUF (
  input I,
  output O
  );

   OUTBUF_VPR _TECHMAP_REPLACE_ (
     .IN(I),
     .OUT(O)
   );

endmodule

module IOBUF (
  input  I,
  input  T,
  output O,
  inout  IO
);

  IOBUF_VPR _TECHMAP_REPLACE_ (
    .I(I),
    .T(T),
    .O(O),
    .IOPAD_$inp(IO),
    .IOPAD_$out(IO)
  );

endmodule

// ============================================================================
// I/OSERDES

module OSERDESE2 (
  input CLK,
  input CLKDIV,
  input D1,
  input D2,
  input D3,
  input D4,
  input D5,
  input D6,
  input D7,
  input D8,
  input OCE,
  input RST,
  input T1,
  input T2,
  input T3,
  input T4,
  input TCE,
  output OFB,
  output OQ,
  output TFB,
  output TQ
  );

  parameter DATA_RATE_OQ = "DDR";
  parameter DATA_RATE_TQ = "DDR";
  parameter DATA_WIDTH = 4;
  parameter SERDES_MODE = "MASTER";
  parameter TRISTATE_WIDTH = 4;

  if (DATA_RATE_OQ == "DDR" &&
      !(DATA_WIDTH == 2 || DATA_WIDTH == 4 ||
        DATA_WIDTH == 6 || DATA_WIDTH == 8)) begin
    wire _TECHMAP_FAIL_ = 1'b1;
  end

  if (DATA_RATE_OQ == "SDR" &&
      !(DATA_WIDTH >= 2 || DATA_WIDTH <= 8)) begin
    wire _TECHMAP_FAIL_ = 1'b1;
  end

  if ((DATA_RATE_TQ == "SDR" || DATA_RATE_TQ == "BUF") &&
      TRISTATE_WIDTH != 1) begin
    wire _TECHMAP_FAIL_ = 1'b1;
  end

  if (DATA_RATE_OQ == "SDR" && DATA_RATE_TQ == "DDR") begin
    wire _TECHMAP_FAIL_ = 1'b1;
  end

  if (TRISTATE_WIDTH != 1 && TRISTATE_WIDTH != 4) begin
    wire _TECHMAP_FAIL_ = 1'b1;
  end

  localparam [0:0] DATA_WIDTH_DDR_W6_8 = DATA_RATE_OQ == "DDR" && (DATA_WIDTH == 6 || DATA_WIDTH == 8) ? 1'b1 : 1'b0;
  localparam [0:0] DATA_WIDTH_SDR_W2_4_5_6 = DATA_RATE_OQ == "SDR" &&
                                             (DATA_WIDTH == 2 || DATA_WIDTH == 4 ||
                                              DATA_WIDTH == 5 || DATA_WIDTH == 6) ? 1'b1 : 1'b0;

  // Inverter parameters
  parameter [0:0] IS_D1_INVERTED = 1'b0;
  parameter [0:0] IS_D2_INVERTED = 1'b0;
  parameter [0:0] IS_D3_INVERTED = 1'b0;
  parameter [0:0] IS_D4_INVERTED = 1'b0;
  parameter [0:0] IS_D5_INVERTED = 1'b0;
  parameter [0:0] IS_D6_INVERTED = 1'b0;
  parameter [0:0] IS_D7_INVERTED = 1'b0;
  parameter [0:0] IS_D8_INVERTED = 1'b0;
  parameter [0:0] IS_CLKDIV_INVERTED = 1'b0;

  parameter [0:0] IS_CLK_INVERTED = 1'b0;
  parameter [0:0] IS_T1_INVERTED = 1'b0;
  parameter [0:0] IS_T2_INVERTED = 1'b0;
  parameter [0:0] IS_T3_INVERTED = 1'b0;
  parameter [0:0] IS_T4_INVERTED = 1'b0;

  localparam [0:0] INIT_OQ = 1'b0;
  localparam [0:0] INIT_TQ = 1'b0;
  localparam [0:0] SRVAL_OQ = 1'b0;
  localparam [0:0] SRVAL_TQ = 1'b0;

  parameter _TECHMAP_CONSTMSK_D1_ = 0;
  parameter _TECHMAP_CONSTVAL_D1_ = 0;
  parameter _TECHMAP_CONSTMSK_D2_ = 0;
  parameter _TECHMAP_CONSTVAL_D2_ = 0;
  parameter _TECHMAP_CONSTMSK_D3_ = 0;
  parameter _TECHMAP_CONSTVAL_D3_ = 0;
  parameter _TECHMAP_CONSTMSK_D4_ = 0;
  parameter _TECHMAP_CONSTVAL_D4_ = 0;
  parameter _TECHMAP_CONSTMSK_D5_ = 0;
  parameter _TECHMAP_CONSTVAL_D5_ = 0;
  parameter _TECHMAP_CONSTMSK_D6_ = 0;
  parameter _TECHMAP_CONSTVAL_D6_ = 0;
  parameter _TECHMAP_CONSTMSK_D7_ = 0;
  parameter _TECHMAP_CONSTVAL_D7_ = 0;
  parameter _TECHMAP_CONSTMSK_D8_ = 0;
  parameter _TECHMAP_CONSTVAL_D8_ = 0;

  localparam [0:0] INV_D1 = (
      _TECHMAP_CONSTMSK_D1_ == 1 &&
      _TECHMAP_CONSTVAL_D1_ == 0 &&
      IS_D1_INVERTED == 0);
  localparam [0:0] INV_D2 = (
      _TECHMAP_CONSTMSK_D2_ == 1 &&
      _TECHMAP_CONSTVAL_D2_ == 0 &&
      IS_D2_INVERTED == 0);
  localparam [0:0] INV_D3 = (
      _TECHMAP_CONSTMSK_D3_ == 1 &&
      _TECHMAP_CONSTVAL_D3_ == 0 &&
      IS_D3_INVERTED == 0);
  localparam [0:0] INV_D4 = (
      _TECHMAP_CONSTMSK_D4_ == 1 &&
      _TECHMAP_CONSTVAL_D4_ == 0 &&
      IS_D4_INVERTED == 0);
  localparam [0:0] INV_D5 = (
      _TECHMAP_CONSTMSK_D5_ == 1 &&
      _TECHMAP_CONSTVAL_D5_ == 0 &&
      IS_D5_INVERTED == 0);
  localparam [0:0] INV_D6 = (
      _TECHMAP_CONSTMSK_D6_ == 1 &&
      _TECHMAP_CONSTVAL_D6_ == 0 &&
      IS_D6_INVERTED == 0);
  localparam [0:0] INV_D7 = (
      _TECHMAP_CONSTMSK_D7_ == 1 &&
      _TECHMAP_CONSTVAL_D7_ == 0 &&
      IS_D7_INVERTED == 0);
  localparam [0:0] INV_D8 = (
      _TECHMAP_CONSTMSK_D8_ == 1 &&
      _TECHMAP_CONSTVAL_D8_ == 0 &&
      IS_D8_INVERTED == 0);

  OSERDESE2_VPR #(
      .SERDES_MODE_SLAVE            (SERDES_MODE == "SLAVE"),
      .TRISTATE_WIDTH_W4            (TRISTATE_WIDTH == 4),
      .DATA_RATE_OQ_DDR             (DATA_RATE_OQ == "DDR"),
      .DATA_RATE_OQ_SDR             (DATA_RATE_OQ == "SDR"),
      .DATA_RATE_TQ_BUF             (DATA_RATE_TQ == "BUF"),
      .DATA_RATE_TQ_DDR             (DATA_RATE_TQ == "DDR"),
      .DATA_RATE_TQ_SDR             (DATA_RATE_TQ == "SDR"),
      .DATA_WIDTH_DDR_W6_8          (DATA_WIDTH_DDR_W6_8),
      .DATA_WIDTH_SDR_W2_4_5_6      (DATA_WIDTH_SDR_W2_4_5_6),
      .DATA_WIDTH_W2                (DATA_WIDTH == 2),
      .DATA_WIDTH_W3                (DATA_WIDTH == 3),
      .DATA_WIDTH_W4                (DATA_WIDTH == 4),
      .DATA_WIDTH_W5                (DATA_WIDTH == 5),
      .DATA_WIDTH_W6                (DATA_WIDTH == 6),
      .DATA_WIDTH_W7                (DATA_WIDTH == 7),
      .DATA_WIDTH_W8                (DATA_WIDTH == 8),
      .ZINIT_OQ                     (!INIT_OQ),
      .ZINIT_TQ                     (!INIT_TQ),
      .ZSRVAL_OQ                    (!SRVAL_OQ),
      .ZSRVAL_TQ                    (!SRVAL_TQ),
      .IS_CLKDIV_INVERTED           (IS_CLKDIV_INVERTED),
      .IS_D1_INVERTED               (IS_D1_INVERTED ^ INV_D1),
      .IS_D2_INVERTED               (IS_D2_INVERTED ^ INV_D2),
      .IS_D3_INVERTED               (IS_D3_INVERTED ^ INV_D3),
      .IS_D4_INVERTED               (IS_D4_INVERTED ^ INV_D4),
      .IS_D5_INVERTED               (IS_D5_INVERTED ^ INV_D5),
      .IS_D6_INVERTED               (IS_D6_INVERTED ^ INV_D6),
      .IS_D7_INVERTED               (IS_D7_INVERTED ^ INV_D7),
      .IS_D8_INVERTED               (IS_D8_INVERTED ^ INV_D8),
      .ZINV_CLK                     (!IS_CLK_INVERTED),
      .ZINV_T1                      (IS_T1_INVERTED),
      .ZINV_T2                      (IS_T2_INVERTED),
      .ZINV_T3                      (IS_T3_INVERTED),
      .ZINV_T4                      (IS_T4_INVERTED)
  ) _TECHMAP_REPLACE_ (
    .CLK    (CLK),
    .CLKDIV (CLKDIV),
    .D1     (D1),
    .D2     (D2),
    .D3     (D3),
    .D4     (D4),
    .D5     (D5),
    .D6     (D6),
    .D7     (D7),
    .D8     (D8),
    .OCE    (OCE),
    .RST    (RST),
    .T1     (T1),
    .T2     (T2),
    .T3     (T3),
    .T4     (T4),
    .TCE    (TCE),
    .OFB    (OFB),
    .OQ     (OQ),
    .TFB    (TFB),
    .TQ     (TQ)
  );

endmodule

// ============================================================================
// Clock Buffers

module BUFG (
  input I,
  output O
  );

  BUFGCTRL _TECHMAP_REPLACE_ (
    .O(O),
    .CE0(1'b1),
    .CE1(1'b0),
    .I0(I),
    .I1(1'b1),
    .IGNORE0(1'b0),
    .IGNORE1(1'b1),
    .S0(1'b1),
    .S1(1'b0)
  );
endmodule

module BUFGCTRL (
output O,
input I0, input I1,
input S0, input S1,
input CE0, input CE1,
input IGNORE0, input IGNORE1
);

  parameter [0:0] INIT_OUT = 1'b0;
  parameter [0:0] PRESELECT_I0 = 1'b0;
  parameter [0:0] PRESELECT_I1 = 1'b0;
  parameter [0:0] IS_IGNORE0_INVERTED = 1'b0;
  parameter [0:0] IS_IGNORE1_INVERTED = 1'b0;
  parameter [0:0] IS_CE0_INVERTED = 1'b0;
  parameter [0:0] IS_CE1_INVERTED = 1'b0;
  parameter [0:0] IS_S0_INVERTED = 1'b0;
  parameter [0:0] IS_S1_INVERTED = 1'b0;

  parameter _TECHMAP_CONSTMSK_IGNORE0_ = 0;
  parameter _TECHMAP_CONSTVAL_IGNORE0_ = 0;
  parameter _TECHMAP_CONSTMSK_IGNORE1_ = 0;
  parameter _TECHMAP_CONSTVAL_IGNORE1_ = 0;
  parameter _TECHMAP_CONSTMSK_CE0_ = 0;
  parameter _TECHMAP_CONSTVAL_CE0_ = 0;
  parameter _TECHMAP_CONSTMSK_CE1_ = 0;
  parameter _TECHMAP_CONSTVAL_CE1_ = 0;
  parameter _TECHMAP_CONSTMSK_S0_ = 0;
  parameter _TECHMAP_CONSTVAL_S0_ = 0;
  parameter _TECHMAP_CONSTMSK_S1_ = 0;
  parameter _TECHMAP_CONSTVAL_S1_ = 0;

  localparam [0:0] INV_IGNORE0 = (
      _TECHMAP_CONSTMSK_IGNORE0_ == 1 &&
      _TECHMAP_CONSTVAL_IGNORE0_ == 0 &&
      IS_IGNORE0_INVERTED == 0);
  localparam [0:0] INV_IGNORE1 = (
      _TECHMAP_CONSTMSK_IGNORE1_ == 1 &&
      _TECHMAP_CONSTVAL_IGNORE1_ == 0 &&
      IS_IGNORE1_INVERTED == 0);
  localparam [0:0] INV_CE0 = (
      _TECHMAP_CONSTMSK_CE0_ == 1 &&
      _TECHMAP_CONSTVAL_CE0_ == 0 &&
      IS_CE0_INVERTED == 0);
  localparam [0:0] INV_CE1 = (
      _TECHMAP_CONSTMSK_CE1_ == 1 &&
      _TECHMAP_CONSTVAL_CE1_ == 0 &&
      IS_CE1_INVERTED == 0);
  localparam [0:0] INV_S0 = (
      _TECHMAP_CONSTMSK_S0_ == 1 &&
      _TECHMAP_CONSTVAL_S0_ == 0 &&
      IS_S0_INVERTED == 0);
  localparam [0:0] INV_S1 = (
      _TECHMAP_CONSTMSK_S1_ == 1 &&
      _TECHMAP_CONSTVAL_S1_ == 0 &&
      IS_S1_INVERTED == 0);

  BUFGCTRL_VPR #(
      .INIT_OUT(INIT_OUT),
      .ZPRESELECT_I0(PRESELECT_I0),
      .ZPRESELECT_I1(PRESELECT_I1),
      .IS_IGNORE0_INVERTED(!IS_IGNORE0_INVERTED ^ INV_IGNORE0),
      .IS_IGNORE1_INVERTED(!IS_IGNORE1_INVERTED ^ INV_IGNORE1),
      .ZINV_CE0(!IS_CE0_INVERTED ^ INV_CE0),
      .ZINV_CE1(!IS_CE1_INVERTED ^ INV_CE1),
      .ZINV_S0(!IS_S0_INVERTED ^ INV_S0),
      .ZINV_S1(!IS_S1_INVERTED ^ INV_S1)
  ) _TECHMAP_REPLACE_ (
    .O(O),
    .CE0(CE0 ^ INV_CE0),
    .CE1(CE1 ^ INV_CE1),
    .I0(I0),
    .I1(I1),
    .IGNORE0(IGNORE0 ^ INV_IGNORE0),
    .IGNORE1(IGNORE1 ^ INV_IGNORE1),
    .S0(S0 ^ INV_S0),
    .S1(S1 ^ INV_S1)
  );

endmodule

module BUFH (
  input I,
  output O
  );

  BUFHCE _TECHMAP_REPLACE_ (
    .O(O),
    .I(I),
    .CE(1)
  );
endmodule

module BUFHCE (
  input I,
  input CE,
  output O
  );

  parameter [0:0] INIT_OUT = 1'b0;
  parameter [0:0] IS_CE_INVERTED = 1'b0;

  parameter [0:0] _TECHMAP_CONSTMSK_CE_ = 0;
  parameter [0:0] _TECHMAP_CONSTVAL_CE_ = 0;

  localparam [0:0] INV_CE = (
      _TECHMAP_CONSTMSK_CE_ == 1 &&
      _TECHMAP_CONSTVAL_CE_ == 0 &&
      IS_CE_INVERTED == 0);

  BUFHCE_VPR #(
      .INIT_OUT(INIT_OUT),
      .ZINV_CE(!IS_CE_INVERTED ^ INV_CE)
  ) _TECHMAP_REPLACE_ (
  .O(O),
  .I(I),
  .CE(CE)
  );

endmodule

// ============================================================================
// CMT

`define PLL_FRAC_PRECISION  10
`define PLL_FIXED_WIDTH     32

// Rounds a fixed point number to a given precision
function [`PLL_FIXED_WIDTH:1] pll_round_frac
(
input [`PLL_FIXED_WIDTH:1] decimal,
input [`PLL_FIXED_WIDTH:1] precision
);

 if (decimal[(`PLL_FRAC_PRECISION - precision)] == 1'b1) begin
   pll_round_frac = decimal + (1'b1 << (`PLL_FRAC_PRECISION - precision));
 end else begin
   pll_round_frac = decimal;
 end

endfunction

// Computes content of the PLLs divider registers
function [13:0] pll_divider_regs
(
input [ 7:0] divide,      // Max divide is 128
input [31:0] duty_cycle   // Duty cycle is multiplied by 100,000
);

  reg [`PLL_FIXED_WIDTH:1] duty_cycle_fix;
  reg [`PLL_FIXED_WIDTH:1] duty_cycle_min;
  reg [`PLL_FIXED_WIDTH:1] duty_cycle_max;

  reg [6:0] high_time;
  reg [6:0] low_time;
  reg       w_edge;
  reg       no_count;

  reg [`PLL_FIXED_WIDTH:1] temp;

  if (divide >= 64) begin
      duty_cycle_min = ((divide - 64) * 100_000) / divide;
      duty_cycle_max = (645 / divide) * 100_00;
      if (duty_cycle > duty_cycle_max)
        duty_cycle = duty_cycle_max;
      if (duty_cycle < duty_cycle_min)
        duty_cycle = duty_cycle_min;
  end

  duty_cycle_fix = (duty_cycle << `PLL_FRAC_PRECISION) / 100_000;

  if (divide == 7'h01) begin
      high_time = 7'h01;
      w_edge    = 1'b0;
      low_time  = 7'h01;
      no_count  = 1'b1;

  end else begin
      temp = pll_round_frac(duty_cycle_fix*divide, 1);

      high_time = temp[`PLL_FRAC_PRECISION+7:`PLL_FRAC_PRECISION+1];
      w_edge    = temp[`PLL_FRAC_PRECISION];

      if (high_time == 7'h00) begin
         high_time = 7'h01;
         w_edge    = 1'b0;
      end

      if (high_time == divide) begin
         high_time = divide - 1;
         w_edge    = 1'b1;
      end

      low_time = divide - high_time;
      no_count = 1'b0;
  end

  pll_divider_regs = {w_edge, no_count, high_time[5:0], low_time[5:0]};
endfunction

// Computes the PLLs phase shift registers
function [10:0] pll_phase_regs
(
input        [ 7:0] divide,
input signed [31:0] phase
);

  reg [`PLL_FIXED_WIDTH:1] phase_in_cycles;
  reg [`PLL_FIXED_WIDTH:1] phase_fixed;
  reg [1:0] mx;
  reg [5:0] delay_time;
  reg [2:0] phase_mux;

  reg [`PLL_FIXED_WIDTH:1] temp;

  if(phase < 0) begin
      phase_fixed = ((phase + 360000) << `PLL_FRAC_PRECISION) / 1000;
  end else begin
      phase_fixed = (phase << `PLL_FRAC_PRECISION) / 1000;
  end

 phase_in_cycles = (phase_fixed * divide) / 360;
 temp = pll_round_frac(phase_in_cycles, 3);

 mx         =  2'b00;
 phase_mux  =  temp[`PLL_FRAC_PRECISION:`PLL_FRAC_PRECISION-2];
 delay_time =  temp[`PLL_FRAC_PRECISION+6:`PLL_FRAC_PRECISION+1];

 pll_phase_regs = {mx, phase_mux, delay_time};
endfunction


// Given PLL/MMCM divide, duty_cycle and phase calculates content of the
// CLKREG1 and CLKREG2.
function [37:0] pll_clkregs
(
input [7:0]         divide,     // Max divide is 128
input [31:0]        duty_cycle, // Multiplied by 100,000
input signed [31:0] phase       // Phase is given in degrees (-360,000 to 360,000)
);

  reg [13:0] pll_div;   // EDGE, NO_COUNT, HIGH_TIME[5:0], LOW_TIME[5:0]
  reg [10:0] pll_phase; // MX, PHASE_MUX[2:0], DELAY_TIME[5:0]

  pll_div = pll_divider_regs(divide, duty_cycle);
  pll_phase = pll_phase_regs(divide, phase);

  pll_clkregs = {
    // CLKREG2: RESERVED[6:0], MX[1:0], EDGE, NO_COUNT, DELAY_TIME[5:0]
    6'h00, pll_phase[10:9], pll_div[13:12], pll_phase[5:0],
    // CLKREG1: PHASE_MUX[3:0], RESERVED, HIGH_TIME[5:0], LOW_TIME[5:0]
    pll_phase[8:6], 1'b0, pll_div[11:0]
  };

endfunction

// This function takes the divide value and outputs the necessary lock values
function [39:0] pll_lktable_lookup
(
input [6:0] divide // Max divide is 64
);

  reg [2559:0] lookup;

  lookup = {
    // This table is composed of:
    // LockRefDly_LockFBDly_LockCnt_LockSatHigh_UnlockCnt
    40'b00110_00110_1111101000_1111101001_0000000001,
    40'b00110_00110_1111101000_1111101001_0000000001,
    40'b01000_01000_1111101000_1111101001_0000000001,
    40'b01011_01011_1111101000_1111101001_0000000001,
    40'b01110_01110_1111101000_1111101001_0000000001,
    40'b10001_10001_1111101000_1111101001_0000000001,
    40'b10011_10011_1111101000_1111101001_0000000001,
    40'b10110_10110_1111101000_1111101001_0000000001,
    40'b11001_11001_1111101000_1111101001_0000000001,
    40'b11100_11100_1111101000_1111101001_0000000001,
    40'b11111_11111_1110000100_1111101001_0000000001,
    40'b11111_11111_1100111001_1111101001_0000000001,
    40'b11111_11111_1011101110_1111101001_0000000001,
    40'b11111_11111_1010111100_1111101001_0000000001,
    40'b11111_11111_1010001010_1111101001_0000000001,
    40'b11111_11111_1001110001_1111101001_0000000001,
    40'b11111_11111_1000111111_1111101001_0000000001,
    40'b11111_11111_1000100110_1111101001_0000000001,
    40'b11111_11111_1000001101_1111101001_0000000001,
    40'b11111_11111_0111110100_1111101001_0000000001,
    40'b11111_11111_0111011011_1111101001_0000000001,
    40'b11111_11111_0111000010_1111101001_0000000001,
    40'b11111_11111_0110101001_1111101001_0000000001,
    40'b11111_11111_0110010000_1111101001_0000000001,
    40'b11111_11111_0110010000_1111101001_0000000001,
    40'b11111_11111_0101110111_1111101001_0000000001,
    40'b11111_11111_0101011110_1111101001_0000000001,
    40'b11111_11111_0101011110_1111101001_0000000001,
    40'b11111_11111_0101000101_1111101001_0000000001,
    40'b11111_11111_0101000101_1111101001_0000000001,
    40'b11111_11111_0100101100_1111101001_0000000001,
    40'b11111_11111_0100101100_1111101001_0000000001,
    40'b11111_11111_0100101100_1111101001_0000000001,
    40'b11111_11111_0100010011_1111101001_0000000001,
    40'b11111_11111_0100010011_1111101001_0000000001,
    40'b11111_11111_0100010011_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001,
    40'b11111_11111_0011111010_1111101001_0000000001
    };

  pll_lktable_lookup = lookup[ ((64-divide)*40) +: 40];
endfunction

// This function takes the divide value and the bandwidth setting of the PLL
// and outputs the digital filter settings necessary.
function [9:0] pll_table_lookup
(
input [6:0]   divide, // Max divide is 64
input [8*9:0] BANDWIDTH
);

  reg [639:0] lookup_low;
  reg [639:0] lookup_high;
  reg [639:0] lookup_optimized;

  reg [9:0] lookup_entry;

  lookup_low = {
    // CP_RES_LFHF
    10'b0010_1111_00,
    10'b0010_1111_00,
    10'b0010_0111_00,
    10'b0010_1101_00,
    10'b0010_0101_00,
    10'b0010_0101_00,
    10'b0010_1001_00,
    10'b0010_1110_00,
    10'b0010_1110_00,
    10'b0010_0001_00,
    10'b0010_0001_00,
    10'b0010_0110_00,
    10'b0010_0110_00,
    10'b0010_0110_00,
    10'b0010_0110_00,
    10'b0010_1010_00,
    10'b0010_1010_00,
    10'b0010_1010_00,
    10'b0010_1010_00,
    10'b0010_1100_00,
    10'b0010_1100_00,
    10'b0010_1100_00,
    10'b0010_1100_00,
    10'b0010_1100_00,
    10'b0010_1100_00,
    10'b0010_1100_00,
    10'b0010_1100_00,
    10'b0010_1100_00,
    10'b0010_1100_00,
    10'b0010_1100_00,
    10'b0010_0010_00,
    10'b0010_0010_00,
    10'b0010_0010_00,
    10'b0010_0010_00,
    10'b0010_0010_00,
    10'b0010_0010_00,
    10'b0010_0010_00,
    10'b0010_0010_00,
    10'b0010_0010_00,
    10'b0010_0010_00,
    10'b0011_1100_00,
    10'b0011_1100_00,
    10'b0011_1100_00,
    10'b0011_1100_00,
    10'b0011_1100_00,
    10'b0011_1100_00,
    10'b0011_1100_00,
    10'b0010_0100_00,
    10'b0010_0100_00,
    10'b0010_0100_00,
    10'b0010_0100_00,
    10'b0010_0100_00,
    10'b0010_0100_00,
    10'b0010_0100_00,
    10'b0010_0100_00,
    10'b0010_0100_00,
    10'b0010_0100_00,
    10'b0010_0100_00,
    10'b0010_0100_00,
    10'b0010_0100_00,
    10'b0010_0100_00,
    10'b0010_0100_00,
    10'b0010_0100_00,
    10'b0010_0100_00
  };

  lookup_high = {
    // CP_RES_LFHF
    10'b0011_0111_00,
    10'b0011_0111_00,
    10'b0101_1111_00,
    10'b0111_1111_00,
    10'b0111_1011_00,
    10'b1101_0111_00,
    10'b1110_1011_00,
    10'b1110_1101_00,
    10'b1111_1101_00,
    10'b1111_0111_00,
    10'b1111_1011_00,
    10'b1111_1101_00,
    10'b1111_0011_00,
    10'b1110_0101_00,
    10'b1111_0101_00,
    10'b1111_0101_00,
    10'b1111_0101_00,
    10'b1111_0101_00,
    10'b0111_0110_00,
    10'b0111_0110_00,
    10'b0111_0110_00,
    10'b0111_0110_00,
    10'b0101_1100_00,
    10'b0101_1100_00,
    10'b0101_1100_00,
    10'b1100_0001_00,
    10'b1100_0001_00,
    10'b1100_0001_00,
    10'b1100_0001_00,
    10'b1100_0001_00,
    10'b1100_0001_00,
    10'b1100_0001_00,
    10'b1100_0001_00,
    10'b0100_0010_00,
    10'b0100_0010_00,
    10'b0100_0010_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0011_0100_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0100_1100_00,
    10'b0100_1100_00,
    10'b0100_1100_00,
    10'b0100_1100_00,
    10'b0100_1100_00,
    10'b0100_1100_00,
    10'b0100_1100_00,
    10'b0010_0100_00,
    10'b0010_0100_00,
    10'b0010_0100_00,
    10'b0010_0100_00
  };

  lookup_optimized = {
    // CP_RES_LFHF
    10'b0011_0111_00,
    10'b0011_0111_00,
    10'b0101_1111_00,
    10'b0111_1111_00,
    10'b0111_1011_00,
    10'b1101_0111_00,
    10'b1110_1011_00,
    10'b1110_1101_00,
    10'b1111_1101_00,
    10'b1111_0111_00,
    10'b1111_1011_00,
    10'b1111_1101_00,
    10'b1111_0011_00,
    10'b1110_0101_00,
    10'b1111_0101_00,
    10'b1111_0101_00,
    10'b1111_0101_00,
    10'b1111_0101_00,
    10'b0111_0110_00,
    10'b0111_0110_00,
    10'b0111_0110_00,
    10'b0111_0110_00,
    10'b0101_1100_00,
    10'b0101_1100_00,
    10'b0101_1100_00,
    10'b1100_0001_00,
    10'b1100_0001_00,
    10'b1100_0001_00,
    10'b1100_0001_00,
    10'b1100_0001_00,
    10'b1100_0001_00,
    10'b1100_0001_00,
    10'b1100_0001_00,
    10'b0100_0010_00,
    10'b0100_0010_00,
    10'b0100_0010_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0011_0100_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0010_1000_00,
    10'b0100_1100_00,
    10'b0100_1100_00,
    10'b0100_1100_00,
    10'b0100_1100_00,
    10'b0100_1100_00,
    10'b0100_1100_00,
    10'b0100_1100_00,
    10'b0010_0100_00,
    10'b0010_0100_00,
    10'b0010_0100_00,
    10'b0010_0100_00
  };

  if (BANDWIDTH == "LOW") begin
    pll_table_lookup = lookup_low[((64-divide)*10) +: 10];
  end else if (BANDWIDTH == "HIGH") begin
    pll_table_lookup = lookup_high[((64-divide)*10) +: 10];
  end else if (BANDWIDTH == "OPTIMIZED") begin
    pll_table_lookup = lookup_optimized[((64-divide)*10) +: 10];
  end

endfunction

// ............................................................................
// IMPORTANT NOTE: Due to lack of support for real type parameters in Yosys
// the PLL parameters that define duty cycles and phase shifts have to be
// provided as integers! The DUTY_CYCLE is expressed as % of high time times
// 1000 whereas the PHASE is expressed in degrees times 1000.

// PLLE2_ADV
module PLLE2_ADV
(
input         CLKFBIN,
input         CLKIN1,
input         CLKIN2,
input         CLKINSEL,

output        CLKFBOUT,
output        CLKOUT0,
output        CLKOUT1,
output        CLKOUT2,
output        CLKOUT3,
output        CLKOUT4,
output        CLKOUT5,

input         PWRDWN,
input         RST,
output        LOCKED,

input         DCLK,
input         DEN,
input         DWE,
output        DRDY,
input  [ 6:0] DADDR,
input  [15:0] DI,
output [15:0] DO
);

  parameter _TECHMAP_CONSTMSK_PWRDWN_   = 1'b1;
  parameter _TECHMAP_CONSTVAL_PWRDWN_   = 1'bx;

  parameter _TECHMAP_CONSTMSK_DCLK_     = 1'b1;
  parameter _TECHMAP_CONSTVAL_DCLK_     = 1'bx;
  parameter _TECHMAP_CONSTMSK_DEN_      = 1'b1;
  parameter _TECHMAP_CONSTVAL_DEN_      = 1'bx;
  parameter _TECHMAP_CONSTMSK_DWE_      = 1'b1;
  parameter _TECHMAP_CONSTVAL_DWE_      = 1'bx;

  parameter _TECHMAP_CONSTMSK_CLKFBOUT_ = 1'b1;
  parameter _TECHMAP_CONSTVAL_CLKFBOUT_ = 1'bx;
  parameter _TECHMAP_CONSTMSK_CLKOUT0_  = 1'b1;
  parameter _TECHMAP_CONSTVAL_CLKOUT0_  = 1'bx;
  parameter _TECHMAP_CONSTMSK_CLKOUT1_  = 1'b1;
  parameter _TECHMAP_CONSTVAL_CLKOUT1_  = 1'bx;
  parameter _TECHMAP_CONSTMSK_CLKOUT2_  = 1'b1;
  parameter _TECHMAP_CONSTVAL_CLKOUT2_  = 1'bx;
  parameter _TECHMAP_CONSTMSK_CLKOUT3_  = 1'b1;
  parameter _TECHMAP_CONSTVAL_CLKOUT3_  = 1'bx;
  parameter _TECHMAP_CONSTMSK_CLKOUT4_  = 1'b1;
  parameter _TECHMAP_CONSTVAL_CLKOUT4_  = 1'bx;
  parameter _TECHMAP_CONSTMSK_CLKOUT5_  = 1'b1;
  parameter _TECHMAP_CONSTVAL_CLKOUT5_  = 1'bx;


  parameter IS_CLKINSEL_INVERTED = 1'b0;
  parameter IS_RST_INVERTED = 1'b0;
  parameter IS_PWRDWN_INVERTED = 1'b0;

  parameter BANDWIDTH = "OPTIMIZED";
  parameter STARTUP_WAIT = "FALSE";
  parameter COMPENSATION = "ZHOLD";

  parameter CLKIN1_PERIOD = 0.0;
  parameter REF_JITTER1 = 0.01;
  parameter CLKIN2_PERIOD = 0.0;
  parameter REF_JITTER2 = 0.01;

  parameter [5:0] DIVCLK_DIVIDE = 1;

  parameter [5:0] CLKFBOUT_MULT = 1;
  parameter CLKFBOUT_PHASE = 0;

  parameter [6:0] CLKOUT0_DIVIDE = 1;
  parameter CLKOUT0_DUTY_CYCLE = 50000;
  parameter signed CLKOUT0_PHASE = 0;

  parameter [6:0] CLKOUT1_DIVIDE = 1;
  parameter CLKOUT1_DUTY_CYCLE = 50000;
  parameter signed CLKOUT1_PHASE = 0;

  parameter [6:0] CLKOUT2_DIVIDE = 1;
  parameter CLKOUT2_DUTY_CYCLE = 50000;
  parameter signed CLKOUT2_PHASE = 0;

  parameter [6:0] CLKOUT3_DIVIDE = 1;
  parameter CLKOUT3_DUTY_CYCLE = 50000;
  parameter signed CLKOUT3_PHASE = 0;

  parameter [6:0] CLKOUT4_DIVIDE = 1;
  parameter CLKOUT4_DUTY_CYCLE = 50000;
  parameter signed CLKOUT4_PHASE = 0;

  parameter [6:0] CLKOUT5_DIVIDE = 1;
  parameter CLKOUT5_DUTY_CYCLE = 50000;
  parameter signed CLKOUT5_PHASE = 0;

  // Compute PLL's registers content
  localparam CLKFBOUT_REGS = pll_clkregs(CLKFBOUT_MULT, 50000, CLKFBOUT_PHASE);
  localparam DIVCLK_REGS   = pll_clkregs(DIVCLK_DIVIDE, 50000, 0);

  localparam CLKOUT0_REGS  = pll_clkregs(CLKOUT0_DIVIDE, CLKOUT0_DUTY_CYCLE, CLKOUT0_PHASE);
  localparam CLKOUT1_REGS  = pll_clkregs(CLKOUT1_DIVIDE, CLKOUT1_DUTY_CYCLE, CLKOUT1_PHASE);
  localparam CLKOUT2_REGS  = pll_clkregs(CLKOUT2_DIVIDE, CLKOUT2_DUTY_CYCLE, CLKOUT2_PHASE);
  localparam CLKOUT3_REGS  = pll_clkregs(CLKOUT3_DIVIDE, CLKOUT3_DUTY_CYCLE, CLKOUT3_PHASE);
  localparam CLKOUT4_REGS  = pll_clkregs(CLKOUT4_DIVIDE, CLKOUT4_DUTY_CYCLE, CLKOUT4_PHASE);
  localparam CLKOUT5_REGS  = pll_clkregs(CLKOUT5_DIVIDE, CLKOUT5_DUTY_CYCLE, CLKOUT5_PHASE);

  // The substituted cell
  PLLE2_ADV_VPR #
  (
  // Inverters
  .INV_CLKINSEL(IS_CLKINSEL_INVERTED),
  .ZINV_PWRDWN(IS_PWRDWN_INVERTED),
  .ZINV_RST(IS_RST_INVERTED),

  // Straight mapped parameters
  .STARTUP_WAIT(STARTUP_WAIT == "TRUE"),

  // Lookup tables
  .LKTABLE(pll_lktable_lookup(CLKFBOUT_MULT)),
  .TABLE(pll_table_lookup(CLKFBOUT_MULT, BANDWIDTH)),

  // FIXME: How to compute values the two below ?
  .FILTREG1_RESERVED(12'b0000_00001000),
  .LOCKREG3_RESERVED(1'b1),

  // Clock feedback settings
  .CLKFBOUT_CLKOUT1_HIGH_TIME   (CLKFBOUT_REGS[11:6]),
  .CLKFBOUT_CLKOUT1_LOW_TIME    (CLKFBOUT_REGS[5:0]),
  .CLKFBOUT_CLKOUT1_PHASE_MUX   (CLKFBOUT_REGS[15:13]),
  .CLKFBOUT_CLKOUT2_DELAY_TIME  (CLKFBOUT_REGS[21:16]),
  .CLKFBOUT_CLKOUT2_EDGE        (CLKFBOUT_REGS[23]),
  .CLKFBOUT_CLKOUT2_NO_COUNT    (CLKFBOUT_REGS[22]),

  // Internal VCO divider settings
  .DIVCLK_DIVCLK_HIGH_TIME      (DIVCLK_REGS[11:6]),
  .DIVCLK_DIVCLK_LOW_TIME       (DIVCLK_REGS[5:0]),
  .DIVCLK_DIVCLK_NO_COUNT       (DIVCLK_REGS[22]),
  .DIVCLK_DIVCLK_EDGE           (DIVCLK_REGS[23]),

  // CLKOUT0
  .CLKOUT0_CLKOUT1_HIGH_TIME    (CLKOUT0_REGS[11:6]),
  .CLKOUT0_CLKOUT1_LOW_TIME     (CLKOUT0_REGS[5:0]),
  .CLKOUT0_CLKOUT1_PHASE_MUX    (CLKOUT0_REGS[15:13]),
  .CLKOUT0_CLKOUT2_DELAY_TIME   (CLKOUT0_REGS[21:16]),
  .CLKOUT0_CLKOUT2_EDGE         (CLKOUT0_REGS[23]),
  .CLKOUT0_CLKOUT2_NO_COUNT     (CLKOUT0_REGS[22]),

  // CLKOUT1
  .CLKOUT1_CLKOUT1_HIGH_TIME    (CLKOUT1_REGS[11:6]),
  .CLKOUT1_CLKOUT1_LOW_TIME     (CLKOUT1_REGS[5:0]),
  .CLKOUT1_CLKOUT1_PHASE_MUX    (CLKOUT1_REGS[15:13]),
  .CLKOUT1_CLKOUT2_DELAY_TIME   (CLKOUT1_REGS[21:16]),
  .CLKOUT1_CLKOUT2_EDGE         (CLKOUT1_REGS[23]),
  .CLKOUT1_CLKOUT2_NO_COUNT     (CLKOUT1_REGS[22]),

  // CLKOUT2
  .CLKOUT2_CLKOUT1_HIGH_TIME    (CLKOUT2_REGS[11:6]),
  .CLKOUT2_CLKOUT1_LOW_TIME     (CLKOUT2_REGS[5:0]),
  .CLKOUT2_CLKOUT1_PHASE_MUX    (CLKOUT2_REGS[15:13]),
  .CLKOUT2_CLKOUT2_DELAY_TIME   (CLKOUT2_REGS[21:16]),
  .CLKOUT2_CLKOUT2_EDGE         (CLKOUT2_REGS[23]),
  .CLKOUT2_CLKOUT2_NO_COUNT     (CLKOUT2_REGS[22]),

  // CLKOUT3
  .CLKOUT3_CLKOUT1_HIGH_TIME    (CLKOUT3_REGS[11:6]),
  .CLKOUT3_CLKOUT1_LOW_TIME     (CLKOUT3_REGS[5:0]),
  .CLKOUT3_CLKOUT1_PHASE_MUX    (CLKOUT3_REGS[15:13]),
  .CLKOUT3_CLKOUT2_DELAY_TIME   (CLKOUT3_REGS[21:16]),
  .CLKOUT3_CLKOUT2_EDGE         (CLKOUT3_REGS[23]),
  .CLKOUT3_CLKOUT2_NO_COUNT     (CLKOUT3_REGS[22]),

  // CLKOUT4
  .CLKOUT4_CLKOUT1_HIGH_TIME    (CLKOUT4_REGS[11:6]),
  .CLKOUT4_CLKOUT1_LOW_TIME     (CLKOUT4_REGS[5:0]),
  .CLKOUT4_CLKOUT1_PHASE_MUX    (CLKOUT4_REGS[15:13]),
  .CLKOUT4_CLKOUT2_DELAY_TIME   (CLKOUT4_REGS[21:16]),
  .CLKOUT4_CLKOUT2_EDGE         (CLKOUT4_REGS[23]),
  .CLKOUT4_CLKOUT2_NO_COUNT     (CLKOUT4_REGS[22]),

  // CLKOUT5
  .CLKOUT5_CLKOUT1_HIGH_TIME    (CLKOUT5_REGS[11:6]),
  .CLKOUT5_CLKOUT1_LOW_TIME     (CLKOUT5_REGS[5:0]),
  .CLKOUT5_CLKOUT1_PHASE_MUX    (CLKOUT5_REGS[15:13]),
  .CLKOUT5_CLKOUT2_DELAY_TIME   (CLKOUT5_REGS[21:16]),
  .CLKOUT5_CLKOUT2_EDGE         (CLKOUT5_REGS[23]),
  .CLKOUT5_CLKOUT2_NO_COUNT     (CLKOUT5_REGS[22]),

  // Clock output enable controls
  .CLKFBOUT_CLKOUT1_OUTPUT_ENABLE(_TECHMAP_CONSTMSK_CLKFBOUT_ == 1'b0),

  .CLKOUT0_CLKOUT1_OUTPUT_ENABLE(_TECHMAP_CONSTMSK_CLKOUT0_ == 1'b0),
  .CLKOUT1_CLKOUT1_OUTPUT_ENABLE(_TECHMAP_CONSTMSK_CLKOUT1_ == 1'b0),
  .CLKOUT2_CLKOUT1_OUTPUT_ENABLE(_TECHMAP_CONSTMSK_CLKOUT2_ == 1'b0),
  .CLKOUT3_CLKOUT1_OUTPUT_ENABLE(_TECHMAP_CONSTMSK_CLKOUT3_ == 1'b0),
  .CLKOUT4_CLKOUT1_OUTPUT_ENABLE(_TECHMAP_CONSTMSK_CLKOUT4_ == 1'b0),
  .CLKOUT5_CLKOUT1_OUTPUT_ENABLE(_TECHMAP_CONSTMSK_CLKOUT5_ == 1'b0)

  )
  _TECHMAP_REPLACE_
  (
  .CLKFBIN(CLKFBIN),
  .CLKIN1(CLKIN1),
  .CLKIN2(CLKIN2),
  .CLKINSEL(CLKINSEL),

  .CLKFBOUT(CLKFBOUT),
  .CLKOUT0(CLKOUT0),
  .CLKOUT1(CLKOUT1),
  .CLKOUT2(CLKOUT2),
  .CLKOUT3(CLKOUT3),
  .CLKOUT4(CLKOUT4),
  .CLKOUT5(CLKOUT5),

  .PWRDWN((_TECHMAP_CONSTMSK_PWRDWN_ == 1'b0 && _TECHMAP_CONSTVAL_PWRDWN_ == 1'bx) ? 1'b0 : PWRDWN),
  .RST(RST),
  .LOCKED(LOCKED),

  .DCLK ((_TECHMAP_CONSTMSK_DCLK_ == 1'b0 && _TECHMAP_CONSTVAL_DCLK_ == 1'bx) ? 1'b0 : DCLK),
  .DEN  ((_TECHMAP_CONSTMSK_DEN_  == 1'b0 && _TECHMAP_CONSTVAL_DEN_  == 1'bx) ? 1'b0 : DEN),
  .DWE  ((_TECHMAP_CONSTMSK_DWE_  == 1'b0 && _TECHMAP_CONSTVAL_DWE_  == 1'bx) ? 1'b0 : DWE),
  .DRDY (DRDY),
  .DADDR(DADDR),
  .DI   (DI),
  .DO   (DO)
  );

endmodule

// PLLE2_BASE
module PLLE2_BASE
(
input         CLKFBIN,
input         CLKIN,

output        CLKFBOUT,
output        CLKOUT0,
output        CLKOUT1,
output        CLKOUT2,
output        CLKOUT3,
output        CLKOUT4,
output        CLKOUT5,

input         RST,
output        LOCKED
);

  parameter IS_CLKINSEL_INVERTED = 1'b0;
  parameter IS_RST_INVERTED = 1'b0;

  parameter BANDWIDTH = "OPTIMIZED";
  parameter STARTUP_WAIT = "FALSE";

  parameter CLKIN1_PERIOD = 0.0;
  parameter REF_JITTER1 = 0.1;

  parameter [5:0] DIVCLK_DIVIDE = 1;

  parameter [5:0] CLKFBOUT_MULT = 1;
  parameter signed CLKFBOUT_PHASE = 0;

  parameter [6:0] CLKOUT0_DIVIDE = 1;
  parameter CLKOUT0_DUTY_CYCLE = 50000;
  parameter signed CLKOUT0_PHASE = 0;

  parameter [6:0] CLKOUT1_DIVIDE = 1;
  parameter CLKOUT1_DUTY_CYCLE = 50000;
  parameter signed CLKOUT1_PHASE = 0;

  parameter [6:0] CLKOUT2_DIVIDE = 1;
  parameter CLKOUT2_DUTY_CYCLE = 50000;
  parameter signed CLKOUT2_PHASE = 0;

  parameter [6:0] CLKOUT3_DIVIDE = 1;
  parameter CLKOUT3_DUTY_CYCLE = 50000;
  parameter signed CLKOUT3_PHASE = 0;

  parameter [6:0] CLKOUT4_DIVIDE = 1;
  parameter CLKOUT4_DUTY_CYCLE = 50000;
  parameter signed CLKOUT4_PHASE = 0;

  parameter [6:0] CLKOUT5_DIVIDE = 1;
  parameter CLKOUT5_DUTY_CYCLE = 50000;
  parameter signed CLKOUT5_PHASE = 0;

  // The substituted cell
  PLLE2_ADV #
  (
  .IS_CLKINSEL_INVERTED(IS_CLKINSEL_INVERTED),
  .IS_RST_INVERTED(IS_RST_INVERTED),
  .IS_PWRDWN_INVERTED(1'b0),

  .BANDWIDTH(BANDWIDTH),
  .STARTUP_WAIT(STARTUP_WAIT),

  .CLKIN1_PERIOD(CLKIN1_PERIOD),
  .REF_JITTER1(REF_JITTER1),

  .DIVCLK_DIVIDE(DIVCLK_DIVIDE),
  
  .CLKFBOUT_MULT(CLKFBOUT_MULT),
  .CLKFBOUT_PHASE(CLKFBOUT_PHASE),

  .CLKOUT0_DIVIDE(CLKOUT0_DIVIDE),
  .CLKOUT0_DUTY_CYCLE(CLKOUT0_DUTY_CYCLE),
  .CLKOUT0_PHASE(CLKOUT0_PHASE),

  .CLKOUT1_DIVIDE(CLKOUT1_DIVIDE),
  .CLKOUT1_DUTY_CYCLE(CLKOUT1_DUTY_CYCLE),
  .CLKOUT1_PHASE(CLKOUT1_PHASE),

  .CLKOUT2_DIVIDE(CLKOUT2_DIVIDE),
  .CLKOUT2_DUTY_CYCLE(CLKOUT2_DUTY_CYCLE),
  .CLKOUT2_PHASE(CLKOUT2_PHASE),

  .CLKOUT3_DIVIDE(CLKOUT3_DIVIDE),
  .CLKOUT3_DUTY_CYCLE(CLKOUT3_DUTY_CYCLE),
  .CLKOUT3_PHASE(CLKOUT3_PHASE),

  .CLKOUT4_DIVIDE(CLKOUT4_DIVIDE),
  .CLKOUT4_DUTY_CYCLE(CLKOUT4_DUTY_CYCLE),
  .CLKOUT4_PHASE(CLKOUT4_PHASE),

  .CLKOUT5_DIVIDE(CLKOUT5_DIVIDE),
  .CLKOUT5_DUTY_CYCLE(CLKOUT5_DUTY_CYCLE),
  .CLKOUT5_PHASE(CLKOUT5_PHASE)
  )
  _TECHMAP_REPLACE_
  (
  .CLKFBIN(CLKFBIN),
  .CLKIN1(CLKIN),
  .CLKINSEL(1'b1),

  .CLKFBOUT(CLKFBOUT),
  .CLKOUT0(CLKOUT0),
  .CLKOUT1(CLKOUT1),
  .CLKOUT2(CLKOUT2),
  .CLKOUT3(CLKOUT3),
  .CLKOUT4(CLKOUT4),
  .CLKOUT5(CLKOUT5),

  .PWRDWN(1'b0),
  .RST(RST),
  .LOCKED(LOCKED),

  .DCLK(1'b0),
  .DEN(1'b0),
  .DWE(1'b0),
  .DRDY(),
  .DADDR(7'd0),
  .DI(16'd0),
  .DO()
  );

endmodule

