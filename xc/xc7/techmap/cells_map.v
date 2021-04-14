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

    SPRAM32 #(
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

    wire Dstub;
    DI64_STUB stub1 (
        .DI(D),
        .DO(Dstub)
    );

    DPRAM64 #(
        .INIT(INIT),
        .IS_WCLK_INVERTED(IS_WCLK_INVERTED)
    ) dram0 (
        .DI(Dstub),
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
  reg GENERATE_ERROR;
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
        && READ_WIDTH_A != 2
        && READ_WIDTH_A != 4
        && READ_WIDTH_A != 9
        && READ_WIDTH_A != 18
        && READ_WIDTH_A != 36)
        _TECHMAP_FAIL_ <= GENERATE_ERROR;
    if(READ_WIDTH_B != 0
        && READ_WIDTH_B != 1
        && READ_WIDTH_B != 2
        && READ_WIDTH_B != 4
        && READ_WIDTH_B != 9
        && READ_WIDTH_B != 18)
         _TECHMAP_FAIL_ <= GENERATE_ERROR;
    if(WRITE_WIDTH_A != 0
        && WRITE_WIDTH_A != 1
        && WRITE_WIDTH_A != 2
        && WRITE_WIDTH_A != 4
        && WRITE_WIDTH_A != 9
        && WRITE_WIDTH_A != 18)
        _TECHMAP_FAIL_ <= GENERATE_ERROR;
    if(WRITE_WIDTH_B != 0
        && WRITE_WIDTH_B != 1
        && WRITE_WIDTH_B != 2
        && WRITE_WIDTH_B != 4
        && WRITE_WIDTH_B != 9
        && WRITE_WIDTH_B != 18
        && WRITE_WIDTH_B != 36)
        _TECHMAP_FAIL_ <= GENERATE_ERROR;

    if(READ_WIDTH_A > 18 && RAM_MODE != "SDP") begin
        _TECHMAP_FAIL_ <= GENERATE_ERROR;
    end

    if(WRITE_WIDTH_B > 18 && RAM_MODE != "SDP") begin
        _TECHMAP_FAIL_ <= GENERATE_ERROR;
    end

    if(WRITE_MODE_A != "WRITE_FIRST" && WRITE_MODE_A != "NO_CHANGE" && WRITE_MODE_A != "READ_FIRST")
        _TECHMAP_FAIL_ <= GENERATE_ERROR;
    if(WRITE_MODE_B != "WRITE_FIRST" && WRITE_MODE_B != "NO_CHANGE" && WRITE_MODE_B != "READ_FIRST")
        _TECHMAP_FAIL_ <= GENERATE_ERROR;

  end

  localparam EFF_READ_WIDTH_A = (RAM_MODE == "SDP" && READ_WIDTH_A == 36) ? 18 : READ_WIDTH_A;
  localparam EFF_READ_WIDTH_B = (RAM_MODE == "SDP" && READ_WIDTH_A == 36) ? 18 : READ_WIDTH_B;

  localparam EFF_WRITE_WIDTH_A = (RAM_MODE == "SDP" && WRITE_WIDTH_B == 36) ? 18 : WRITE_WIDTH_A;
  localparam EFF_WRITE_WIDTH_B = (RAM_MODE == "SDP" && WRITE_WIDTH_B == 36) ? 18 : WRITE_WIDTH_B;

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

  assign REGCLKA = DOA_REG ? CLKARDCLK : 1'b1;
  localparam ZINV_REGCLKARDRCLK = (DOA_REG && !IS_CLKARDCLK_INVERTED);

  assign REGCLKB = DOB_REG ? CLKBWRCLK : 1'b1;
  localparam ZINV_REGCLKB = (DOB_REG && !IS_CLKBWRCLK_INVERTED);

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

      // Assign special parameters relative to the RAMB site location.
      // These is needed after the findings gathered with https://github.com/SymbiFlow/prjxray/pull/1263
      // The rules to assign the correct READ_WIDTH_A parameter are the following:
      //   - Y0 RAMB18 and SDP mode: READ_WIDTH_A must be 1
      //   - Y1 RAMB18 and SDP mode: READ_WIDTH_A must be 18
      //   - No SDP: READ_WIDTH_A assumes the right value based on EFF_READ_WIDTH_A
      .Y0_READ_WIDTH_A_1(READ_WIDTH_A == 36 || EFF_READ_WIDTH_A == 1 || EFF_READ_WIDTH_A == 0),
      .Y1_READ_WIDTH_A_1(READ_WIDTH_A != 36 && (EFF_READ_WIDTH_A == 1 || EFF_READ_WIDTH_A == 0)),
      .Y0_READ_WIDTH_A_18(READ_WIDTH_A != 36 && EFF_READ_WIDTH_A == 18),
      .Y1_READ_WIDTH_A_18(READ_WIDTH_A == 36 || EFF_READ_WIDTH_A == 18),

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
        _TECHMAP_FAIL_ <= GENERATE_ERROR;
    if(`INVALID_WIDTH(READ_WIDTH_B))
        _TECHMAP_FAIL_ <= GENERATE_ERROR;
    if(`INVALID_WIDTH(WRITE_WIDTH_A))
        _TECHMAP_FAIL_ <= GENERATE_ERROR;
    if(`INVALID_WIDTH_WIDE(WRITE_WIDTH_B))
        _TECHMAP_FAIL_ <= GENERATE_ERROR;

    `undef INVALID_WIDTH
    `undef INVALID_WIDTH_WIDE

    if(READ_WIDTH_A > 36 && RAM_MODE != "SDP") begin
        _TECHMAP_FAIL_ <= GENERATE_ERROR;
    end

    if(WRITE_WIDTH_B > 36 && RAM_MODE != "SDP") begin
        _TECHMAP_FAIL_ <= GENERATE_ERROR;
    end

    if(WRITE_MODE_A != "WRITE_FIRST" && WRITE_MODE_A != "NO_CHANGE" && WRITE_MODE_A != "READ_FIRST")
        _TECHMAP_FAIL_ <= GENERATE_ERROR;
    if(WRITE_MODE_B != "WRITE_FIRST" && WRITE_MODE_B != "NO_CHANGE" && WRITE_MODE_B != "READ_FIRST")
        _TECHMAP_FAIL_ <= GENERATE_ERROR;

  end

  localparam EFF_READ_WIDTH_A = (RAM_MODE == "SDP" && READ_WIDTH_A > 36) ? 36 : READ_WIDTH_A;
  localparam EFF_READ_WIDTH_B = (RAM_MODE == "SDP" && READ_WIDTH_A > 36) ? 36 : READ_WIDTH_B;

  localparam EFF_WRITE_WIDTH_A = (RAM_MODE == "SDP" && WRITE_WIDTH_B > 36) ? 36 : WRITE_WIDTH_A;
  localparam EFF_WRITE_WIDTH_B = (RAM_MODE == "SDP" && WRITE_WIDTH_B > 36) ? 36 : WRITE_WIDTH_B;

  wire REGCLKA;
  wire REGCLKB;

  assign REGCLKA = DOA_REG ? CLKARDCLK : 1'b1;
  localparam ZINV_REGCLKARDRCLK = (DOA_REG && !IS_CLKARDCLK_INVERTED);

  assign REGCLKB = DOB_REG ? CLKBWRCLK : 1'b1;
  localparam ZINV_REGCLKB = (DOB_REG && !IS_CLKBWRCLK_INVERTED);

  wire [7:0] WEBWE_WIDE;
  wire [3:0] WEA_WIDE;
  wire [3:0] DIPADIP_MAPPED;
  wire [3:0] DIPBDIP_MAPPED;
  wire [31:0] DIADI_MAPPED;
  wire [31:0] DIBDI_MAPPED;

  if(WRITE_WIDTH_A == 1) begin
      assign DIADI_MAPPED[31:2] = DIADI[31:2];
      assign DIADI_MAPPED[1] = DIADI[0];
      assign DIADI_MAPPED[0] = DIADI[0];
  end else begin
      assign DIADI_MAPPED = DIADI;
  end

  if(WRITE_WIDTH_B == 1) begin
      assign DIBDI_MAPPED[31:2] = DIBDI[31:2];
      assign DIBDI_MAPPED[1] = DIBDI[0];
      assign DIBDI_MAPPED[0] = DIBDI[0];
  end else begin
      assign DIBDI_MAPPED = DIBDI;
  end

  if(WRITE_WIDTH_A < 18) begin
      assign WEA_WIDE = {4{WEA[0]}};

      assign DIPADIP_MAPPED[3:2] = DIPADIP[3:2];
      assign DIPADIP_MAPPED[1] = DIPADIP[0];
      assign DIPADIP_MAPPED[0] = DIPADIP[0];
  end else if(WRITE_WIDTH_A == 18) begin
      assign WEA_WIDE[3] = WEA[1];
      assign WEA_WIDE[1] = WEA[1];
      assign WEA_WIDE[2] = WEA[0];
      assign WEA_WIDE[0] = WEA[0];

      assign DIPADIP_MAPPED = DIPADIP;
  end else if(WRITE_WIDTH_A == 36) begin
      assign WEA_WIDE = WEA;
      assign DIPADIP_MAPPED = DIPADIP;
  end

  if(WRITE_WIDTH_B < 18) begin
      assign WEBWE_WIDE[7:4] = 4'b0;
      assign WEBWE_WIDE[3:0] = {4{WEBWE[0]}};

      assign DIPBDIP_MAPPED[3:2] = DIPBDIP[3:2];
      assign DIPBDIP_MAPPED[1] = DIPBDIP[0];
      assign DIPBDIP_MAPPED[0] = DIPBDIP[0];
  end else if(WRITE_WIDTH_B == 18) begin
      assign WEBWE_WIDE[7:4] = 4'b0;
      assign WEBWE_WIDE[3] = WEBWE[1];
      assign WEBWE_WIDE[1] = WEBWE[1];
      assign WEBWE_WIDE[2] = WEBWE[0];
      assign WEBWE_WIDE[0] = WEBWE[0];

      assign DIPBDIP_MAPPED = DIPBDIP;
  end else if(WRITE_WIDTH_B == 36) begin
      assign WEBWE_WIDE = WEBWE;
      assign DIPBDIP_MAPPED = DIPBDIP;
  end else if(WRITE_WIDTH_B == 72) begin
      assign WEA_WIDE = 4'b0;
      assign WEBWE_WIDE = WEBWE;
      assign DIPBDIP_MAPPED = DIPBDIP;
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

      .BRAM36_READ_WIDTH_A_1(EFF_READ_WIDTH_A == 1 || EFF_READ_WIDTH_A == 9),
      .BRAM36_READ_WIDTH_B_1(EFF_READ_WIDTH_B == 1 || EFF_READ_WIDTH_B == 9),
      .BRAM36_WRITE_WIDTH_A_1(EFF_WRITE_WIDTH_A == 1 || EFF_WRITE_WIDTH_A == 9),
      .BRAM36_WRITE_WIDTH_B_1(EFF_WRITE_WIDTH_B == 1 || EFF_WRITE_WIDTH_B == 9),

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
    .DIADI(DIADI_MAPPED),
    .DIBDI(DIBDI_MAPPED),
    .DIPADIP(DIPADIP_MAPPED),
    .DIPBDIP(DIPBDIP_MAPPED),
    `DUP(WEA, WEA_WIDE),
    `DUP(WEBWE, WEBWE_WIDE),

    .DOADO(DOADO),
    .DOBDO(DOBDO),
    .DOPADOP(DOPADOP),
    .DOPBDOP(DOPBDOP)
    `undef DUP
  );
endmodule // RAMB36E1

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

  parameter IOSTANDARD = "LVCMOS33";
  parameter IBUF_LOW_PWR = 0;   // TODO: Map this to fasm
  parameter IN_TERM = "NONE";   // Not supported by Vivado ?
  parameter PULLTYPE = "NONE";  // Not supported by Vivado ?
  parameter IO_LOC_PAIRS = "NONE";

  IBUF_VPR # (
    .LVCMOS12_LVCMOS15_LVCMOS18_IN(
      (IOSTANDARD == "LVCMOS12") ||
      (IOSTANDARD == "LVCMOS15") ||
      (IOSTANDARD == "LVCMOS18")
    ),
    .LVCMOS12_LVCMOS15_LVCMOS18_LVCMOS25_LVCMOS33_LVTTL_SLEW_FAST(
      (IOSTANDARD == "LVCMOS12") ||
      (IOSTANDARD == "LVCMOS15") ||
      (IOSTANDARD == "LVCMOS18") ||
      (IOSTANDARD == "LVCMOS25") ||
      (IOSTANDARD == "LVCMOS33") ||
      (IOSTANDARD == "LVTTL") ||
      (IOSTANDARD == "SSTL135") ||
      (IOSTANDARD == "SSTL15")
    ),
    .LVCMOS12_LVCMOS15_LVCMOS18_LVCMOS25_LVCMOS33_LVDS_25_LVTTL_SSTL135_SSTL15_TMDS_33_IN_ONLY(
      (IOSTANDARD == "LVCMOS12") ||
      (IOSTANDARD == "LVCMOS15") ||
      (IOSTANDARD == "LVCMOS18") ||
      (IOSTANDARD == "LVCMOS25") ||
      (IOSTANDARD == "LVCMOS33") ||
      (IOSTANDARD == "LVTTL") ||
      (IOSTANDARD == "SSTL135") ||
      (IOSTANDARD == "SSTL15")
    ),
    .LVCMOS12_LVCMOS15_LVCMOS18_SSTL135_SSTL15_STEPDOWN(
      (IOSTANDARD == "LVCMOS12") ||
      (IOSTANDARD == "LVCMOS15") ||
      (IOSTANDARD == "LVCMOS18") ||
      (IOSTANDARD == "SSTL135") ||
      (IOSTANDARD == "SSTL15")
    ),
    .LVCMOS25_LVCMOS33_LVTTL_IN(
      (IOSTANDARD == "LVCMOS25") ||
      (IOSTANDARD == "LVCMOS33") ||
      (IOSTANDARD == "LVTTL")
    ),
    .SSTL135_SSTL15_IN(
      (IOSTANDARD == "SSTL135") ||
      (IOSTANDARD == "SSTL15")
    ),

    .IN_TERM_UNTUNED_SPLIT_40 (IN_TERM == "UNTUNED_SPLIT_40"),
    .IN_TERM_UNTUNED_SPLIT_50 (IN_TERM == "UNTUNED_SPLIT_50"),
    .IN_TERM_UNTUNED_SPLIT_60 (IN_TERM == "UNTUNED_SPLIT_60"),

    .IBUF_LOW_PWR(IBUF_LOW_PWR),

    .PULLTYPE_PULLUP(PULLTYPE == "PULLUP"),
    .PULLTYPE_PULLDOWN(PULLTYPE == "PULLDOWN"),
    .PULLTYPE_NONE(PULLTYPE == "NONE"),
    .PULLTYPE_KEEPER(PULLTYPE == "KEEPER"),

    .PULLTYPE(PULLTYPE),
    .IOSTANDARD(IOSTANDARD),
    .IO_LOC_PAIRS(IO_LOC_PAIRS)
  ) _TECHMAP_REPLACE_ (
    .I(I),
    .O(O)
  );

endmodule

module OBUF (
  input I,
  output O
  );

  parameter IOSTANDARD = "LVCMOS33";
  parameter DRIVE = 12;
  parameter SLEW = "SLOW";
  parameter PULLTYPE = "NONE";  // Not supported by Vivado ?
  parameter IO_LOC_PAIRS = "NONE";

  OBUFT # (
    .PULLTYPE(PULLTYPE),
    .IOSTANDARD(IOSTANDARD),
    .DRIVE(DRIVE),
    .SLEW(SLEW),
    .IO_LOC_PAIRS(IO_LOC_PAIRS)
  ) _TECHMAP_REPLACE_ (
    .I(I),
    .T(1'b0),
    .O(O)
  );

endmodule

module OBUFT (
  input  I,
  input  T,
  output O
  );

  parameter IOSTANDARD = "LVCMOS33";
  parameter DRIVE = 12;
  parameter SLEW = "SLOW";
  parameter PULLTYPE = "NONE";  // Not supported by Vivado ?
  parameter IO_LOC_PAIRS = "NONE";

  parameter _TECHMAP_CONSTMSK_T_ = 1'bx;
  parameter _TECHMAP_CONSTVAL_T_ = 1'bx;

  wire t;

  // When T=1'b0 Vivado routes it to const1 and enables an inverter in OLOGIC.
  // To mimic this behavior insert a specialized inverter that will go to the
  // OLOGIC site.
  generate if (_TECHMAP_CONSTMSK_T_ == 1'b1 && _TECHMAP_CONSTVAL_T_ == 1'b0) begin
    T_INV t_inv (
    .TI (1'b1),
    .TO (t)
    );

  end else begin
    assign t = T;

  end endgenerate

  OBUFT_VPR # (
    .LVCMOS12_DRIVE_I12(
      (IOSTANDARD == "LVCMOS12" && DRIVE == 12)
    ),
    .LVCMOS12_DRIVE_I4(
      (IOSTANDARD == "LVCMOS12" && DRIVE == 4)
    ),
    .LVCMOS12_LVCMOS15_LVCMOS18_LVCMOS25_LVCMOS33_LVTTL_SLEW_FAST(
      (IOSTANDARD == "LVCMOS12" && SLEW == "FAST") ||
      (IOSTANDARD == "LVCMOS15" && SLEW == "FAST") ||
      (IOSTANDARD == "LVCMOS18" && SLEW == "FAST") ||
      (IOSTANDARD == "LVCMOS25" && SLEW == "FAST") ||
      (IOSTANDARD == "LVCMOS33" && SLEW == "FAST") ||
      (IOSTANDARD == "LVTTL" && SLEW == "FAST")
    ),
    .LVCMOS12_LVCMOS15_LVCMOS18_LVCMOS25_LVCMOS33_LVTTL_SSTL135_SSTL15_SLEW_SLOW(
      (IOSTANDARD == "LVCMOS12" && SLEW == "SLOW") ||
      (IOSTANDARD == "LVCMOS15" && SLEW == "SLOW") ||
      (IOSTANDARD == "LVCMOS18" && SLEW == "SLOW") ||
      (IOSTANDARD == "LVCMOS25" && SLEW == "SLOW") ||
      (IOSTANDARD == "LVCMOS33" && SLEW == "SLOW") ||
      (IOSTANDARD == "LVTTL" && SLEW == "SLOW") ||
      (IOSTANDARD == "SSTL135" && SLEW == "SLOW") ||
      (IOSTANDARD == "SSTL15" && SLEW == "SLOW")
    ),
    .LVCMOS12_LVCMOS15_LVCMOS18_SSTL135_SSTL15_STEPDOWN(
      (IOSTANDARD == "LVCMOS12") ||
      (IOSTANDARD == "LVCMOS15") ||
      (IOSTANDARD == "LVCMOS18") ||
      (IOSTANDARD == "SSTL135") ||
      (IOSTANDARD == "SSTL15")
    ),
    .LVCMOS12_LVCMOS25_DRIVE_I8(
      (IOSTANDARD == "LVCMOS12" && DRIVE == 8) ||
      (IOSTANDARD == "LVCMOS25" && DRIVE == 8)
    ),
    .LVCMOS15_DRIVE_I12(
      (IOSTANDARD == "LVCMOS15" && DRIVE == 12)
    ),
    .LVCMOS15_DRIVE_I8(
      (IOSTANDARD == "LVCMOS15" && DRIVE == 8)
    ),
    .LVCMOS15_LVCMOS18_LVCMOS25_DRIVE_I4(
      (IOSTANDARD == "LVCMOS15" && DRIVE == 4) ||
      (IOSTANDARD == "LVCMOS18" && DRIVE == 4) ||
      (IOSTANDARD == "LVCMOS25" && DRIVE == 4)
    ),
    .LVCMOS15_SSTL15_DRIVE_I16_I_FIXED(
      (IOSTANDARD == "LVCMOS15" && DRIVE == 16) ||
      (IOSTANDARD == "SSTL15")
    ),
    .LVCMOS18_DRIVE_I12_I8(
      (IOSTANDARD == "LVCMOS18" && DRIVE == 12) ||
      (IOSTANDARD == "LVCMOS18" && DRIVE == 8)
    ),
    .LVCMOS18_DRIVE_I16(
      (IOSTANDARD == "LVCMOS18" && DRIVE == 16)
    ),
    .LVCMOS18_DRIVE_I24(
      (IOSTANDARD == "LVCMOS18" && DRIVE == 24)
    ),
    .LVCMOS25_DRIVE_I12(
      (IOSTANDARD == "LVCMOS25" && DRIVE == 12)
    ),
    .LVCMOS25_DRIVE_I16(
      (IOSTANDARD == "LVCMOS25" && DRIVE == 16)
    ),
    .LVCMOS33_DRIVE_I16(
      (IOSTANDARD == "LVCMOS33" && DRIVE == 16)
    ),
    .LVCMOS33_LVTTL_DRIVE_I12_I16(
      (IOSTANDARD == "LVCMOS33" && DRIVE == 12) ||
      (IOSTANDARD == "LVTTL" && DRIVE == 16)
    ),
    .LVCMOS33_LVTTL_DRIVE_I12_I8(
      (IOSTANDARD == "LVCMOS33" && DRIVE == 8) ||
      (IOSTANDARD == "LVTTL" && DRIVE == 12) ||
      (IOSTANDARD == "LVTTL" && DRIVE == 8)
    ),
    .LVCMOS33_LVTTL_DRIVE_I4(
      (IOSTANDARD == "LVCMOS33" && DRIVE == 4) ||
      (IOSTANDARD == "LVTTL" && DRIVE == 4)
    ),
    .LVTTL_DRIVE_I24(
      (IOSTANDARD == "LVTTL" && DRIVE == 24)
    ),
    .SSTL135_DRIVE_I_FIXED(
      (IOSTANDARD == "SSTL135")
    ),
    .SSTL135_SSTL15_SLEW_FAST(
      (IOSTANDARD == "SSTL135" && SLEW == "FAST") ||
      (IOSTANDARD == "SSTL15" && SLEW == "FAST")
    ),

    .PULLTYPE_PULLUP(PULLTYPE == "PULLUP"),
    .PULLTYPE_PULLDOWN(PULLTYPE == "PULLDOWN"),
    .PULLTYPE_NONE(PULLTYPE == "NONE"),
    .PULLTYPE_KEEPER(PULLTYPE == "KEEPER"),

    .PULLTYPE(PULLTYPE),
    .IOSTANDARD(IOSTANDARD),
    .DRIVE(DRIVE),
    .SLEW(SLEW),
    .IO_LOC_PAIRS(IO_LOC_PAIRS)
  ) obuft (
    .I(I),
    .T(t),
    .O(O)
  );

endmodule

module IOBUF (
  input  I,
  input  T,
  output O,
  inout  IO
);

  parameter IOSTANDARD = "LVCMOS33";
  parameter DRIVE = 12;
  parameter SLEW = "SLOW";
  parameter IBUF_LOW_PWR = 0;  // TODO: Map this to fasm
  parameter IN_TERM = "NONE";  // Not supported by Vivado ?
  parameter PULLTYPE = "NONE"; // Not supported by Vivado ?
  parameter IO_LOC_PAIRS = "NONE";

  IOBUF_VPR # (
    .LVCMOS12_DRIVE_I12(
      (IOSTANDARD == "LVCMOS12" && DRIVE == 12)
    ),
    .LVCMOS12_DRIVE_I4(
      (IOSTANDARD == "LVCMOS12" && DRIVE == 4)
    ),
    .LVCMOS12_LVCMOS15_LVCMOS18_IN(
      (IOSTANDARD == "LVCMOS12") ||
      (IOSTANDARD == "LVCMOS15") ||
      (IOSTANDARD == "LVCMOS18")
    ),
    .LVCMOS12_LVCMOS15_LVCMOS18_LVCMOS25_LVCMOS33_LVTTL_SLEW_FAST(
      (IOSTANDARD == "LVCMOS12" && SLEW == "FAST") ||
      (IOSTANDARD == "LVCMOS15" && SLEW == "FAST") ||
      (IOSTANDARD == "LVCMOS18" && SLEW == "FAST") ||
      (IOSTANDARD == "LVCMOS25" && SLEW == "FAST") ||
      (IOSTANDARD == "LVCMOS33" && SLEW == "FAST") ||
      (IOSTANDARD == "LVTTL" && SLEW == "FAST")
    ),
    .LVCMOS12_LVCMOS15_LVCMOS18_LVCMOS25_LVCMOS33_LVTTL_SSTL135_SSTL15_SLEW_SLOW(
      (IOSTANDARD == "LVCMOS12" && SLEW == "SLOW") ||
      (IOSTANDARD == "LVCMOS15" && SLEW == "SLOW") ||
      (IOSTANDARD == "LVCMOS18" && SLEW == "SLOW") ||
      (IOSTANDARD == "LVCMOS25" && SLEW == "SLOW") ||
      (IOSTANDARD == "LVCMOS33" && SLEW == "SLOW") ||
      (IOSTANDARD == "LVTTL" && SLEW == "SLOW") ||
      (IOSTANDARD == "SSTL135" && SLEW == "SLOW") ||
      (IOSTANDARD == "SSTL15" && SLEW == "SLOW")
    ),
    .LVCMOS12_LVCMOS15_LVCMOS18_SSTL135_SSTL15_STEPDOWN(
      (IOSTANDARD == "LVCMOS12") ||
      (IOSTANDARD == "LVCMOS15") ||
      (IOSTANDARD == "LVCMOS18") ||
      (IOSTANDARD == "SSTL135") ||
      (IOSTANDARD == "SSTL15")
    ),
    .LVCMOS12_LVCMOS25_DRIVE_I8(
      (IOSTANDARD == "LVCMOS12" && DRIVE == 8) ||
      (IOSTANDARD == "LVCMOS25" && DRIVE == 8)
    ),
    .LVCMOS15_DRIVE_I12(
      (IOSTANDARD == "LVCMOS15" && DRIVE == 12)
    ),
    .LVCMOS15_DRIVE_I8(
      (IOSTANDARD == "LVCMOS15" && DRIVE == 8)
    ),
    .LVCMOS15_LVCMOS18_LVCMOS25_DRIVE_I4(
      (IOSTANDARD == "LVCMOS15" && DRIVE == 4) ||
      (IOSTANDARD == "LVCMOS18" && DRIVE == 4) ||
      (IOSTANDARD == "LVCMOS25" && DRIVE == 4)
    ),
    .LVCMOS15_SSTL15_DRIVE_I16_I_FIXED(
      (IOSTANDARD == "LVCMOS15" && DRIVE == 16) ||
      (IOSTANDARD == "SSTL15")
    ),
    .LVCMOS18_DRIVE_I12_I8(
      (IOSTANDARD == "LVCMOS18" && DRIVE == 12) ||
      (IOSTANDARD == "LVCMOS18" && DRIVE == 8)
    ),
    .LVCMOS18_DRIVE_I16(
      (IOSTANDARD == "LVCMOS18" && DRIVE == 16)
    ),
    .LVCMOS18_DRIVE_I24(
      (IOSTANDARD == "LVCMOS18" && DRIVE == 24)
    ),
    .LVCMOS25_DRIVE_I12(
      (IOSTANDARD == "LVCMOS25" && DRIVE == 12)
    ),
    .LVCMOS25_DRIVE_I16(
      (IOSTANDARD == "LVCMOS25" && DRIVE == 16)
    ),
    .LVCMOS25_LVCMOS33_LVTTL_IN(
      (IOSTANDARD == "LVCMOS25") ||
      (IOSTANDARD == "LVCMOS33") ||
      (IOSTANDARD == "LVTTL")
    ),
    .LVCMOS33_DRIVE_I16(
      (IOSTANDARD == "LVCMOS33" && DRIVE == 16)
    ),
    .LVCMOS33_LVTTL_DRIVE_I12_I16(
      (IOSTANDARD == "LVCMOS33" && DRIVE == 12) ||
      (IOSTANDARD == "LVTTL" && DRIVE == 16)
    ),
    .LVCMOS33_LVTTL_DRIVE_I12_I8(
      (IOSTANDARD == "LVCMOS33" && DRIVE == 8) ||
      (IOSTANDARD == "LVTTL" && DRIVE == 12) ||
      (IOSTANDARD == "LVTTL" && DRIVE == 8)
    ),
    .LVCMOS33_LVTTL_DRIVE_I4(
      (IOSTANDARD == "LVCMOS33" && DRIVE == 4) ||
      (IOSTANDARD == "LVTTL" && DRIVE == 4)
    ),
    .LVTTL_DRIVE_I24(
      (IOSTANDARD == "LVTTL" && DRIVE == 24)
    ),
    .SSTL135_DRIVE_I_FIXED(
      (IOSTANDARD == "SSTL135")
    ),
    .SSTL135_SSTL15_IN(
      (IOSTANDARD == "SSTL135") ||
      (IOSTANDARD == "SSTL15")
    ),
    .SSTL135_SSTL15_SLEW_FAST(
      (IOSTANDARD == "SSTL135" && SLEW == "FAST") ||
      (IOSTANDARD == "SSTL15" && SLEW == "FAST")
    ),

    .IN_TERM_UNTUNED_SPLIT_40 (IN_TERM == "UNTUNED_SPLIT_40"),
    .IN_TERM_UNTUNED_SPLIT_50 (IN_TERM == "UNTUNED_SPLIT_50"),
    .IN_TERM_UNTUNED_SPLIT_60 (IN_TERM == "UNTUNED_SPLIT_60"),

    .IBUF_LOW_PWR(IBUF_LOW_PWR),

    .PULLTYPE_PULLUP(PULLTYPE == "PULLUP"),
    .PULLTYPE_PULLDOWN(PULLTYPE == "PULLDOWN"),
    .PULLTYPE_NONE(PULLTYPE == "NONE"),
    .PULLTYPE_KEEPER(PULLTYPE == "KEEPER"),

    .PULLTYPE(PULLTYPE),
    .IOSTANDARD(IOSTANDARD),
    .DRIVE(DRIVE),
    .SLEW(SLEW),
    .IO_LOC_PAIRS(IO_LOC_PAIRS)
  ) _TECHMAP_REPLACE_ (
    .I(I),
    .T(T),
    .O(O),
    .IOPAD_$inp(IO),
    .IOPAD_$out(IO)
  );

endmodule


module OBUFTDS (
    input  I,
    input  T,
    output O,
    output OB
);

  parameter IOSTANDARD = "DIFF_SSTL135";  // TODO: Is this the default ?
  parameter SLEW = "FAST";
  parameter IN_TERM = "NONE";  // Not supported by Vivado ?
  parameter PULLTYPE = "NONE"; // Not supported by Vivado ?
  parameter IO_LOC_PAIRS = "NONE";

  parameter HAS_OSERDES = 0; // Set inside yosys/synth.tcl

  parameter _TECHMAP_CONSTMSK_T_ = 1'bx;
  parameter _TECHMAP_CONSTVAL_T_ = 1'bx;

  wire t;

  // When T=1'b0 Vivado routes it to const1 and enables an inverter in OLOGIC.
  // BUT, that happens only when there is an OSERDES with "TQ.BUF" mode.
  //
  // Presence of an OSERDES is detected in the sytnesis script and the parameter
  // HAS_OSERDES is set.
  generate if (_TECHMAP_CONSTMSK_T_ == 1'b1 && _TECHMAP_CONSTVAL_T_ == 1'b0 && HAS_OSERDES == 1) begin
    T_INV t_inv (
    .TI (1'b1),
    .TO (t)
    );

  end else begin
    assign t = T;

  end endgenerate

  wire complementary;

  OBUFTDS_M_VPR # (
    .LVCMOS12_LVCMOS15_LVCMOS18_LVCMOS25_LVCMOS33_LVTTL_SSTL135_SSTL15_SLEW_SLOW(
      (IOSTANDARD == "DIFF_SSTL135" && SLEW == "SLOW") ||
      (IOSTANDARD == "DIFF_SSTL15" && SLEW == "SLOW")
    ),
    .LVCMOS12_LVCMOS15_LVCMOS18_SSTL135_SSTL15_STEPDOWN(
      (IOSTANDARD == "DIFF_SSTL135") ||
      (IOSTANDARD == "DIFF_SSTL15")
    ),
    .LVCMOS15_SSTL15_DRIVE_I16_I_FIXED(
      (IOSTANDARD == "DIFF_SSTL15")
    ),
    .LVDS_25_DRIVE_I_FIXED(
      (IOSTANDARD == "LVDS_25")
    ),
    .LVDS_25_OUT(
      (IOSTANDARD == "LVDS_25")
    ),
    .SSTL135_DRIVE_I_FIXED(
      (IOSTANDARD == "DIFF_SSTL135")
    ),
    .SSTL135_SSTL15_SLEW_FAST(
      (IOSTANDARD == "DIFF_SSTL135" && SLEW == "FAST") ||
      (IOSTANDARD == "DIFF_SSTL15" && SLEW == "FAST")
    ),
    .TMDS_33_DRIVE_I_FIXED(
      (IOSTANDARD == "TMDS_33")
    ),
    .TMDS_33_OUT(
      (IOSTANDARD == "TMDS_33")
    ),

    .IN_TERM_UNTUNED_SPLIT_40 (IN_TERM == "UNTUNED_SPLIT_40"),
    .IN_TERM_UNTUNED_SPLIT_50 (IN_TERM == "UNTUNED_SPLIT_50"),
    .IN_TERM_UNTUNED_SPLIT_60 (IN_TERM == "UNTUNED_SPLIT_60"),

    .PULLTYPE_PULLUP(PULLTYPE == "PULLUP"),
    .PULLTYPE_PULLDOWN(PULLTYPE == "PULLDOWN"),
    .PULLTYPE_NONE(PULLTYPE == "NONE"),
    .PULLTYPE_KEEPER(PULLTYPE == "KEEPER"),

    .PULLTYPE(PULLTYPE),
    .IOSTANDARD(IOSTANDARD),
    .SLEW(SLEW),
    .IO_LOC_PAIRS(IO_LOC_PAIRS)
  ) obuftds_m (
  .I(I),
  .T(t),
  .O(O),
  .OB(complementary)
  );

  OBUFTDS_S_VPR # (
    .LVCMOS12_LVCMOS15_LVCMOS18_LVCMOS25_LVCMOS33_LVTTL_SSTL135_SSTL15_SLEW_SLOW(
      (IOSTANDARD == "DIFF_SSTL135" && SLEW == "SLOW") ||
      (IOSTANDARD == "DIFF_SSTL15" && SLEW == "SLOW")
    ),
    .LVCMOS12_LVCMOS15_LVCMOS18_SSTL135_SSTL15_STEPDOWN(
      (IOSTANDARD == "DIFF_SSTL135") ||
      (IOSTANDARD == "DIFF_SSTL15")
    ),
    .LVCMOS15_SSTL15_DRIVE_I16_I_FIXED(
      (IOSTANDARD == "DIFF_SSTL15")
    ),
    .SSTL135_DRIVE_I_FIXED(
      (IOSTANDARD == "DIFF_SSTL135")
    ),
    .SSTL135_SSTL15_SLEW_FAST(
      (IOSTANDARD == "DIFF_SSTL135" && SLEW == "FAST") ||
      (IOSTANDARD == "DIFF_SSTL15" && SLEW == "FAST")
    ),

    .IN_TERM_UNTUNED_SPLIT_40 (IN_TERM == "UNTUNED_SPLIT_40"),
    .IN_TERM_UNTUNED_SPLIT_50 (IN_TERM == "UNTUNED_SPLIT_50"),
    .IN_TERM_UNTUNED_SPLIT_60 (IN_TERM == "UNTUNED_SPLIT_60"),

    .PULLTYPE_PULLUP(PULLTYPE == "PULLUP"),
    .PULLTYPE_PULLDOWN(PULLTYPE == "PULLDOWN"),
    .PULLTYPE_NONE(PULLTYPE == "NONE"),
    .PULLTYPE_KEEPER(PULLTYPE == "KEEPER"),

    .PULLTYPE(PULLTYPE),
    .IOSTANDARD(IOSTANDARD),
    .SLEW(SLEW),
    .IO_LOC_PAIRS(IO_LOC_PAIRS)
  ) obuftds_s (
  .IB(complementary),
  .OB(OB)
  );

endmodule


module OBUFDS (
    input  I,
    output O,
    output OB
);

  parameter IOSTANDARD = "DIFF_SSTL135";  // TODO: Is this the default ?
  parameter SLEW = "FAST";
  parameter PULLTYPE = "NONE";  // Not supported by Vivado ?
  parameter IO_LOC_PAIRS = "NONE";

  parameter HAS_OSERDES = 0; // Set inside yosys/synth.tcl

  OBUFTDS # (
  .PULLTYPE(PULLTYPE),
  .IOSTANDARD(IOSTANDARD),
  .SLEW(SLEW),
  .HAS_OSERDES(HAS_OSERDES),
  .IO_LOC_PAIRS(IO_LOC_PAIRS)
  ) _TECHMAP_REPLACE_ (
  .I(I),
  .T(1'b0),
  .O(O),
  .OB(OB)
  );

endmodule


module IOBUFDS (
  input  I,
  input  T,
  output O,
  inout  IO,
  inout  IOB
);

  parameter IOSTANDARD = "DIFF_SSTL135";  // TODO: Is this the default ?
  parameter SLEW = "SLOW";
  parameter IN_TERM = "NONE";  // Not supported by Vivado ?
  parameter PULLTYPE = "NONE"; // Not supported by Vivado ?
  parameter IO_LOC_PAIRS = "NONE";

  wire complementary_o;
  wire complementary_i;

  IOBUFDS_M_VPR # (
    .LVCMOS12_LVCMOS15_LVCMOS18_LVCMOS25_LVCMOS33_LVTTL_SSTL135_SSTL15_SLEW_SLOW(
      (IOSTANDARD == "DIFF_SSTL135" && SLEW == "SLOW") ||
      (IOSTANDARD == "DIFF_SSTL15" && SLEW == "SLOW")
    ),
    .LVCMOS12_LVCMOS15_LVCMOS18_SSTL135_SSTL15_STEPDOWN(
      (IOSTANDARD == "DIFF_SSTL135") ||
      (IOSTANDARD == "DIFF_SSTL15")
    ),
    .LVCMOS15_SSTL15_DRIVE_I16_I_FIXED(
      (IOSTANDARD == "DIFF_SSTL15")
    ),
    .LVDS_25_DRIVE_I_FIXED(
      (IOSTANDARD == "LVDS_25")
    ),
    .LVDS_25_OUT(
      (IOSTANDARD == "LVDS_25")
    ),
    .SSTL135_DRIVE_I_FIXED(
      (IOSTANDARD == "DIFF_SSTL135")
    ),
    .LVDS_25_SSTL135_SSTL15_IN_DIFF(
      (IOSTANDARD == "DIFF_SSTL135") ||
      (IOSTANDARD == "DIFF_SSTL15") ||
      (IOSTANDARD == "LVDS_25")
    ),
    .SSTL135_SSTL15_SLEW_FAST(
      (IOSTANDARD == "DIFF_SSTL135" && SLEW == "FAST") ||
      (IOSTANDARD == "DIFF_SSTL15" && SLEW == "FAST")
    ),
    .TMDS_33_IN_DIFF(
      (IOSTANDARD == "TMDS_33")
    ),
    .TMDS_33_DRIVE_I_FIXED(
      (IOSTANDARD == "TMDS_33")
    ),
    .TMDS_33_OUT(
      (IOSTANDARD == "TMDS_33")
    ),

    .IN_TERM_UNTUNED_SPLIT_40 (IN_TERM == "UNTUNED_SPLIT_40"),
    .IN_TERM_UNTUNED_SPLIT_50 (IN_TERM == "UNTUNED_SPLIT_50"),
    .IN_TERM_UNTUNED_SPLIT_60 (IN_TERM == "UNTUNED_SPLIT_60"),

    .PULLTYPE_PULLUP(PULLTYPE == "PULLUP"),
    .PULLTYPE_PULLDOWN(PULLTYPE == "PULLDOWN"),
    .PULLTYPE_NONE(PULLTYPE == "NONE"),
    .PULLTYPE_KEEPER(PULLTYPE == "KEEPER"),

    .PULLTYPE(PULLTYPE),
    .IOSTANDARD(IOSTANDARD),
    .SLEW(SLEW),
    .IO_LOC_PAIRS(IO_LOC_PAIRS)
  ) iobufds_m (
    .I(I),
    .T(T),
    .O(O),
    .IOPAD_$inp(IO),
    .IOPAD_$out(IO),
    .IB(complementary_i),
    .OB(complementary_o)
  );

  IOBUFDS_S_VPR # (
    .LVCMOS12_LVCMOS15_LVCMOS18_LVCMOS25_LVCMOS33_LVTTL_SSTL135_SSTL15_SLEW_SLOW(
      (IOSTANDARD == "DIFF_SSTL135" && SLEW == "SLOW") ||
      (IOSTANDARD == "DIFF_SSTL15" && SLEW == "SLOW")
    ),
    .LVCMOS12_LVCMOS15_LVCMOS18_SSTL135_SSTL15_STEPDOWN(
      (IOSTANDARD == "DIFF_SSTL135") ||
      (IOSTANDARD == "DIFF_SSTL15")
    ),
    .LVCMOS15_SSTL15_DRIVE_I16_I_FIXED(
      (IOSTANDARD == "DIFF_SSTL15")
    ),
    .SSTL135_DRIVE_I_FIXED(
      (IOSTANDARD == "DIFF_SSTL135")
    ),
    .LVDS_25_SSTL135_SSTL15_IN_DIFF(
      (IOSTANDARD == "DIFF_SSTL135") ||
      (IOSTANDARD == "DIFF_SSTL15") ||
      (IOSTANDARD == "LVDS_25")
    ),
    .SSTL135_SSTL15_SLEW_FAST(
      (IOSTANDARD == "DIFF_SSTL135" && SLEW == "FAST") ||
      (IOSTANDARD == "DIFF_SSTL15" && SLEW == "FAST")
    ),

    .IN_TERM_UNTUNED_SPLIT_40 (IN_TERM == "UNTUNED_SPLIT_40"),
    .IN_TERM_UNTUNED_SPLIT_50 (IN_TERM == "UNTUNED_SPLIT_50"),
    .IN_TERM_UNTUNED_SPLIT_60 (IN_TERM == "UNTUNED_SPLIT_60"),

    .PULLTYPE_PULLUP(PULLTYPE == "PULLUP"),
    .PULLTYPE_PULLDOWN(PULLTYPE == "PULLDOWN"),
    .PULLTYPE_NONE(PULLTYPE == "NONE"),
    .PULLTYPE_KEEPER(PULLTYPE == "KEEPER"),

    .PULLTYPE(PULLTYPE),
    .IOSTANDARD(IOSTANDARD),
    .SLEW(SLEW),
    .IO_LOC_PAIRS(IO_LOC_PAIRS)
  ) iobufds_s (
    .IB(complementary_o),
    .OB(complementary_i),
    .IOPAD_$inp(IOB),
    .IOPAD_$out(IOB)
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
  parameter IO_LOC_PAIRS = "NONE";

  if (DATA_RATE_OQ == "DDR" &&
      !(DATA_WIDTH == 4 || DATA_WIDTH == 6 || DATA_WIDTH == 8)) begin
    wire _TECHMAP_FAIL_;
  end

  if (DATA_RATE_OQ == "SDR" &&
      !(DATA_WIDTH >= 2 || DATA_WIDTH <= 8)) begin
    wire _TECHMAP_FAIL_;
  end

  if ((DATA_RATE_TQ == "SDR" || DATA_RATE_TQ == "BUF") &&
      TRISTATE_WIDTH != 1) begin
    wire _TECHMAP_FAIL_;
  end

  if (DATA_RATE_OQ == "SDR" && DATA_RATE_TQ == "DDR") begin
    wire _TECHMAP_FAIL_;
  end

  if (TRISTATE_WIDTH != 1 && TRISTATE_WIDTH != 4) begin
    wire _TECHMAP_FAIL_;
  end

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
  parameter _TECHMAP_CONSTMSK_TQ_ = 1'bx;
  parameter _TECHMAP_CONSTVAL_TQ_ = 1'bx;

  localparam INV_D1 = (_TECHMAP_CONSTMSK_D1_ == 1)  ? !_TECHMAP_CONSTVAL_D1_ ^ IS_D1_INVERTED :
                      (_TECHMAP_CONSTVAL_D1_ === 0) ? ~IS_D1_INVERTED : IS_D1_INVERTED;
  wire d1 = (_TECHMAP_CONSTMSK_D1_ == 1)  ? 1'b1 :
            (_TECHMAP_CONSTVAL_D1_ === 0) ? 1'b1 : D1;

  localparam INV_D2 = (_TECHMAP_CONSTMSK_D2_ == 1)  ? !_TECHMAP_CONSTVAL_D2_ ^ IS_D2_INVERTED :
                      (_TECHMAP_CONSTVAL_D2_ === 0) ? ~IS_D2_INVERTED : IS_D2_INVERTED;
  wire d2 = (_TECHMAP_CONSTMSK_D2_ == 1)  ? 1'b1 :
            (_TECHMAP_CONSTVAL_D2_ === 0) ? 1'b1 : D2;

  localparam INV_D3 = (_TECHMAP_CONSTMSK_D3_ == 1)  ? !_TECHMAP_CONSTVAL_D3_ ^ IS_D3_INVERTED :
                      (_TECHMAP_CONSTVAL_D3_ === 0) ? ~IS_D3_INVERTED : IS_D3_INVERTED;
  wire d3 = (_TECHMAP_CONSTMSK_D3_ == 1)  ? 1'b1 :
            (_TECHMAP_CONSTVAL_D3_ === 0) ? 1'b1 : D3;

  localparam INV_D4 = (_TECHMAP_CONSTMSK_D4_ == 1)  ? !_TECHMAP_CONSTVAL_D4_ ^ IS_D4_INVERTED :
                      (_TECHMAP_CONSTVAL_D4_ === 0) ? ~IS_D4_INVERTED : IS_D4_INVERTED;
  wire d4 = (_TECHMAP_CONSTMSK_D4_ == 1)  ? 1'b1 :
            (_TECHMAP_CONSTVAL_D4_ === 0) ? 1'b1 : D4;

  localparam INV_D5 = (_TECHMAP_CONSTMSK_D5_ == 1)  ? !_TECHMAP_CONSTVAL_D5_ ^ IS_D5_INVERTED :
                      (_TECHMAP_CONSTVAL_D5_ === 0) ? ~IS_D5_INVERTED : IS_D5_INVERTED;
  wire d5 = (_TECHMAP_CONSTMSK_D5_ == 1)  ? 1'b1 :
            (_TECHMAP_CONSTVAL_D5_ === 0) ? 1'b1 : D5;

  localparam INV_D6 = (_TECHMAP_CONSTMSK_D6_ == 1)  ? !_TECHMAP_CONSTVAL_D6_ ^ IS_D6_INVERTED :
                      (_TECHMAP_CONSTVAL_D6_ === 0) ? ~IS_D6_INVERTED : IS_D6_INVERTED;
  wire d6 = (_TECHMAP_CONSTMSK_D6_ == 1)  ? 1'b1 :
            (_TECHMAP_CONSTVAL_D6_ === 0) ? 1'b1 : D6;

  localparam INV_D7 = (_TECHMAP_CONSTMSK_D7_ == 1)  ? !_TECHMAP_CONSTVAL_D7_ ^ IS_D7_INVERTED :
                      (_TECHMAP_CONSTVAL_D7_ === 0) ? ~IS_D7_INVERTED : IS_D7_INVERTED;
  wire d7 = (_TECHMAP_CONSTMSK_D7_ == 1)  ? 1'b1 :
            (_TECHMAP_CONSTVAL_D7_ === 0) ? 1'b1 : D7;

  localparam INV_D8 = (_TECHMAP_CONSTMSK_D8_ == 1)  ? !_TECHMAP_CONSTVAL_D8_ ^ IS_D8_INVERTED :
                      (_TECHMAP_CONSTVAL_D8_ === 0) ? ~IS_D8_INVERTED : IS_D8_INVERTED;
  wire d8 = (_TECHMAP_CONSTMSK_D8_ == 1)  ? 1'b1 :
            (_TECHMAP_CONSTVAL_D8_ === 0) ? 1'b1 : D8;

  localparam TQ_USED = (_TECHMAP_CONSTVAL_TQ_ === 1'bx && (DATA_RATE_TQ == "DDR" || DATA_RATE_TQ == "SDR")) ? 1'b1 : 1'b0;

  parameter _TECHMAP_CONSTMSK_T1_ = 0;
  parameter _TECHMAP_CONSTVAL_T1_ = 0;
  parameter _TECHMAP_CONSTMSK_T2_ = 0;
  parameter _TECHMAP_CONSTVAL_T2_ = 0;
  parameter _TECHMAP_CONSTMSK_T3_ = 0;
  parameter _TECHMAP_CONSTVAL_T3_ = 0;
  parameter _TECHMAP_CONSTMSK_T4_ = 0;
  parameter _TECHMAP_CONSTVAL_T4_ = 0;

  localparam INV_T1 = (_TECHMAP_CONSTMSK_T1_ == 1)  ? !_TECHMAP_CONSTVAL_T1_ ^ IS_T1_INVERTED :
                      (_TECHMAP_CONSTVAL_T1_ === 0) ? ~IS_T1_INVERTED : IS_T1_INVERTED;
  wire t1 = (_TECHMAP_CONSTMSK_T1_ == 1)  ? 1'b1 :
            (_TECHMAP_CONSTVAL_T1_ === 0) ? 1'b1 : T1;

  localparam INV_T2 = (_TECHMAP_CONSTMSK_T2_ == 1)  ? !_TECHMAP_CONSTVAL_T2_ ^ IS_T2_INVERTED :
                      (_TECHMAP_CONSTVAL_T2_ === 0) ? ~IS_T2_INVERTED : IS_T2_INVERTED;
  wire t2 = (_TECHMAP_CONSTMSK_T2_ == 1)  ? 1'b1 :
            (_TECHMAP_CONSTVAL_T2_ === 0) ? 1'b1 : T2;

  localparam INV_T3 = (_TECHMAP_CONSTMSK_T3_ == 1)  ? !_TECHMAP_CONSTVAL_T3_ ^ IS_T3_INVERTED :
                      (_TECHMAP_CONSTVAL_T3_ === 0) ? ~IS_T3_INVERTED : IS_T3_INVERTED;
  wire t3 = (_TECHMAP_CONSTMSK_T3_ == 1)  ? 1'b1 :
            (_TECHMAP_CONSTVAL_T3_ === 0) ? 1'b1 : T3;

  localparam INV_T4 = (_TECHMAP_CONSTMSK_T4_ == 1)  ? !_TECHMAP_CONSTVAL_T4_ ^ IS_T4_INVERTED :
                      (_TECHMAP_CONSTVAL_T4_ === 0) ? ~IS_T4_INVERTED : IS_T4_INVERTED;
  wire t4 = (_TECHMAP_CONSTMSK_T4_ == 1)  ? 1'b1 :
            (_TECHMAP_CONSTVAL_T4_ === 0) ? 1'b1 : T4;

  OSERDESE2_VPR #(
      .SERDES_MODE_SLAVE            (SERDES_MODE == "SLAVE"),
      .TRISTATE_WIDTH_W4            (TRISTATE_WIDTH == 4),
      .DATA_RATE_OQ_DDR             (DATA_RATE_OQ == "DDR"),
      .DATA_RATE_OQ_SDR             (DATA_RATE_OQ == "SDR"),
      .DATA_RATE_TQ_BUF             (DATA_RATE_TQ == "BUF"),
      .DATA_RATE_TQ_DDR             (DATA_RATE_TQ == "DDR"),
      .DATA_RATE_TQ_SDR             (DATA_RATE_TQ == "SDR"),
      .DATA_WIDTH_DDR_W4            (DATA_RATE_OQ == "DDR" && DATA_WIDTH == 4),
      .DATA_WIDTH_DDR_W6            (DATA_RATE_OQ == "DDR" && DATA_WIDTH == 6),
      .DATA_WIDTH_DDR_W8            (DATA_RATE_OQ == "DDR" && DATA_WIDTH == 8),
      .DATA_WIDTH_SDR_W2            (DATA_RATE_OQ == "SDR" && DATA_WIDTH == 2),
      .DATA_WIDTH_SDR_W3            (DATA_RATE_OQ == "SDR" && DATA_WIDTH == 3),
      .DATA_WIDTH_SDR_W4            (DATA_RATE_OQ == "SDR" && DATA_WIDTH == 4),
      .DATA_WIDTH_SDR_W5            (DATA_RATE_OQ == "SDR" && DATA_WIDTH == 5),
      .DATA_WIDTH_SDR_W6            (DATA_RATE_OQ == "SDR" && DATA_WIDTH == 6),
      .DATA_WIDTH_SDR_W7            (DATA_RATE_OQ == "SDR" && DATA_WIDTH == 7),
      .DATA_WIDTH_SDR_W8            (DATA_RATE_OQ == "SDR" && DATA_WIDTH == 8),
      .ZINIT_OQ                     (!INIT_OQ),
      .ZINIT_TQ                     (!INIT_TQ),
      .ZSRVAL_OQ                    (!SRVAL_OQ),
      .ZSRVAL_TQ                    (!SRVAL_TQ),
      .IS_CLKDIV_INVERTED           (IS_CLKDIV_INVERTED),
      .IS_D1_INVERTED               (INV_D1),
      .IS_D2_INVERTED               (INV_D2),
      .IS_D3_INVERTED               (INV_D3),
      .IS_D4_INVERTED               (INV_D4),
      .IS_D5_INVERTED               (INV_D5),
      .IS_D6_INVERTED               (INV_D6),
      .IS_D7_INVERTED               (INV_D7),
      .IS_D8_INVERTED               (INV_D8),
      .ZINV_CLK                     (!IS_CLK_INVERTED),
      .ZINV_T1                      (!INV_T1),
      .ZINV_T2                      (!INV_T2),
      .ZINV_T3                      (!INV_T3),
      .ZINV_T4                      (!INV_T4),
      .TQ_USED                      (TQ_USED)
  ) _TECHMAP_REPLACE_ (
    .CLK    (CLK),
    .CLKDIV (CLKDIV),
    .D1     (d1),
    .D2     (d2),
    .D3     (d3),
    .D4     (d4),
    .D5     (d5),
    .D6     (d6),
    .D7     (d7),
    .D8     (d8),
    .OCE    (OCE),
    .RST    (RST),
    .T1     (t1),
    .T2     (t2),
    .T3     (t3),
    .T4     (t4),
    .TCE    (TCE),
    .OFB    (OFB),
    .OQ     (OQ),
    .TFB    (TFB),
    .TQ     (TQ)
  );

endmodule

module ISERDESE2 (
  input  BITSLIP,
  input  CE1,
  input  CE2,
  input  CLK,
  input  CLKB,
  input  CLKDIV,
  input  RST,
  input  D,
  input  DDLY,
  output Q1,
  output Q2,
  output Q3,
  output Q4,
  output Q5,
  output Q6,
  output Q7,
  output Q8
  );

  parameter DATA_RATE = "DDR";
  parameter DATA_WIDTH = 4;

  parameter NUM_CE = 2;

  parameter DYN_CLKDIV_INV_EN = "FALSE";
  parameter DYN_CLK_INV_EN = "FALSE";

  parameter INTERFACE_TYPE = "MEMORY";

  parameter IOBDELAY = "NONE";
  parameter SERDES_MODE = "MASTER";

  parameter [0:0] INIT_Q1 = 1'b0;
  parameter [0:0] INIT_Q2 = 1'b0;
  parameter [0:0] INIT_Q3 = 1'b0;
  parameter [0:0] INIT_Q4 = 1'b0;

  parameter [0:0] SRVAL_Q1 = 1'b0;
  parameter [0:0] SRVAL_Q2 = 1'b0;
  parameter [0:0] SRVAL_Q3 = 1'b0;
  parameter [0:0] SRVAL_Q4 = 1'b0;

  parameter [0:0] IS_D_INVERTED = 1'b0;
  parameter [0:0] IS_CLK_INVERTED = 1'b0;

  if (INTERFACE_TYPE == "NETWORKING") begin
    if (DATA_RATE == "DDR" &&
          (DATA_WIDTH != 4 &&
           DATA_WIDTH != 6 &&
           DATA_WIDTH != 8)) begin
      wire _TECHMAP_FAIL_;
    end

    if (DATA_RATE == "SDR" &&
        (DATA_WIDTH < 2 ||
         DATA_WIDTH > 8)) begin
      wire _TECHMAP_FAIL_;
    end
  end

  if (INTERFACE_TYPE == "MEMORY"      ||
      INTERFACE_TYPE == "MEMORY_DDR3" ||
      INTERFACE_TYPE == "MEMORY_QDR") begin

    if (DATA_RATE == "SDR") begin
      wire _TECHMAP_FAIL_;
    end

    if (DATA_RATE == "DDR" &&
        (DATA_WIDTH != 4 &&
         DATA_WIDTH != 6 &&
         DATA_WIDTH != 8)) begin
      wire _TECHMAP_FAIL_;
    end
  end

  if (NUM_CE != 1 && NUM_CE != 2) begin
    wire _TECHMAP_FAIL_ = 1'b1;
  end

  parameter _TECHMAP_CONSTMSK_D_ = 1'b1;
  parameter _TECHMAP_CONSTVAL_D_ = 1'bx;
  parameter _TECHMAP_CONSTMSK_DDLY_ = 1'b1;
  parameter _TECHMAP_CONSTVAL_DDLY_ = 1'bx;

  localparam [0:0] MEMORY_DDR3_4     = (INTERFACE_TYPE == "MEMORY_DDR3" && DATA_RATE == "DDR" && DATA_WIDTH == 4);
  localparam [0:0] MEMORY_DDR_4      = (INTERFACE_TYPE == "MEMORY"      && DATA_RATE == "DDR" && DATA_WIDTH == 4);
  localparam [0:0] MEMORY_QDR_4      = (INTERFACE_TYPE == "MEMORY_QDR"  && DATA_RATE == "DDR" && DATA_WIDTH == 4);

  localparam [0:0] NETWORKING_SDR_2  = (INTERFACE_TYPE == "NETWORKING"  && DATA_RATE == "SDR" && DATA_WIDTH == 2);
  localparam [0:0] NETWORKING_SDR_3  = (INTERFACE_TYPE == "NETWORKING"  && DATA_RATE == "SDR" && DATA_WIDTH == 3);
  localparam [0:0] NETWORKING_SDR_4  = (INTERFACE_TYPE == "NETWORKING"  && DATA_RATE == "SDR" && DATA_WIDTH == 4);
  localparam [0:0] NETWORKING_SDR_5  = (INTERFACE_TYPE == "NETWORKING"  && DATA_RATE == "SDR" && DATA_WIDTH == 5);
  localparam [0:0] NETWORKING_SDR_6  = (INTERFACE_TYPE == "NETWORKING"  && DATA_RATE == "SDR" && DATA_WIDTH == 6);
  localparam [0:0] NETWORKING_SDR_7  = (INTERFACE_TYPE == "NETWORKING"  && DATA_RATE == "SDR" && DATA_WIDTH == 7);
  localparam [0:0] NETWORKING_SDR_8  = (INTERFACE_TYPE == "NETWORKING"  && DATA_RATE == "SDR" && DATA_WIDTH == 8);

  localparam [0:0] NETWORKING_DDR_4  = (INTERFACE_TYPE == "NETWORKING"  && DATA_RATE == "DDR" && DATA_WIDTH == 4);
  localparam [0:0] NETWORKING_DDR_6  = (INTERFACE_TYPE == "NETWORKING"  && DATA_RATE == "DDR" && DATA_WIDTH == 6);
  localparam [0:0] NETWORKING_DDR_8  = (INTERFACE_TYPE == "NETWORKING"  && DATA_RATE == "DDR" && DATA_WIDTH == 8);
  localparam [0:0] NETWORKING_DDR_10 = (INTERFACE_TYPE == "NETWORKING"  && DATA_RATE == "DDR" && DATA_WIDTH == 10);
  localparam [0:0] NETWORKING_DDR_14 = (INTERFACE_TYPE == "NETWORKING"  && DATA_RATE == "DDR" && DATA_WIDTH == 14);

  localparam [0:0] OVERSAMPLE_DDR_4  = (INTERFACE_TYPE == "OVERSAMPLE"  && DATA_RATE == "DDR" && DATA_WIDTH == 4);

  if (_TECHMAP_CONSTMSK_D_ == 1'b1) begin
      ISERDESE2_IDELAY_VPR #(

          .MEMORY_DDR3_4                (MEMORY_DDR3_4),
          .MEMORY_DDR_4                 (MEMORY_DDR_4),
          .MEMORY_QDR_4                 (MEMORY_QDR_4),

          .NETWORKING_SDR_2             (NETWORKING_SDR_2),
          .NETWORKING_SDR_3             (NETWORKING_SDR_3),
          .NETWORKING_SDR_4             (NETWORKING_SDR_4),
          .NETWORKING_SDR_5             (NETWORKING_SDR_5),
          .NETWORKING_SDR_6             (NETWORKING_SDR_6),
          .NETWORKING_SDR_7             (NETWORKING_SDR_7),
          .NETWORKING_SDR_8             (NETWORKING_SDR_8),

          .NETWORKING_DDR_4             (NETWORKING_DDR_4),
          .NETWORKING_DDR_6             (NETWORKING_DDR_6),
          .NETWORKING_DDR_8             (NETWORKING_DDR_8),
          .NETWORKING_DDR_10            (NETWORKING_DDR_10),
          .NETWORKING_DDR_14            (NETWORKING_DDR_14),

          .OVERSAMPLE_DDR_4             (OVERSAMPLE_DDR_4),

          .NUM_CE_N1                    (NUM_CE == 1),
          .NUM_CE_N2                    (NUM_CE == 2),

          .IOBDELAY_IFD                 (IOBDELAY == "IFD" || IOBDELAY == "BOTH"),
          .IOBDELAY_IBUF                (IOBDELAY == "IBUF" || IOBDELAY == "BOTH"),

          // Inverters
          .ZINIT_Q1                     (!INIT_Q1),
          .ZINIT_Q2                     (!INIT_Q2),
          .ZINIT_Q3                     (!INIT_Q3),
          .ZINIT_Q4                     (!INIT_Q4),
          .ZSRVAL_Q1                    (!SRVAL_Q1),
          .ZSRVAL_Q2                    (!SRVAL_Q2),
          .ZSRVAL_Q3                    (!SRVAL_Q3),
          .ZSRVAL_Q4                    (!SRVAL_Q4),

          .ZINV_C                       (!IS_CLK_INVERTED)
      ) _TECHMAP_REPLACE_ (
       .BITSLIP     (BITSLIP),
       .CE1         (CE1),
       .CE2         (CE2),
       .CLK         (CLK),
       .CLKB        (CLKB),
       .CLKDIV      (CLKDIV),
       .RST         (RST),
       .DDLY        (DDLY),
       .Q1          (Q1),
       .Q2          (Q2),
       .Q3          (Q3),
       .Q4          (Q4),
       .Q5          (Q5),
       .Q6          (Q6),
       .Q7          (Q7),
       .Q8          (Q8)
      );
    end else if (_TECHMAP_CONSTMSK_DDLY_ == 1'b1) begin
      ISERDESE2_NO_IDELAY_VPR #(

          .MEMORY_DDR3_4                (MEMORY_DDR3_4),
          .MEMORY_DDR_4                 (MEMORY_DDR_4),
          .MEMORY_QDR_4                 (MEMORY_QDR_4),

          .NETWORKING_SDR_2             (NETWORKING_SDR_2),
          .NETWORKING_SDR_3             (NETWORKING_SDR_3),
          .NETWORKING_SDR_4             (NETWORKING_SDR_4),
          .NETWORKING_SDR_5             (NETWORKING_SDR_5),
          .NETWORKING_SDR_6             (NETWORKING_SDR_6),
          .NETWORKING_SDR_7             (NETWORKING_SDR_7),
          .NETWORKING_SDR_8             (NETWORKING_SDR_8),

          .NETWORKING_DDR_4             (NETWORKING_DDR_4),
          .NETWORKING_DDR_6             (NETWORKING_DDR_6),
          .NETWORKING_DDR_8             (NETWORKING_DDR_8),
          .NETWORKING_DDR_10            (NETWORKING_DDR_10),
          .NETWORKING_DDR_14            (NETWORKING_DDR_14),

          .OVERSAMPLE_DDR_4             (OVERSAMPLE_DDR_4),

          .NUM_CE_N1                    (NUM_CE == 1),
          .NUM_CE_N2                    (NUM_CE == 2),

          .IOBDELAY_IFD                 (IOBDELAY == "IFD" || IOBDELAY == "BOTH"),
          .IOBDELAY_IBUF                (IOBDELAY == "IBUF" || IOBDELAY == "BOTH"),

          // Inverters
          .ZINIT_Q1                     (!INIT_Q1),
          .ZINIT_Q2                     (!INIT_Q2),
          .ZINIT_Q3                     (!INIT_Q3),
          .ZINIT_Q4                     (!INIT_Q4),
          .ZSRVAL_Q1                    (!SRVAL_Q1),
          .ZSRVAL_Q2                    (!SRVAL_Q2),
          .ZSRVAL_Q3                    (!SRVAL_Q3),
          .ZSRVAL_Q4                    (!SRVAL_Q4),

          .ZINV_D                       (!IS_D_INVERTED),

          .ZINV_C                       (!IS_CLK_INVERTED)
      ) _TECHMAP_REPLACE_ (
       .BITSLIP     (BITSLIP),
       .CE1         (CE1),
       .CE2         (CE2),
       .CLK         (CLK),
       .CLKB        (CLKB),
       .CLKDIV      (CLKDIV),
       .RST         (RST),
       .D           (D),
       .Q1          (Q1),
       .Q2          (Q2),
       .Q3          (Q3),
       .Q4          (Q4),
       .Q5          (Q5),
       .Q6          (Q6),
       .Q7          (Q7),
       .Q8          (Q8)
      );
    end else begin
        wire _TECHMAP_FAIL_;
    end


endmodule

// ============================================================================
// IDDR/ODDR

module IDDR_2CLK (
  output Q1,
  output Q2,
  input  C,
  input  CB,
  input  CE,
  input  D,
  input  R,
  input  S,
);

  parameter DDR_CLK_EDGE = "OPPOSITE_EDGE";
  parameter INIT_Q1 = 1'b0;
  parameter INIT_Q2 = 1'b0;
  parameter [0:0] IS_C_INVERTED  = 1'b0;
  parameter [0:0] IS_CB_INVERTED = 1'b0;
  parameter [0:0] IS_D_INVERTED  = 1'b0;
  parameter SRTYPE = "SYNC";

  parameter _TECHMAP_CONSTMSK_R_ = 1'b1;
  parameter _TECHMAP_CONSTVAL_R_ = 1'bx;
  parameter _TECHMAP_CONSTMSK_S_ = 1'b1;
  parameter _TECHMAP_CONSTVAL_S_ = 1'bx;

  localparam [0:0] R_USED = (_TECHMAP_CONSTMSK_R_ != 1'b1);
  localparam [0:0] S_USED = (_TECHMAP_CONSTMSK_S_ != 1'b1);

  wire SR;

  localparam SRVAL = (!R_USED) ? 1'b1 : 1'b0;
  localparam SRUSED = 1'b1;

  generate if (!R_USED && !S_USED) begin
    assign SR = 1'b0;
  end else if (R_USED && !S_USED) begin
    assign SR = R;
  end else if (!R_USED && S_USED) begin
    assign SR = S;
  end else begin
    assign SR = 1'bx;
    $error("Both S and R cannot be used simultaneously");
  end endgenerate

  localparam INIT_Q3 = (DDR_CLK_EDGE != "OPPOSITE_EDGE") ? INIT_Q1 : 1'b1;
  localparam INIT_Q4 = (DDR_CLK_EDGE != "OPPOSITE_EDGE") ? INIT_Q2 : 1'b1;
  localparam SRVAL34 = (DDR_CLK_EDGE != "OPPOSITE_EDGE") ? SRVAL : 1'b1;

  IDDR_VPR #(
    .ZINV_D         (!IS_D_INVERTED),
    .ZINV_C         (!IS_C_INVERTED),
    .SRTYPE_SYNC    (SRTYPE == "SYNC"),
    .SAME_EDGE      (DDR_CLK_EDGE == "SAME_EDGE"),
    .OPPOSITE_EDGE  (DDR_CLK_EDGE == "OPPOSITE_EDGE"),
    .ZINIT_Q1       (!INIT_Q1),
    .ZINIT_Q2       (!INIT_Q2),
    .ZINIT_Q3       (!INIT_Q3),
    .ZINIT_Q4       (!INIT_Q4),
    .ZSRVAL_Q12     (!SRVAL),
    .ZSRVAL_Q34     (!SRVAL34)

  ) _TECHMAP_REPLACE_ (
    .CK  (C),
    .CKB (CB),
    .CE  (CE),
    .SR  (SR),
    .D   (D),
    .Q1  (Q1),
    .Q2  (Q2)
  );

endmodule

module IDDR (
  output Q1,
  output Q2,
  input  C,
  input  CE,
  input  D,
  input  R,
  input  S,
);

  parameter DDR_CLK_EDGE = "OPPOSITE_EDGE";
  parameter INIT_Q1 = 1'b0;
  parameter INIT_Q2 = 1'b0;
  parameter [0:0] IS_C_INVERTED = 1'b0;
  parameter [0:0] IS_D_INVERTED = 1'b0;
  parameter SRTYPE = "SYNC";

  IDDR_2CLK # (
    .DDR_CLK_EDGE   (DDR_CLK_EDGE),
    .SRTYPE         (SRTYPE),
    .INIT_Q1        (INIT_Q1),
    .INIT_Q2        (INIT_Q2),
    .IS_C_INVERTED  (IS_C_INVERTED),
    .IS_CB_INVERTED (!IS_C_INVERTED),
    .IS_D_INVERTED  (IS_D_INVERTED)

  ) _TECHMAP_REPLACE_ (
    .C  (C),
    .CB (C),
    .CE (CE),
    .S  (S),
    .R  (R),
    .D  (D),
    .Q1 (Q1),
    .Q2 (Q2)
  );

endmodule

module ODDR (
  input  C,
  input  CE,
  input  R,
  input  S,
  input  D1,
  input  D2,
  output Q
);

  parameter DDR_CLK_EDGE = "OPPOSITE_EDGE";
  parameter INIT = 1'b0;
  parameter [0:0] IS_C_INVERTED = 1'b0;
  parameter [0:0] IS_D1_INVERTED = 1'b0;
  parameter [0:0] IS_D2_INVERTED = 1'b0;
  parameter SRTYPE = "SYNC";

  parameter _TECHMAP_CONSTMSK_R_ = 1'b1;
  parameter _TECHMAP_CONSTVAL_R_ = 1'bx;
  parameter _TECHMAP_CONSTMSK_S_ = 1'b1;
  parameter _TECHMAP_CONSTVAL_S_ = 1'bx;

  localparam [0:0] R_USED = (_TECHMAP_CONSTMSK_R_ != 1'b1);
  localparam [0:0] S_USED = (_TECHMAP_CONSTMSK_S_ != 1'b1);

  wire SR;

  localparam SRVAL = (!R_USED) ? 1'b1 : 1'b0;

  generate if (!R_USED && !S_USED) begin
    assign SR = 1'b0;
  end else if (R_USED && !S_USED) begin
    assign SR = R;
  end else if (!R_USED && S_USED) begin
    assign SR = S;
  end else begin
    assign SR = 1'bx;
    $error("Both S and R cannot be used simultaneously");
  end endgenerate

  parameter _TECHMAP_CONSTMSK_D1_ = 0;
  parameter _TECHMAP_CONSTVAL_D1_ = 0;
  parameter _TECHMAP_CONSTMSK_D2_ = 0;
  parameter _TECHMAP_CONSTVAL_D2_ = 0;

  localparam INV_D1 = (_TECHMAP_CONSTMSK_D1_ ==  1) ? !_TECHMAP_CONSTVAL_D1_ ^ IS_D1_INVERTED :
                       (_TECHMAP_CONSTVAL_D1_ === 0) ? IS_D1_INVERTED : !IS_D1_INVERTED;
  wire d1 = (_TECHMAP_CONSTMSK_D1_ ==  1) ? 1'b1 :
            (_TECHMAP_CONSTVAL_D1_ === 0) ? 1'b1 : D1;

  localparam INV_D2 = (_TECHMAP_CONSTMSK_D2_ ==  1) ? !_TECHMAP_CONSTVAL_D2_ ^ IS_D2_INVERTED :
                       (_TECHMAP_CONSTVAL_D2_ === 0) ? IS_D2_INVERTED : !IS_D2_INVERTED;
  wire d2 = (_TECHMAP_CONSTMSK_D2_ ==  1) ? 1'b1 :
            (_TECHMAP_CONSTVAL_D2_ === 0) ? 1'b1 : D2;

  ODDR_VPR # (
    .ZINV_CLK       (!IS_C_INVERTED),
    .INV_D1         (INV_D1),
    .INV_D2         (INV_D2),
    .ZINV_D1        (!INV_D1),
    .ZINV_D2        (!INV_D2),
    .SRTYPE_SYNC    ( SRTYPE == "SYNC"),
    .SAME_EDGE      ( (DDR_CLK_EDGE != "OPPOSITE_EDGE") ^ IS_C_INVERTED),
    .ZINIT_Q        (!INIT),
    .ZSRVAL_Q       (!SRVAL)
  ) _TECHMAP_REPLACE_ (
    .CK (C),
    .CE (CE),
    .SR (SR),
    .D1 (d1),
    .D2 (d2),
    .Q  (Q)
  );

endmodule


// ============================================================================
// IDELAYE2

module IDELAYE2 (
  input C,
  input CE,
  input CINVCTRL,
  input CNTVALUEIN0,
  input CNTVALUEIN1,
  input CNTVALUEIN2,
  input CNTVALUEIN3,
  input CNTVALUEIN4,
  input DATAIN,
  input IDATAIN,
  input INC,
  input LD,
  input LDPIPEEN,
  input REGRST,

  output CNTVALUEOUT0,
  output CNTVALUEOUT1,
  output CNTVALUEOUT2,
  output CNTVALUEOUT3,
  output CNTVALUEOUT4,
  output DATAOUT
  );

  parameter CINVCTRL_SEL = "FALSE";
  parameter DELAY_SRC = "IDATAIN";
  parameter HIGH_PERFORMANCE_MODE = "FALSE";
  parameter IDELAY_TYPE = "FIXED";
  parameter PIPE_SEL = "FALSE";

  parameter REFCLK_FREQUENCY = 200.0;
  parameter SIGNAL_PATTERN = "DATA";

  parameter [4:0] IDELAY_VALUE = 5'b00000;

  parameter [0:0] IS_DATAIN_INVERTED = 1'b0;
  parameter [0:0] IS_IDATAIN_INVERTED = 1'b0;

  localparam [4:0] ZIDELAY_VALUE = ~IDELAY_VALUE;
  localparam [0:0] NOT_USING_CNTVALUEIN = (IDELAY_TYPE == "FIXED" || IDELAY_TYPE == "VARIABLE");

  parameter _TECHMAP_CONSTMSK_IDATAIN_ = 1'b1;
  parameter _TECHMAP_CONSTVAL_IDATAIN_ = 1'bx;
  parameter _TECHMAP_CONSTMSK_DATAIN_ = 1'b1;
  parameter _TECHMAP_CONSTVAL_DATAIN_ = 1'bx;

  localparam [0:0] IDATAIN_USED = _TECHMAP_CONSTMSK_IDATAIN_ == 1'b0;
  localparam [0:0] DATAIN_USED = _TECHMAP_CONSTMSK_DATAIN_ == 1'b0;

  IDELAYE2_VPR #(
    .IN_USE                 (IDATAIN_USED | DATAIN_USED),
    .IDELAY_VALUE           (IDELAY_VALUE),
    .ZIDELAY_VALUE          (ZIDELAY_VALUE),

    .PIPE_SEL               (PIPE_SEL == "TRUE"),
    .CINVCTRL_SEL           (CINVCTRL_SEL == "TRUE"),
    .DELAY_SRC_DATAIN       (DELAY_SRC == "DATAIN"),
    .DELAY_SRC_IDATAIN      (DELAY_SRC == "IDATAIN"),
    .HIGH_PERFORMANCE_MODE  (HIGH_PERFORMANCE_MODE == "TRUE"),

    .IDELAY_TYPE_FIXED      (IDELAY_TYPE == "FIXED"),
    .IDELAY_TYPE_VAR_LOAD   (IDELAY_TYPE == "VAR_LOAD"),
    .IDELAY_TYPE_VARIABLE   (IDELAY_TYPE == "VARIABLE"),

    // Inverters
    .IS_DATAIN_INVERTED     (IS_DATAIN_INVERTED),
    .IS_IDATAIN_INVERTED    (IS_IDATAIN_INVERTED)
  ) _TECHMAP_REPLACE_ (
      .C                (C),
      .CE               (CE),
      .CINVCTRL         (CINVCTRL),
      // CNTVALUEIN0-4 should be 1 if unused
      .CNTVALUEIN0      (CNTVALUEIN0 | NOT_USING_CNTVALUEIN),
      .CNTVALUEIN1      (CNTVALUEIN1 | NOT_USING_CNTVALUEIN),
      .CNTVALUEIN2      (CNTVALUEIN2 | NOT_USING_CNTVALUEIN),
      .CNTVALUEIN3      (CNTVALUEIN3 | NOT_USING_CNTVALUEIN),
      .CNTVALUEIN4      (CNTVALUEIN4 | NOT_USING_CNTVALUEIN),
      .DATAIN           (DATAIN | ~DATAIN_USED),
      .IDATAIN          (IDATAIN | ~IDATAIN_USED),
      .INC              (INC),
      .LD               (LD),
      .LDPIPEEN         (LDPIPEEN),
      .REGRST           (REGRST),

      .CNTVALUEOUT0     (CNTVALUEOUT0),
      .CNTVALUEOUT1     (CNTVALUEOUT1),
      .CNTVALUEOUT2     (CNTVALUEOUT2),
      .CNTVALUEOUT3     (CNTVALUEOUT3),
      .CNTVALUEOUT4     (CNTVALUEOUT4),
      .DATAOUT          (DATAOUT)
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

module BUFGCE (
  input I,
  input CE,
  output O,
  );

  BUFGCTRL _TECHMAP_REPLACE_ (
    .O(O),
    .CE0(CE),
    .CE1(1'b0),
    .I0(I),
    .I1(1'b1),
    .IGNORE0(1'b0),
    .IGNORE1(1'b1),
    .S0(1'b1),
    .S1(1'b0)
  );
endmodule

module BUFGMUX (
  input I0,
  input I1,
  input S,
  output O
  );

  BUFGCTRL #(
    .IS_CE0_INVERTED(1'b1)
  )_TECHMAP_REPLACE_ (
    .O(O),
    .CE0(S),
    .CE1(S),
    .I0(I0),
    .I1(I1),
    .IGNORE0(1'b0),
    .IGNORE1(1'b0),
    .S0(1'b1),
    .S1(1'b1)
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

  parameter _TECHMAP_CONSTMSK_CLKINSEL_ = 0;
  parameter _TECHMAP_CONSTVAL_CLKINSEL_ = 0;

  parameter _TECHMAP_CONSTMSK_RST_      = 0;
  parameter _TECHMAP_CONSTVAL_RST_      = 0;
  parameter _TECHMAP_CONSTMSK_PWRDWN_   = 0;
  parameter _TECHMAP_CONSTVAL_PWRDWN_   = 0;

  parameter _TECHMAP_CONSTMSK_CLKFBOUT_ = 0;
  parameter _TECHMAP_CONSTVAL_CLKFBOUT_ = 0;
  parameter _TECHMAP_CONSTMSK_CLKOUT0_  = 0;
  parameter _TECHMAP_CONSTVAL_CLKOUT0_  = 0;
  parameter _TECHMAP_CONSTMSK_CLKOUT1_  = 0;
  parameter _TECHMAP_CONSTVAL_CLKOUT1_  = 0;
  parameter _TECHMAP_CONSTMSK_CLKOUT2_  = 0;
  parameter _TECHMAP_CONSTVAL_CLKOUT2_  = 0;
  parameter _TECHMAP_CONSTMSK_CLKOUT3_  = 0;
  parameter _TECHMAP_CONSTVAL_CLKOUT3_  = 0;
  parameter _TECHMAP_CONSTMSK_CLKOUT4_  = 0;
  parameter _TECHMAP_CONSTVAL_CLKOUT4_  = 0;
  parameter _TECHMAP_CONSTMSK_CLKOUT5_  = 0;
  parameter _TECHMAP_CONSTVAL_CLKOUT5_  = 0;

  parameter _TECHMAP_CONSTMSK_DCLK_     = 0;
  parameter _TECHMAP_CONSTVAL_DCLK_     = 0;
  parameter _TECHMAP_CONSTMSK_DEN_      = 0;
  parameter _TECHMAP_CONSTVAL_DEN_      = 0;
  parameter _TECHMAP_CONSTMSK_DWE_      = 0;
  parameter _TECHMAP_CONSTVAL_DWE_      = 0;

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

  // Handle inputs that should have certain logic levels when left unconnected

  // If unconnected, CLKINSEL should be set to VCC by default
  localparam INV_CLKINSEL = (_TECHMAP_CONSTMSK_CLKINSEL_ ==  1) ? !_TECHMAP_CONSTVAL_CLKINSEL_ ^ IS_CLKINSEL_INVERTED:
                            (_TECHMAP_CONSTVAL_CLKINSEL_ === 0) ? IS_CLKINSEL_INVERTED : IS_CLKINSEL_INVERTED;
  wire clkinsel = (_TECHMAP_CONSTMSK_CLKINSEL_ ==  1) ? 1'b1 :
                  (_TECHMAP_CONSTVAL_CLKINSEL_ === 0) ? 1'b1 : CLKINSEL;

  localparam INV_PWRDWN = (_TECHMAP_CONSTMSK_PWRDWN_ ==  1) ? !_TECHMAP_CONSTVAL_PWRDWN_ ^ IS_PWRDWN_INVERTED:
                          (_TECHMAP_CONSTVAL_PWRDWN_ === 0) ? ~IS_PWRDWN_INVERTED : IS_PWRDWN_INVERTED;
  wire pwrdwn = (_TECHMAP_CONSTMSK_PWRDWN_ ==  1) ? 1'b1 :
                (_TECHMAP_CONSTVAL_PWRDWN_ === 0) ? 1'b1 : PWRDWN;

  localparam INV_RST = (_TECHMAP_CONSTMSK_RST_ == 1)  ? !_TECHMAP_CONSTVAL_RST_ ^ IS_RST_INVERTED:
                       (_TECHMAP_CONSTVAL_RST_ === 0) ? ~IS_RST_INVERTED : IS_RST_INVERTED;
  wire rst = (_TECHMAP_CONSTMSK_RST_ ==  1) ? 1'b1 :
             (_TECHMAP_CONSTVAL_RST_ === 0) ? 1'b1 : RST;

  wire dclk = (_TECHMAP_CONSTMSK_DCLK_ == 1) ? _TECHMAP_CONSTVAL_DCLK_ :
              (_TECHMAP_CONSTVAL_DCLK_ == 0) ? 1'b0 : DCLK;

  wire den = (_TECHMAP_CONSTMSK_DEN_ == 1) ? _TECHMAP_CONSTVAL_DEN_ :
             (_TECHMAP_CONSTVAL_DEN_ == 0) ? 1'b0 : DEN;

  wire dwe = (_TECHMAP_CONSTMSK_DWE_ == 1) ? _TECHMAP_CONSTVAL_DWE_ :
             (_TECHMAP_CONSTVAL_DWE_ == 0) ? 1'b0 : DWE;

  // The substituted cell
  PLLE2_ADV_VPR #
  (
  // Inverters
  .INV_CLKINSEL(INV_CLKINSEL),
  .ZINV_PWRDWN (INV_PWRDWN),
  .ZINV_RST    (INV_RST),

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
  .CLKFBOUT_CLKOUT1_OUTPUT_ENABLE(_TECHMAP_CONSTVAL_CLKFBOUT_ === 1'bX),

  .CLKOUT0_CLKOUT1_OUTPUT_ENABLE(_TECHMAP_CONSTVAL_CLKOUT0_ === 1'bX),
  .CLKOUT1_CLKOUT1_OUTPUT_ENABLE(_TECHMAP_CONSTVAL_CLKOUT1_ === 1'bX),
  .CLKOUT2_CLKOUT1_OUTPUT_ENABLE(_TECHMAP_CONSTVAL_CLKOUT2_ === 1'bX),
  .CLKOUT3_CLKOUT1_OUTPUT_ENABLE(_TECHMAP_CONSTVAL_CLKOUT3_ === 1'bX),
  .CLKOUT4_CLKOUT1_OUTPUT_ENABLE(_TECHMAP_CONSTVAL_CLKOUT4_ === 1'bX),
  .CLKOUT5_CLKOUT1_OUTPUT_ENABLE(_TECHMAP_CONSTVAL_CLKOUT5_ === 1'bX)
  )
  _TECHMAP_REPLACE_
  (
  .CLKFBIN(CLKFBIN),
  .CLKIN1(CLKIN1),
  .CLKIN2(CLKIN2),
  .CLKFBOUT(CLKFBOUT),
  .CLKOUT0(CLKOUT0),
  .CLKOUT1(CLKOUT1),
  .CLKOUT2(CLKOUT2),
  .CLKOUT3(CLKOUT3),
  .CLKOUT4(CLKOUT4),
  .CLKOUT5(CLKOUT5),

  .CLKINSEL (clkinsel),

  .PWRDWN   (pwrdwn),
  .RST      (rst),
  .LOCKED   (LOCKED),

  .DCLK (dclk),
  .DEN  (den),
  .DWE  (dwe),
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

module INV(
    output O,
    input I
);
  LUT1 #(.INIT(2'b01)) _TECHMAP_REPLACE_ (.O(O), .I0(I));
endmodule

// ============================================================================
// The Zynq PS7

module PS7 (
  inout  [14: 0] DDRA,
  input  [ 3: 0] DDRARB,
  inout  [ 2: 0] DDRBA,
  inout          DDRCASB,
  inout          DDRCKE,
  inout          DDRCKN,
  inout          DDRCKP,
  inout          DDRCSB,
  inout  [ 3: 0] DDRDM,
  inout  [31: 0] DDRDQ,
  inout  [ 3: 0] DDRDQSN,
  inout  [ 3: 0] DDRDQSP,
  inout          DDRDRSTB,
  inout          DDRODT,
  inout          DDRRASB,
  inout          DDRVRN,
  inout          DDRVRP,
  inout          DDRWEB,
  input          DMA0ACLK,
  input          DMA0DAREADY,
  output [ 1: 0] DMA0DATYPE,
  output         DMA0DAVALID,
  input          DMA0DRLAST,
  output         DMA0DRREADY,
  input  [ 1: 0] DMA0DRTYPE,
  input          DMA0DRVALID,
  output         DMA0RSTN,
  input          DMA1ACLK,
  input          DMA1DAREADY,
  output [ 1: 0] DMA1DATYPE,
  output         DMA1DAVALID,
  input          DMA1DRLAST,
  output         DMA1DRREADY,
  input  [ 1: 0] DMA1DRTYPE,
  input          DMA1DRVALID,
  output         DMA1RSTN,
  input          DMA2ACLK,
  input          DMA2DAREADY,
  output [ 1: 0] DMA2DATYPE,
  output         DMA2DAVALID,
  input          DMA2DRLAST,
  output         DMA2DRREADY,
  input  [ 1: 0] DMA2DRTYPE,
  input          DMA2DRVALID,
  output         DMA2RSTN,
  input          DMA3ACLK,
  input          DMA3DAREADY,
  output [ 1: 0] DMA3DATYPE,
  output         DMA3DAVALID,
  input          DMA3DRLAST,
  output         DMA3DRREADY,
  input  [ 1: 0] DMA3DRTYPE,
  input          DMA3DRVALID,
  output         DMA3RSTN,
  input          EMIOCAN0PHYRX,
  output         EMIOCAN0PHYTX,
  input          EMIOCAN1PHYRX,
  output         EMIOCAN1PHYTX,
  input          EMIOENET0EXTINTIN,
  input          EMIOENET0GMIICOL,
  input          EMIOENET0GMIICRS,
  input          EMIOENET0GMIIRXCLK,
  input  [ 7: 0] EMIOENET0GMIIRXD,
  input          EMIOENET0GMIIRXDV,
  input          EMIOENET0GMIIRXER,
  input          EMIOENET0GMIITXCLK,
  output [ 7: 0] EMIOENET0GMIITXD,
  output         EMIOENET0GMIITXEN,
  output         EMIOENET0GMIITXER,
  input          EMIOENET0MDIOI,
  output         EMIOENET0MDIOMDC,
  output         EMIOENET0MDIOO,
  output         EMIOENET0MDIOTN,
  output         EMIOENET0PTPDELAYREQRX,
  output         EMIOENET0PTPDELAYREQTX,
  output         EMIOENET0PTPPDELAYREQRX,
  output         EMIOENET0PTPPDELAYREQTX,
  output         EMIOENET0PTPPDELAYRESPRX,
  output         EMIOENET0PTPPDELAYRESPTX,
  output         EMIOENET0PTPSYNCFRAMERX,
  output         EMIOENET0PTPSYNCFRAMETX,
  output         EMIOENET0SOFRX,
  output         EMIOENET0SOFTX,
  input          EMIOENET1EXTINTIN,
  input          EMIOENET1GMIICOL,
  input          EMIOENET1GMIICRS,
  input          EMIOENET1GMIIRXCLK,
  input  [ 7: 0] EMIOENET1GMIIRXD,
  input          EMIOENET1GMIIRXDV,
  input          EMIOENET1GMIIRXER,
  input          EMIOENET1GMIITXCLK,
  output [ 7: 0] EMIOENET1GMIITXD,
  output         EMIOENET1GMIITXEN,
  output         EMIOENET1GMIITXER,
  input          EMIOENET1MDIOI,
  output         EMIOENET1MDIOMDC,
  output         EMIOENET1MDIOO,
  output         EMIOENET1MDIOTN,
  output         EMIOENET1PTPDELAYREQRX,
  output         EMIOENET1PTPDELAYREQTX,
  output         EMIOENET1PTPPDELAYREQRX,
  output         EMIOENET1PTPPDELAYREQTX,
  output         EMIOENET1PTPPDELAYRESPRX,
  output         EMIOENET1PTPPDELAYRESPTX,
  output         EMIOENET1PTPSYNCFRAMERX,
  output         EMIOENET1PTPSYNCFRAMETX,
  output         EMIOENET1SOFRX,
  output         EMIOENET1SOFTX,
  input  [63: 0] EMIOGPIOI,
  output [63: 0] EMIOGPIOO,
  output [63: 0] EMIOGPIOTN,
  input          EMIOI2C0SCLI,
  output         EMIOI2C0SCLO,
  output         EMIOI2C0SCLTN,
  input          EMIOI2C0SDAI,
  output         EMIOI2C0SDAO,
  output         EMIOI2C0SDATN,
  input          EMIOI2C1SCLI,
  output         EMIOI2C1SCLO,
  output         EMIOI2C1SCLTN,
  input          EMIOI2C1SDAI,
  output         EMIOI2C1SDAO,
  output         EMIOI2C1SDATN,
  input          EMIOPJTAGTCK,
  input          EMIOPJTAGTDI,
  output         EMIOPJTAGTDO,
  output         EMIOPJTAGTDTN,
  input          EMIOPJTAGTMS,
  output         EMIOSDIO0BUSPOW,
  output [ 2: 0] EMIOSDIO0BUSVOLT,
  input          EMIOSDIO0CDN,
  output         EMIOSDIO0CLK,
  input          EMIOSDIO0CLKFB,
  input          EMIOSDIO0CMDI,
  output         EMIOSDIO0CMDO,
  output         EMIOSDIO0CMDTN,
  input  [ 3: 0] EMIOSDIO0DATAI,
  output [ 3: 0] EMIOSDIO0DATAO,
  output [ 3: 0] EMIOSDIO0DATATN,
  output         EMIOSDIO0LED,
  input          EMIOSDIO0WP,
  output         EMIOSDIO1BUSPOW,
  output [ 2: 0] EMIOSDIO1BUSVOLT,
  input          EMIOSDIO1CDN,
  output         EMIOSDIO1CLK,
  input          EMIOSDIO1CLKFB,
  input          EMIOSDIO1CMDI,
  output         EMIOSDIO1CMDO,
  output         EMIOSDIO1CMDTN,
  input  [ 3: 0] EMIOSDIO1DATAI,
  output [ 3: 0] EMIOSDIO1DATAO,
  output [ 3: 0] EMIOSDIO1DATATN,
  output         EMIOSDIO1LED,
  input          EMIOSDIO1WP,
  input          EMIOSPI0MI,
  output         EMIOSPI0MO,
  output         EMIOSPI0MOTN,
  input          EMIOSPI0SCLKI,
  output         EMIOSPI0SCLKO,
  output         EMIOSPI0SCLKTN,
  input          EMIOSPI0SI,
  output         EMIOSPI0SO,
  input          EMIOSPI0SSIN,
  output         EMIOSPI0SSNTN,
  output [ 2: 0] EMIOSPI0SSON,
  output         EMIOSPI0STN,
  input          EMIOSPI1MI,
  output         EMIOSPI1MO,
  output         EMIOSPI1MOTN,
  input          EMIOSPI1SCLKI,
  output         EMIOSPI1SCLKO,
  output         EMIOSPI1SCLKTN,
  input          EMIOSPI1SI,
  output         EMIOSPI1SO,
  input          EMIOSPI1SSIN,
  output         EMIOSPI1SSNTN,
  output [ 2: 0] EMIOSPI1SSON,
  output         EMIOSPI1STN,
  input          EMIOSRAMINTIN,
  input          EMIOTRACECLK,
  output         EMIOTRACECTL,
  output [31: 0] EMIOTRACEDATA,
  input  [ 2: 0] EMIOTTC0CLKI,
  output [ 2: 0] EMIOTTC0WAVEO,
  input  [ 2: 0] EMIOTTC1CLKI,
  output [ 2: 0] EMIOTTC1WAVEO,
  input          EMIOUART0CTSN,
  input          EMIOUART0DCDN,
  input          EMIOUART0DSRN,
  output         EMIOUART0DTRN,
  input          EMIOUART0RIN,
  output         EMIOUART0RTSN,
  input          EMIOUART0RX,
  output         EMIOUART0TX,
  input          EMIOUART1CTSN,
  input          EMIOUART1DCDN,
  input          EMIOUART1DSRN,
  output         EMIOUART1DTRN,
  input          EMIOUART1RIN,
  output         EMIOUART1RTSN,
  input          EMIOUART1RX,
  output         EMIOUART1TX,
  output [ 1: 0] EMIOUSB0PORTINDCTL,
  input          EMIOUSB0VBUSPWRFAULT,
  output         EMIOUSB0VBUSPWRSELECT,
  output [ 1: 0] EMIOUSB1PORTINDCTL,
  input          EMIOUSB1VBUSPWRFAULT,
  output         EMIOUSB1VBUSPWRSELECT,
  input          EMIOWDTCLKI,
  output         EMIOWDTRSTO,
  input          EVENTEVENTI,
  output         EVENTEVENTO,
  output [ 1: 0] EVENTSTANDBYWFE,
  output [ 1: 0] EVENTSTANDBYWFI,
  output [ 3: 0] FCLKCLK,
  input  [ 3: 0] FCLKCLKTRIGN,
  output [ 3: 0] FCLKRESETN,
  input          FPGAIDLEN,
  input  [ 3: 0] FTMDTRACEINATID,
  input          FTMDTRACEINCLOCK,
  input  [31: 0] FTMDTRACEINDATA,
  input          FTMDTRACEINVALID,
  input  [31: 0] FTMTF2PDEBUG,
  input  [ 3: 0] FTMTF2PTRIG,
  output [ 3: 0] FTMTF2PTRIGACK,
  output [31: 0] FTMTP2FDEBUG,
  output [ 3: 0] FTMTP2FTRIG,
  input  [ 3: 0] FTMTP2FTRIGACK,
  input  [19: 0] IRQF2P,
  output [28: 0] IRQP2F,
  input          MAXIGP0ACLK,
  output [31: 0] MAXIGP0ARADDR,
  output [ 1: 0] MAXIGP0ARBURST,
  output [ 3: 0] MAXIGP0ARCACHE,
  output         MAXIGP0ARESETN,
  output [11: 0] MAXIGP0ARID,
  output [ 3: 0] MAXIGP0ARLEN,
  output [ 1: 0] MAXIGP0ARLOCK,
  output [ 2: 0] MAXIGP0ARPROT,
  output [ 3: 0] MAXIGP0ARQOS,
  input          MAXIGP0ARREADY,
  output [ 1: 0] MAXIGP0ARSIZE,
  output         MAXIGP0ARVALID,
  output [31: 0] MAXIGP0AWADDR,
  output [ 1: 0] MAXIGP0AWBURST,
  output [ 3: 0] MAXIGP0AWCACHE,
  output [11: 0] MAXIGP0AWID,
  output [ 3: 0] MAXIGP0AWLEN,
  output [ 1: 0] MAXIGP0AWLOCK,
  output [ 2: 0] MAXIGP0AWPROT,
  output [ 3: 0] MAXIGP0AWQOS,
  input          MAXIGP0AWREADY,
  output [ 1: 0] MAXIGP0AWSIZE,
  output         MAXIGP0AWVALID,
  input  [11: 0] MAXIGP0BID,
  output         MAXIGP0BREADY,
  input  [ 1: 0] MAXIGP0BRESP,
  input          MAXIGP0BVALID,
  input  [31: 0] MAXIGP0RDATA,
  input  [11: 0] MAXIGP0RID,
  input          MAXIGP0RLAST,
  output         MAXIGP0RREADY,
  input  [ 1: 0] MAXIGP0RRESP,
  input          MAXIGP0RVALID,
  output [31: 0] MAXIGP0WDATA,
  output [11: 0] MAXIGP0WID,
  output         MAXIGP0WLAST,
  input          MAXIGP0WREADY,
  output [ 3: 0] MAXIGP0WSTRB,
  output         MAXIGP0WVALID,
  input          MAXIGP1ACLK,
  output [31: 0] MAXIGP1ARADDR,
  output [ 1: 0] MAXIGP1ARBURST,
  output [ 3: 0] MAXIGP1ARCACHE,
  output         MAXIGP1ARESETN,
  output [11: 0] MAXIGP1ARID,
  output [ 3: 0] MAXIGP1ARLEN,
  output [ 1: 0] MAXIGP1ARLOCK,
  output [ 2: 0] MAXIGP1ARPROT,
  output [ 3: 0] MAXIGP1ARQOS,
  input          MAXIGP1ARREADY,
  output [ 1: 0] MAXIGP1ARSIZE,
  output         MAXIGP1ARVALID,
  output [31: 0] MAXIGP1AWADDR,
  output [ 1: 0] MAXIGP1AWBURST,
  output [ 3: 0] MAXIGP1AWCACHE,
  output [11: 0] MAXIGP1AWID,
  output [ 3: 0] MAXIGP1AWLEN,
  output [ 1: 0] MAXIGP1AWLOCK,
  output [ 2: 0] MAXIGP1AWPROT,
  output [ 3: 0] MAXIGP1AWQOS,
  input          MAXIGP1AWREADY,
  output [ 1: 0] MAXIGP1AWSIZE,
  output         MAXIGP1AWVALID,
  input  [11: 0] MAXIGP1BID,
  output         MAXIGP1BREADY,
  input  [ 1: 0] MAXIGP1BRESP,
  input          MAXIGP1BVALID,
  input  [31: 0] MAXIGP1RDATA,
  input  [11: 0] MAXIGP1RID,
  input          MAXIGP1RLAST,
  output         MAXIGP1RREADY,
  input  [ 1: 0] MAXIGP1RRESP,
  input          MAXIGP1RVALID,
  output [31: 0] MAXIGP1WDATA,
  output [11: 0] MAXIGP1WID,
  output         MAXIGP1WLAST,
  input          MAXIGP1WREADY,
  output [ 3: 0] MAXIGP1WSTRB,
  output         MAXIGP1WVALID,
  inout  [53: 0] MIO,
  inout          PSCLK,
  inout          PSPORB,
  inout          PSSRSTB,
  input          SAXIACPACLK,
  input  [31: 0] SAXIACPARADDR,
  input  [ 1: 0] SAXIACPARBURST,
  input  [ 3: 0] SAXIACPARCACHE,
  output         SAXIACPARESETN,
  input  [ 2: 0] SAXIACPARID,
  input  [ 3: 0] SAXIACPARLEN,
  input  [ 1: 0] SAXIACPARLOCK,
  input  [ 2: 0] SAXIACPARPROT,
  input  [ 3: 0] SAXIACPARQOS,
  output         SAXIACPARREADY,
  input  [ 1: 0] SAXIACPARSIZE,
  input  [ 4: 0] SAXIACPARUSER,
  input          SAXIACPARVALID,
  input  [31: 0] SAXIACPAWADDR,
  input  [ 1: 0] SAXIACPAWBURST,
  input  [ 3: 0] SAXIACPAWCACHE,
  input  [ 2: 0] SAXIACPAWID,
  input  [ 3: 0] SAXIACPAWLEN,
  input  [ 1: 0] SAXIACPAWLOCK,
  input  [ 2: 0] SAXIACPAWPROT,
  input  [ 3: 0] SAXIACPAWQOS,
  output         SAXIACPAWREADY,
  input  [ 1: 0] SAXIACPAWSIZE,
  input  [ 4: 0] SAXIACPAWUSER,
  input          SAXIACPAWVALID,
  output [ 2: 0] SAXIACPBID,
  input          SAXIACPBREADY,
  output [ 1: 0] SAXIACPBRESP,
  output         SAXIACPBVALID,
  output [63: 0] SAXIACPRDATA,
  output [ 2: 0] SAXIACPRID,
  output         SAXIACPRLAST,
  input          SAXIACPRREADY,
  output [ 1: 0] SAXIACPRRESP,
  output         SAXIACPRVALID,
  input  [63: 0] SAXIACPWDATA,
  input  [ 2: 0] SAXIACPWID,
  input          SAXIACPWLAST,
  output         SAXIACPWREADY,
  input  [ 7: 0] SAXIACPWSTRB,
  input          SAXIACPWVALID,
  input          SAXIGP0ACLK,
  input  [31: 0] SAXIGP0ARADDR,
  input  [ 1: 0] SAXIGP0ARBURST,
  input  [ 3: 0] SAXIGP0ARCACHE,
  output         SAXIGP0ARESETN,
  input  [ 5: 0] SAXIGP0ARID,
  input  [ 3: 0] SAXIGP0ARLEN,
  input  [ 1: 0] SAXIGP0ARLOCK,
  input  [ 2: 0] SAXIGP0ARPROT,
  input  [ 3: 0] SAXIGP0ARQOS,
  output         SAXIGP0ARREADY,
  input  [ 1: 0] SAXIGP0ARSIZE,
  input          SAXIGP0ARVALID,
  input  [31: 0] SAXIGP0AWADDR,
  input  [ 1: 0] SAXIGP0AWBURST,
  input  [ 3: 0] SAXIGP0AWCACHE,
  input  [ 5: 0] SAXIGP0AWID,
  input  [ 3: 0] SAXIGP0AWLEN,
  input  [ 1: 0] SAXIGP0AWLOCK,
  input  [ 2: 0] SAXIGP0AWPROT,
  input  [ 3: 0] SAXIGP0AWQOS,
  output         SAXIGP0AWREADY,
  input  [ 1: 0] SAXIGP0AWSIZE,
  input          SAXIGP0AWVALID,
  output [ 5: 0] SAXIGP0BID,
  input          SAXIGP0BREADY,
  output [ 1: 0] SAXIGP0BRESP,
  output         SAXIGP0BVALID,
  output [31: 0] SAXIGP0RDATA,
  output [ 5: 0] SAXIGP0RID,
  output         SAXIGP0RLAST,
  input          SAXIGP0RREADY,
  output [ 1: 0] SAXIGP0RRESP,
  output         SAXIGP0RVALID,
  input  [31: 0] SAXIGP0WDATA,
  input  [ 5: 0] SAXIGP0WID,
  input          SAXIGP0WLAST,
  output         SAXIGP0WREADY,
  input  [ 3: 0] SAXIGP0WSTRB,
  input          SAXIGP0WVALID,
  input          SAXIGP1ACLK,
  input  [31: 0] SAXIGP1ARADDR,
  input  [ 1: 0] SAXIGP1ARBURST,
  input  [ 3: 0] SAXIGP1ARCACHE,
  output         SAXIGP1ARESETN,
  input  [ 5: 0] SAXIGP1ARID,
  input  [ 3: 0] SAXIGP1ARLEN,
  input  [ 1: 0] SAXIGP1ARLOCK,
  input  [ 2: 0] SAXIGP1ARPROT,
  input  [ 3: 0] SAXIGP1ARQOS,
  output         SAXIGP1ARREADY,
  input  [ 1: 0] SAXIGP1ARSIZE,
  input          SAXIGP1ARVALID,
  input  [31: 0] SAXIGP1AWADDR,
  input  [ 1: 0] SAXIGP1AWBURST,
  input  [ 3: 0] SAXIGP1AWCACHE,
  input  [ 5: 0] SAXIGP1AWID,
  input  [ 3: 0] SAXIGP1AWLEN,
  input  [ 1: 0] SAXIGP1AWLOCK,
  input  [ 2: 0] SAXIGP1AWPROT,
  input  [ 3: 0] SAXIGP1AWQOS,
  output         SAXIGP1AWREADY,
  input  [ 1: 0] SAXIGP1AWSIZE,
  input          SAXIGP1AWVALID,
  output [ 5: 0] SAXIGP1BID,
  input          SAXIGP1BREADY,
  output [ 1: 0] SAXIGP1BRESP,
  output         SAXIGP1BVALID,
  output [31: 0] SAXIGP1RDATA,
  output [ 5: 0] SAXIGP1RID,
  output         SAXIGP1RLAST,
  input          SAXIGP1RREADY,
  output [ 1: 0] SAXIGP1RRESP,
  output         SAXIGP1RVALID,
  input  [31: 0] SAXIGP1WDATA,
  input  [ 5: 0] SAXIGP1WID,
  input          SAXIGP1WLAST,
  output         SAXIGP1WREADY,
  input  [ 3: 0] SAXIGP1WSTRB,
  input          SAXIGP1WVALID,
  input          SAXIHP0ACLK,
  input  [31: 0] SAXIHP0ARADDR,
  input  [ 1: 0] SAXIHP0ARBURST,
  input  [ 3: 0] SAXIHP0ARCACHE,
  output         SAXIHP0ARESETN,
  input  [ 5: 0] SAXIHP0ARID,
  input  [ 3: 0] SAXIHP0ARLEN,
  input  [ 1: 0] SAXIHP0ARLOCK,
  input  [ 2: 0] SAXIHP0ARPROT,
  input  [ 3: 0] SAXIHP0ARQOS,
  output         SAXIHP0ARREADY,
  input  [ 1: 0] SAXIHP0ARSIZE,
  input          SAXIHP0ARVALID,
  input  [31: 0] SAXIHP0AWADDR,
  input  [ 1: 0] SAXIHP0AWBURST,
  input  [ 3: 0] SAXIHP0AWCACHE,
  input  [ 5: 0] SAXIHP0AWID,
  input  [ 3: 0] SAXIHP0AWLEN,
  input  [ 1: 0] SAXIHP0AWLOCK,
  input  [ 2: 0] SAXIHP0AWPROT,
  input  [ 3: 0] SAXIHP0AWQOS,
  output         SAXIHP0AWREADY,
  input  [ 1: 0] SAXIHP0AWSIZE,
  input          SAXIHP0AWVALID,
  output [ 5: 0] SAXIHP0BID,
  input          SAXIHP0BREADY,
  output [ 1: 0] SAXIHP0BRESP,
  output         SAXIHP0BVALID,
  output [ 2: 0] SAXIHP0RACOUNT,
  output [ 7: 0] SAXIHP0RCOUNT,
  output [63: 0] SAXIHP0RDATA,
  input          SAXIHP0RDISSUECAP1EN,
  output [ 5: 0] SAXIHP0RID,
  output         SAXIHP0RLAST,
  input          SAXIHP0RREADY,
  output [ 1: 0] SAXIHP0RRESP,
  output         SAXIHP0RVALID,
  output [ 5: 0] SAXIHP0WACOUNT,
  output [ 7: 0] SAXIHP0WCOUNT,
  input  [63: 0] SAXIHP0WDATA,
  input  [ 5: 0] SAXIHP0WID,
  input          SAXIHP0WLAST,
  output         SAXIHP0WREADY,
  input          SAXIHP0WRISSUECAP1EN,
  input  [ 7: 0] SAXIHP0WSTRB,
  input          SAXIHP0WVALID,
  input          SAXIHP1ACLK,
  input  [31: 0] SAXIHP1ARADDR,
  input  [ 1: 0] SAXIHP1ARBURST,
  input  [ 3: 0] SAXIHP1ARCACHE,
  output         SAXIHP1ARESETN,
  input  [ 5: 0] SAXIHP1ARID,
  input  [ 3: 0] SAXIHP1ARLEN,
  input  [ 1: 0] SAXIHP1ARLOCK,
  input  [ 2: 0] SAXIHP1ARPROT,
  input  [ 3: 0] SAXIHP1ARQOS,
  output         SAXIHP1ARREADY,
  input  [ 1: 0] SAXIHP1ARSIZE,
  input          SAXIHP1ARVALID,
  input  [31: 0] SAXIHP1AWADDR,
  input  [ 1: 0] SAXIHP1AWBURST,
  input  [ 3: 0] SAXIHP1AWCACHE,
  input  [ 5: 0] SAXIHP1AWID,
  input  [ 3: 0] SAXIHP1AWLEN,
  input  [ 1: 0] SAXIHP1AWLOCK,
  input  [ 2: 0] SAXIHP1AWPROT,
  input  [ 3: 0] SAXIHP1AWQOS,
  output         SAXIHP1AWREADY,
  input  [ 1: 0] SAXIHP1AWSIZE,
  input          SAXIHP1AWVALID,
  output [ 5: 0] SAXIHP1BID,
  input          SAXIHP1BREADY,
  output [ 1: 0] SAXIHP1BRESP,
  output         SAXIHP1BVALID,
  output [ 2: 0] SAXIHP1RACOUNT,
  output [ 7: 0] SAXIHP1RCOUNT,
  output [63: 0] SAXIHP1RDATA,
  input          SAXIHP1RDISSUECAP1EN,
  output [ 5: 0] SAXIHP1RID,
  output         SAXIHP1RLAST,
  input          SAXIHP1RREADY,
  output [ 1: 0] SAXIHP1RRESP,
  output         SAXIHP1RVALID,
  output [ 5: 0] SAXIHP1WACOUNT,
  output [ 7: 0] SAXIHP1WCOUNT,
  input  [63: 0] SAXIHP1WDATA,
  input  [ 5: 0] SAXIHP1WID,
  input          SAXIHP1WLAST,
  output         SAXIHP1WREADY,
  input          SAXIHP1WRISSUECAP1EN,
  input  [ 7: 0] SAXIHP1WSTRB,
  input          SAXIHP1WVALID,
  input          SAXIHP2ACLK,
  input  [31: 0] SAXIHP2ARADDR,
  input  [ 1: 0] SAXIHP2ARBURST,
  input  [ 3: 0] SAXIHP2ARCACHE,
  output         SAXIHP2ARESETN,
  input  [ 5: 0] SAXIHP2ARID,
  input  [ 3: 0] SAXIHP2ARLEN,
  input  [ 1: 0] SAXIHP2ARLOCK,
  input  [ 2: 0] SAXIHP2ARPROT,
  input  [ 3: 0] SAXIHP2ARQOS,
  output         SAXIHP2ARREADY,
  input  [ 1: 0] SAXIHP2ARSIZE,
  input          SAXIHP2ARVALID,
  input  [31: 0] SAXIHP2AWADDR,
  input  [ 1: 0] SAXIHP2AWBURST,
  input  [ 3: 0] SAXIHP2AWCACHE,
  input  [ 5: 0] SAXIHP2AWID,
  input  [ 3: 0] SAXIHP2AWLEN,
  input  [ 1: 0] SAXIHP2AWLOCK,
  input  [ 2: 0] SAXIHP2AWPROT,
  input  [ 3: 0] SAXIHP2AWQOS,
  output         SAXIHP2AWREADY,
  input  [ 1: 0] SAXIHP2AWSIZE,
  input          SAXIHP2AWVALID,
  output [ 5: 0] SAXIHP2BID,
  input          SAXIHP2BREADY,
  output [ 1: 0] SAXIHP2BRESP,
  output         SAXIHP2BVALID,
  output [ 2: 0] SAXIHP2RACOUNT,
  output [ 7: 0] SAXIHP2RCOUNT,
  output [63: 0] SAXIHP2RDATA,
  input          SAXIHP2RDISSUECAP1EN,
  output [ 5: 0] SAXIHP2RID,
  output         SAXIHP2RLAST,
  input          SAXIHP2RREADY,
  output [ 1: 0] SAXIHP2RRESP,
  output         SAXIHP2RVALID,
  output [ 5: 0] SAXIHP2WACOUNT,
  output [ 7: 0] SAXIHP2WCOUNT,
  input  [63: 0] SAXIHP2WDATA,
  input  [ 5: 0] SAXIHP2WID,
  input          SAXIHP2WLAST,
  output         SAXIHP2WREADY,
  input          SAXIHP2WRISSUECAP1EN,
  input  [ 7: 0] SAXIHP2WSTRB,
  input          SAXIHP2WVALID,
  input          SAXIHP3ACLK,
  input  [31: 0] SAXIHP3ARADDR,
  input  [ 1: 0] SAXIHP3ARBURST,
  input  [ 3: 0] SAXIHP3ARCACHE,
  output         SAXIHP3ARESETN,
  input  [ 5: 0] SAXIHP3ARID,
  input  [ 3: 0] SAXIHP3ARLEN,
  input  [ 1: 0] SAXIHP3ARLOCK,
  input  [ 2: 0] SAXIHP3ARPROT,
  input  [ 3: 0] SAXIHP3ARQOS,
  output         SAXIHP3ARREADY,
  input  [ 1: 0] SAXIHP3ARSIZE,
  input          SAXIHP3ARVALID,
  input  [31: 0] SAXIHP3AWADDR,
  input  [ 1: 0] SAXIHP3AWBURST,
  input  [ 3: 0] SAXIHP3AWCACHE,
  input  [ 5: 0] SAXIHP3AWID,
  input  [ 3: 0] SAXIHP3AWLEN,
  input  [ 1: 0] SAXIHP3AWLOCK,
  input  [ 2: 0] SAXIHP3AWPROT,
  input  [ 3: 0] SAXIHP3AWQOS,
  output         SAXIHP3AWREADY,
  input  [ 1: 0] SAXIHP3AWSIZE,
  input          SAXIHP3AWVALID,
  output [ 5: 0] SAXIHP3BID,
  input          SAXIHP3BREADY,
  output [ 1: 0] SAXIHP3BRESP,
  output         SAXIHP3BVALID,
  output [ 2: 0] SAXIHP3RACOUNT,
  output [ 7: 0] SAXIHP3RCOUNT,
  output [63: 0] SAXIHP3RDATA,
  input          SAXIHP3RDISSUECAP1EN,
  output [ 5: 0] SAXIHP3RID,
  output         SAXIHP3RLAST,
  input          SAXIHP3RREADY,
  output [ 1: 0] SAXIHP3RRESP,
  output         SAXIHP3RVALID,
  output [ 5: 0] SAXIHP3WACOUNT,
  output [ 7: 0] SAXIHP3WCOUNT,
  input  [63: 0] SAXIHP3WDATA,
  input  [ 5: 0] SAXIHP3WID,
  input          SAXIHP3WLAST,
  output         SAXIHP3WREADY,
  input          SAXIHP3WRISSUECAP1EN,
  input  [ 7: 0] SAXIHP3WSTRB,
  input          SAXIHP3WVALID
);

  // Techmap specific parameters.
  parameter _TECHMAP_CONSTMSK_DDRARB_ = 0;
  parameter _TECHMAP_CONSTVAL_DDRARB_ = 0;
  parameter _TECHMAP_CONSTMSK_DMA0ACLK_ = 0;
  parameter _TECHMAP_CONSTVAL_DMA0ACLK_ = 0;
  parameter _TECHMAP_CONSTMSK_DMA0DAREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_DMA0DAREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_DMA0DRLAST_ = 0;
  parameter _TECHMAP_CONSTVAL_DMA0DRLAST_ = 0;
  parameter _TECHMAP_CONSTMSK_DMA0DRTYPE_ = 0;
  parameter _TECHMAP_CONSTVAL_DMA0DRTYPE_ = 0;
  parameter _TECHMAP_CONSTMSK_DMA0DRVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_DMA0DRVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_DMA1ACLK_ = 0;
  parameter _TECHMAP_CONSTVAL_DMA1ACLK_ = 0;
  parameter _TECHMAP_CONSTMSK_DMA1DAREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_DMA1DAREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_DMA1DRLAST_ = 0;
  parameter _TECHMAP_CONSTVAL_DMA1DRLAST_ = 0;
  parameter _TECHMAP_CONSTMSK_DMA1DRTYPE_ = 0;
  parameter _TECHMAP_CONSTVAL_DMA1DRTYPE_ = 0;
  parameter _TECHMAP_CONSTMSK_DMA1DRVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_DMA1DRVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_DMA2ACLK_ = 0;
  parameter _TECHMAP_CONSTVAL_DMA2ACLK_ = 0;
  parameter _TECHMAP_CONSTMSK_DMA2DAREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_DMA2DAREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_DMA2DRLAST_ = 0;
  parameter _TECHMAP_CONSTVAL_DMA2DRLAST_ = 0;
  parameter _TECHMAP_CONSTMSK_DMA2DRTYPE_ = 0;
  parameter _TECHMAP_CONSTVAL_DMA2DRTYPE_ = 0;
  parameter _TECHMAP_CONSTMSK_DMA2DRVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_DMA2DRVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_DMA3ACLK_ = 0;
  parameter _TECHMAP_CONSTVAL_DMA3ACLK_ = 0;
  parameter _TECHMAP_CONSTMSK_DMA3DAREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_DMA3DAREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_DMA3DRLAST_ = 0;
  parameter _TECHMAP_CONSTVAL_DMA3DRLAST_ = 0;
  parameter _TECHMAP_CONSTMSK_DMA3DRTYPE_ = 0;
  parameter _TECHMAP_CONSTVAL_DMA3DRTYPE_ = 0;
  parameter _TECHMAP_CONSTMSK_DMA3DRVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_DMA3DRVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOCAN0PHYRX_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOCAN0PHYRX_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOCAN1PHYRX_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOCAN1PHYRX_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOENET0EXTINTIN_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOENET0EXTINTIN_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOENET0GMIICOL_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOENET0GMIICOL_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOENET0GMIICRS_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOENET0GMIICRS_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOENET0GMIIRXCLK_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOENET0GMIIRXCLK_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOENET0GMIIRXD_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOENET0GMIIRXD_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOENET0GMIIRXDV_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOENET0GMIIRXDV_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOENET0GMIIRXER_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOENET0GMIIRXER_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOENET0GMIITXCLK_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOENET0GMIITXCLK_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOENET0MDIOI_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOENET0MDIOI_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOENET1EXTINTIN_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOENET1EXTINTIN_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOENET1GMIICOL_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOENET1GMIICOL_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOENET1GMIICRS_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOENET1GMIICRS_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOENET1GMIIRXCLK_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOENET1GMIIRXCLK_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOENET1GMIIRXD_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOENET1GMIIRXD_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOENET1GMIIRXDV_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOENET1GMIIRXDV_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOENET1GMIIRXER_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOENET1GMIIRXER_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOENET1GMIITXCLK_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOENET1GMIITXCLK_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOENET1MDIOI_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOENET1MDIOI_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOGPIOI_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOGPIOI_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOI2C0SCLI_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOI2C0SCLI_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOI2C0SDAI_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOI2C0SDAI_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOI2C1SCLI_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOI2C1SCLI_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOI2C1SDAI_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOI2C1SDAI_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOPJTAGTCK_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOPJTAGTCK_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOPJTAGTDI_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOPJTAGTDI_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOPJTAGTMS_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOPJTAGTMS_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOSDIO0CDN_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOSDIO0CDN_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOSDIO0CLKFB_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOSDIO0CLKFB_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOSDIO0CMDI_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOSDIO0CMDI_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOSDIO0DATAI_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOSDIO0DATAI_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOSDIO0WP_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOSDIO0WP_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOSDIO1CDN_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOSDIO1CDN_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOSDIO1CLKFB_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOSDIO1CLKFB_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOSDIO1CMDI_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOSDIO1CMDI_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOSDIO1DATAI_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOSDIO1DATAI_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOSDIO1WP_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOSDIO1WP_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOSPI0MI_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOSPI0MI_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOSPI0SCLKI_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOSPI0SCLKI_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOSPI0SI_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOSPI0SI_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOSPI0SSIN_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOSPI0SSIN_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOSPI1MI_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOSPI1MI_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOSPI1SCLKI_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOSPI1SCLKI_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOSPI1SI_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOSPI1SI_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOSPI1SSIN_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOSPI1SSIN_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOSRAMINTIN_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOSRAMINTIN_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOTRACECLK_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOTRACECLK_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOTTC0CLKI_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOTTC0CLKI_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOTTC1CLKI_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOTTC1CLKI_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOUART0CTSN_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOUART0CTSN_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOUART0DCDN_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOUART0DCDN_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOUART0DSRN_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOUART0DSRN_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOUART0RIN_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOUART0RIN_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOUART0RX_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOUART0RX_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOUART1CTSN_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOUART1CTSN_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOUART1DCDN_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOUART1DCDN_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOUART1DSRN_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOUART1DSRN_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOUART1RIN_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOUART1RIN_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOUART1RX_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOUART1RX_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOUSB0VBUSPWRFAULT_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOUSB0VBUSPWRFAULT_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOUSB1VBUSPWRFAULT_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOUSB1VBUSPWRFAULT_ = 0;
  parameter _TECHMAP_CONSTMSK_EMIOWDTCLKI_ = 0;
  parameter _TECHMAP_CONSTVAL_EMIOWDTCLKI_ = 0;
  parameter _TECHMAP_CONSTMSK_EVENTEVENTI_ = 0;
  parameter _TECHMAP_CONSTVAL_EVENTEVENTI_ = 0;
  parameter _TECHMAP_CONSTMSK_FCLKCLKTRIGN_ = 0;
  parameter _TECHMAP_CONSTVAL_FCLKCLKTRIGN_ = 0;
  parameter _TECHMAP_CONSTMSK_FPGAIDLEN_ = 0;
  parameter _TECHMAP_CONSTVAL_FPGAIDLEN_ = 0;
  parameter _TECHMAP_CONSTMSK_FTMDTRACEINATID_ = 0;
  parameter _TECHMAP_CONSTVAL_FTMDTRACEINATID_ = 0;
  parameter _TECHMAP_CONSTMSK_FTMDTRACEINCLOCK_ = 0;
  parameter _TECHMAP_CONSTVAL_FTMDTRACEINCLOCK_ = 0;
  parameter _TECHMAP_CONSTMSK_FTMDTRACEINDATA_ = 0;
  parameter _TECHMAP_CONSTVAL_FTMDTRACEINDATA_ = 0;
  parameter _TECHMAP_CONSTMSK_FTMDTRACEINVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_FTMDTRACEINVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_FTMTF2PDEBUG_ = 0;
  parameter _TECHMAP_CONSTVAL_FTMTF2PDEBUG_ = 0;
  parameter _TECHMAP_CONSTMSK_FTMTF2PTRIG_ = 0;
  parameter _TECHMAP_CONSTVAL_FTMTF2PTRIG_ = 0;
  parameter _TECHMAP_CONSTMSK_FTMTP2FTRIGACK_ = 0;
  parameter _TECHMAP_CONSTVAL_FTMTP2FTRIGACK_ = 0;
  parameter _TECHMAP_CONSTMSK_IRQF2P_ = 0;
  parameter _TECHMAP_CONSTVAL_IRQF2P_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP0ACLK_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP0ACLK_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP0ARREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP0ARREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP0AWREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP0AWREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP0BID_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP0BID_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP0BRESP_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP0BRESP_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP0BVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP0BVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP0RDATA_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP0RDATA_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP0RID_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP0RID_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP0RLAST_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP0RLAST_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP0RRESP_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP0RRESP_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP0RVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP0RVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP0WREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP0WREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP1ACLK_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP1ACLK_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP1ARREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP1ARREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP1AWREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP1AWREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP1BID_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP1BID_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP1BRESP_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP1BRESP_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP1BVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP1BVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP1RDATA_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP1RDATA_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP1RID_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP1RID_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP1RLAST_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP1RLAST_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP1RRESP_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP1RRESP_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP1RVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP1RVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_MAXIGP1WREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_MAXIGP1WREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPACLK_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPACLK_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPARADDR_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPARADDR_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPARBURST_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPARBURST_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPARCACHE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPARCACHE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPARID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPARID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPARLEN_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPARLEN_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPARLOCK_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPARLOCK_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPARPROT_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPARPROT_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPARQOS_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPARQOS_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPARSIZE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPARSIZE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPARUSER_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPARUSER_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPARVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPARVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPAWADDR_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPAWADDR_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPAWBURST_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPAWBURST_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPAWCACHE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPAWCACHE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPAWID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPAWID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPAWLEN_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPAWLEN_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPAWLOCK_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPAWLOCK_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPAWPROT_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPAWPROT_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPAWQOS_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPAWQOS_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPAWSIZE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPAWSIZE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPAWUSER_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPAWUSER_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPAWVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPAWVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPBREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPBREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPRREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPRREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPWDATA_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPWDATA_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPWID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPWID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPWLAST_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPWLAST_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPWSTRB_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPWSTRB_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIACPWVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIACPWVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0ACLK_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0ACLK_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0ARADDR_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0ARADDR_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0ARBURST_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0ARBURST_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0ARCACHE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0ARCACHE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0ARID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0ARID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0ARLEN_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0ARLEN_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0ARLOCK_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0ARLOCK_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0ARPROT_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0ARPROT_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0ARQOS_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0ARQOS_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0ARSIZE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0ARSIZE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0ARVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0ARVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0AWADDR_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0AWADDR_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0AWBURST_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0AWBURST_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0AWCACHE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0AWCACHE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0AWID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0AWID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0AWLEN_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0AWLEN_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0AWLOCK_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0AWLOCK_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0AWPROT_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0AWPROT_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0AWQOS_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0AWQOS_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0AWSIZE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0AWSIZE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0AWVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0AWVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0BREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0BREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0RREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0RREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0WDATA_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0WDATA_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0WID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0WID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0WLAST_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0WLAST_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0WSTRB_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0WSTRB_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP0WVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP0WVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1ACLK_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1ACLK_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1ARADDR_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1ARADDR_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1ARBURST_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1ARBURST_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1ARCACHE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1ARCACHE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1ARID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1ARID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1ARLEN_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1ARLEN_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1ARLOCK_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1ARLOCK_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1ARPROT_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1ARPROT_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1ARQOS_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1ARQOS_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1ARSIZE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1ARSIZE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1ARVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1ARVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1AWADDR_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1AWADDR_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1AWBURST_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1AWBURST_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1AWCACHE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1AWCACHE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1AWID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1AWID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1AWLEN_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1AWLEN_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1AWLOCK_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1AWLOCK_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1AWPROT_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1AWPROT_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1AWQOS_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1AWQOS_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1AWSIZE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1AWSIZE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1AWVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1AWVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1BREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1BREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1RREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1RREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1WDATA_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1WDATA_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1WID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1WID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1WLAST_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1WLAST_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1WSTRB_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1WSTRB_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIGP1WVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIGP1WVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0ACLK_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0ACLK_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0ARADDR_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0ARADDR_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0ARBURST_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0ARBURST_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0ARCACHE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0ARCACHE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0ARID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0ARID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0ARLEN_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0ARLEN_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0ARLOCK_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0ARLOCK_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0ARPROT_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0ARPROT_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0ARQOS_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0ARQOS_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0ARSIZE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0ARSIZE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0ARVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0ARVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0AWADDR_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0AWADDR_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0AWBURST_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0AWBURST_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0AWCACHE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0AWCACHE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0AWID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0AWID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0AWLEN_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0AWLEN_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0AWLOCK_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0AWLOCK_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0AWPROT_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0AWPROT_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0AWQOS_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0AWQOS_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0AWSIZE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0AWSIZE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0AWVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0AWVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0BREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0BREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0RDISSUECAP1EN_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0RDISSUECAP1EN_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0RREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0RREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0WDATA_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0WDATA_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0WID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0WID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0WLAST_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0WLAST_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0WRISSUECAP1EN_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0WRISSUECAP1EN_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0WSTRB_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0WSTRB_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP0WVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP0WVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1ACLK_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1ACLK_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1ARADDR_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1ARADDR_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1ARBURST_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1ARBURST_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1ARCACHE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1ARCACHE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1ARID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1ARID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1ARLEN_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1ARLEN_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1ARLOCK_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1ARLOCK_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1ARPROT_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1ARPROT_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1ARQOS_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1ARQOS_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1ARSIZE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1ARSIZE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1ARVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1ARVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1AWADDR_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1AWADDR_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1AWBURST_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1AWBURST_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1AWCACHE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1AWCACHE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1AWID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1AWID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1AWLEN_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1AWLEN_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1AWLOCK_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1AWLOCK_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1AWPROT_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1AWPROT_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1AWQOS_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1AWQOS_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1AWSIZE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1AWSIZE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1AWVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1AWVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1BREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1BREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1RDISSUECAP1EN_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1RDISSUECAP1EN_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1RREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1RREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1WDATA_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1WDATA_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1WID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1WID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1WLAST_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1WLAST_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1WRISSUECAP1EN_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1WRISSUECAP1EN_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1WSTRB_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1WSTRB_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP1WVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP1WVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2ACLK_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2ACLK_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2ARADDR_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2ARADDR_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2ARBURST_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2ARBURST_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2ARCACHE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2ARCACHE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2ARID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2ARID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2ARLEN_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2ARLEN_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2ARLOCK_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2ARLOCK_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2ARPROT_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2ARPROT_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2ARQOS_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2ARQOS_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2ARSIZE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2ARSIZE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2ARVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2ARVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2AWADDR_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2AWADDR_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2AWBURST_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2AWBURST_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2AWCACHE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2AWCACHE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2AWID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2AWID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2AWLEN_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2AWLEN_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2AWLOCK_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2AWLOCK_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2AWPROT_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2AWPROT_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2AWQOS_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2AWQOS_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2AWSIZE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2AWSIZE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2AWVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2AWVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2BREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2BREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2RDISSUECAP1EN_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2RDISSUECAP1EN_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2RREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2RREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2WDATA_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2WDATA_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2WID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2WID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2WLAST_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2WLAST_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2WRISSUECAP1EN_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2WRISSUECAP1EN_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2WSTRB_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2WSTRB_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP2WVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP2WVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3ACLK_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3ACLK_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3ARADDR_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3ARADDR_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3ARBURST_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3ARBURST_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3ARCACHE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3ARCACHE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3ARID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3ARID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3ARLEN_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3ARLEN_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3ARLOCK_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3ARLOCK_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3ARPROT_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3ARPROT_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3ARQOS_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3ARQOS_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3ARSIZE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3ARSIZE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3ARVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3ARVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3AWADDR_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3AWADDR_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3AWBURST_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3AWBURST_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3AWCACHE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3AWCACHE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3AWID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3AWID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3AWLEN_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3AWLEN_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3AWLOCK_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3AWLOCK_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3AWPROT_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3AWPROT_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3AWQOS_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3AWQOS_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3AWSIZE_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3AWSIZE_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3AWVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3AWVALID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3BREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3BREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3RDISSUECAP1EN_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3RDISSUECAP1EN_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3RREADY_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3RREADY_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3WDATA_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3WDATA_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3WID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3WID_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3WLAST_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3WLAST_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3WRISSUECAP1EN_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3WRISSUECAP1EN_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3WSTRB_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3WSTRB_ = 0;
  parameter _TECHMAP_CONSTMSK_SAXIHP3WVALID_ = 0;
  parameter _TECHMAP_CONSTVAL_SAXIHP3WVALID_ = 0;

  // Detect all unconnected inputs and tie them to 0.

  wire [3:0] ddrarb = (_TECHMAP_CONSTMSK_DDRARB_ == 4'd0 && _TECHMAP_CONSTVAL_DDRARB_ === 4'd0) ? 4'b0 : DDRARB;

  wire [0:0] dma0aclk = (_TECHMAP_CONSTMSK_DMA0ACLK_ == 1'd0 && _TECHMAP_CONSTVAL_DMA0ACLK_ === 1'd0) ? 1'b0 : DMA0ACLK;

  wire [0:0] dma0daready = (_TECHMAP_CONSTMSK_DMA0DAREADY_ == 1'd0 && _TECHMAP_CONSTVAL_DMA0DAREADY_ === 1'd0) ? 1'b0 : DMA0DAREADY;

  wire [0:0] dma0drlast = (_TECHMAP_CONSTMSK_DMA0DRLAST_ == 1'd0 && _TECHMAP_CONSTVAL_DMA0DRLAST_ === 1'd0) ? 1'b0 : DMA0DRLAST;

  wire [1:0] dma0drtype = (_TECHMAP_CONSTMSK_DMA0DRTYPE_ == 2'd0 && _TECHMAP_CONSTVAL_DMA0DRTYPE_ === 2'd0) ? 2'b0 : DMA0DRTYPE;

  wire [0:0] dma0drvalid = (_TECHMAP_CONSTMSK_DMA0DRVALID_ == 1'd0 && _TECHMAP_CONSTVAL_DMA0DRVALID_ === 1'd0) ? 1'b0 : DMA0DRVALID;

  wire [0:0] dma1aclk = (_TECHMAP_CONSTMSK_DMA1ACLK_ == 1'd0 && _TECHMAP_CONSTVAL_DMA1ACLK_ === 1'd0) ? 1'b0 : DMA1ACLK;

  wire [0:0] dma1daready = (_TECHMAP_CONSTMSK_DMA1DAREADY_ == 1'd0 && _TECHMAP_CONSTVAL_DMA1DAREADY_ === 1'd0) ? 1'b0 : DMA1DAREADY;

  wire [0:0] dma1drlast = (_TECHMAP_CONSTMSK_DMA1DRLAST_ == 1'd0 && _TECHMAP_CONSTVAL_DMA1DRLAST_ === 1'd0) ? 1'b0 : DMA1DRLAST;

  wire [1:0] dma1drtype = (_TECHMAP_CONSTMSK_DMA1DRTYPE_ == 2'd0 && _TECHMAP_CONSTVAL_DMA1DRTYPE_ === 2'd0) ? 2'b0 : DMA1DRTYPE;

  wire [0:0] dma1drvalid = (_TECHMAP_CONSTMSK_DMA1DRVALID_ == 1'd0 && _TECHMAP_CONSTVAL_DMA1DRVALID_ === 1'd0) ? 1'b0 : DMA1DRVALID;

  wire [0:0] dma2aclk = (_TECHMAP_CONSTMSK_DMA2ACLK_ == 1'd0 && _TECHMAP_CONSTVAL_DMA2ACLK_ === 1'd0) ? 1'b0 : DMA2ACLK;

  wire [0:0] dma2daready = (_TECHMAP_CONSTMSK_DMA2DAREADY_ == 1'd0 && _TECHMAP_CONSTVAL_DMA2DAREADY_ === 1'd0) ? 1'b0 : DMA2DAREADY;

  wire [0:0] dma2drlast = (_TECHMAP_CONSTMSK_DMA2DRLAST_ == 1'd0 && _TECHMAP_CONSTVAL_DMA2DRLAST_ === 1'd0) ? 1'b0 : DMA2DRLAST;

  wire [1:0] dma2drtype = (_TECHMAP_CONSTMSK_DMA2DRTYPE_ == 2'd0 && _TECHMAP_CONSTVAL_DMA2DRTYPE_ === 2'd0) ? 2'b0 : DMA2DRTYPE;

  wire [0:0] dma2drvalid = (_TECHMAP_CONSTMSK_DMA2DRVALID_ == 1'd0 && _TECHMAP_CONSTVAL_DMA2DRVALID_ === 1'd0) ? 1'b0 : DMA2DRVALID;

  wire [0:0] dma3aclk = (_TECHMAP_CONSTMSK_DMA3ACLK_ == 1'd0 && _TECHMAP_CONSTVAL_DMA3ACLK_ === 1'd0) ? 1'b0 : DMA3ACLK;

  wire [0:0] dma3daready = (_TECHMAP_CONSTMSK_DMA3DAREADY_ == 1'd0 && _TECHMAP_CONSTVAL_DMA3DAREADY_ === 1'd0) ? 1'b0 : DMA3DAREADY;

  wire [0:0] dma3drlast = (_TECHMAP_CONSTMSK_DMA3DRLAST_ == 1'd0 && _TECHMAP_CONSTVAL_DMA3DRLAST_ === 1'd0) ? 1'b0 : DMA3DRLAST;

  wire [1:0] dma3drtype = (_TECHMAP_CONSTMSK_DMA3DRTYPE_ == 2'd0 && _TECHMAP_CONSTVAL_DMA3DRTYPE_ === 2'd0) ? 2'b0 : DMA3DRTYPE;

  wire [0:0] dma3drvalid = (_TECHMAP_CONSTMSK_DMA3DRVALID_ == 1'd0 && _TECHMAP_CONSTVAL_DMA3DRVALID_ === 1'd0) ? 1'b0 : DMA3DRVALID;

  wire [0:0] emiocan0phyrx = (_TECHMAP_CONSTMSK_EMIOCAN0PHYRX_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOCAN0PHYRX_ === 1'd0) ? 1'b0 : EMIOCAN0PHYRX;

  wire [0:0] emiocan1phyrx = (_TECHMAP_CONSTMSK_EMIOCAN1PHYRX_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOCAN1PHYRX_ === 1'd0) ? 1'b0 : EMIOCAN1PHYRX;

  wire [0:0] emioenet0extintin = (_TECHMAP_CONSTMSK_EMIOENET0EXTINTIN_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOENET0EXTINTIN_ === 1'd0) ? 1'b0 : EMIOENET0EXTINTIN;

  wire [0:0] emioenet0gmiicol = (_TECHMAP_CONSTMSK_EMIOENET0GMIICOL_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOENET0GMIICOL_ === 1'd0) ? 1'b0 : EMIOENET0GMIICOL;

  wire [0:0] emioenet0gmiicrs = (_TECHMAP_CONSTMSK_EMIOENET0GMIICRS_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOENET0GMIICRS_ === 1'd0) ? 1'b0 : EMIOENET0GMIICRS;

  wire [0:0] emioenet0gmiirxclk = (_TECHMAP_CONSTMSK_EMIOENET0GMIIRXCLK_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOENET0GMIIRXCLK_ === 1'd0) ? 1'b0 : EMIOENET0GMIIRXCLK;

  wire [7:0] emioenet0gmiirxd = (_TECHMAP_CONSTMSK_EMIOENET0GMIIRXD_ == 8'd0 && _TECHMAP_CONSTVAL_EMIOENET0GMIIRXD_ === 8'd0) ? 8'b0 : EMIOENET0GMIIRXD;

  wire [0:0] emioenet0gmiirxdv = (_TECHMAP_CONSTMSK_EMIOENET0GMIIRXDV_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOENET0GMIIRXDV_ === 1'd0) ? 1'b0 : EMIOENET0GMIIRXDV;

  wire [0:0] emioenet0gmiirxer = (_TECHMAP_CONSTMSK_EMIOENET0GMIIRXER_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOENET0GMIIRXER_ === 1'd0) ? 1'b0 : EMIOENET0GMIIRXER;

  wire [0:0] emioenet0gmiitxclk = (_TECHMAP_CONSTMSK_EMIOENET0GMIITXCLK_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOENET0GMIITXCLK_ === 1'd0) ? 1'b0 : EMIOENET0GMIITXCLK;

  wire [0:0] emioenet0mdioi = (_TECHMAP_CONSTMSK_EMIOENET0MDIOI_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOENET0MDIOI_ === 1'd0) ? 1'b0 : EMIOENET0MDIOI;

  wire [0:0] emioenet1extintin = (_TECHMAP_CONSTMSK_EMIOENET1EXTINTIN_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOENET1EXTINTIN_ === 1'd0) ? 1'b0 : EMIOENET1EXTINTIN;

  wire [0:0] emioenet1gmiicol = (_TECHMAP_CONSTMSK_EMIOENET1GMIICOL_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOENET1GMIICOL_ === 1'd0) ? 1'b0 : EMIOENET1GMIICOL;

  wire [0:0] emioenet1gmiicrs = (_TECHMAP_CONSTMSK_EMIOENET1GMIICRS_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOENET1GMIICRS_ === 1'd0) ? 1'b0 : EMIOENET1GMIICRS;

  wire [0:0] emioenet1gmiirxclk = (_TECHMAP_CONSTMSK_EMIOENET1GMIIRXCLK_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOENET1GMIIRXCLK_ === 1'd0) ? 1'b0 : EMIOENET1GMIIRXCLK;

  wire [7:0] emioenet1gmiirxd = (_TECHMAP_CONSTMSK_EMIOENET1GMIIRXD_ == 8'd0 && _TECHMAP_CONSTVAL_EMIOENET1GMIIRXD_ === 8'd0) ? 8'b0 : EMIOENET1GMIIRXD;

  wire [0:0] emioenet1gmiirxdv = (_TECHMAP_CONSTMSK_EMIOENET1GMIIRXDV_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOENET1GMIIRXDV_ === 1'd0) ? 1'b0 : EMIOENET1GMIIRXDV;

  wire [0:0] emioenet1gmiirxer = (_TECHMAP_CONSTMSK_EMIOENET1GMIIRXER_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOENET1GMIIRXER_ === 1'd0) ? 1'b0 : EMIOENET1GMIIRXER;

  wire [0:0] emioenet1gmiitxclk = (_TECHMAP_CONSTMSK_EMIOENET1GMIITXCLK_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOENET1GMIITXCLK_ === 1'd0) ? 1'b0 : EMIOENET1GMIITXCLK;

  wire [0:0] emioenet1mdioi = (_TECHMAP_CONSTMSK_EMIOENET1MDIOI_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOENET1MDIOI_ === 1'd0) ? 1'b0 : EMIOENET1MDIOI;

  wire [63:0] emiogpioi = (_TECHMAP_CONSTMSK_EMIOGPIOI_ == 64'd0 && _TECHMAP_CONSTVAL_EMIOGPIOI_ === 64'd0) ? 64'b0 : EMIOGPIOI;

  wire [0:0] emioi2c0scli = (_TECHMAP_CONSTMSK_EMIOI2C0SCLI_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOI2C0SCLI_ === 1'd0) ? 1'b0 : EMIOI2C0SCLI;

  wire [0:0] emioi2c0sdai = (_TECHMAP_CONSTMSK_EMIOI2C0SDAI_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOI2C0SDAI_ === 1'd0) ? 1'b0 : EMIOI2C0SDAI;

  wire [0:0] emioi2c1scli = (_TECHMAP_CONSTMSK_EMIOI2C1SCLI_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOI2C1SCLI_ === 1'd0) ? 1'b0 : EMIOI2C1SCLI;

  wire [0:0] emioi2c1sdai = (_TECHMAP_CONSTMSK_EMIOI2C1SDAI_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOI2C1SDAI_ === 1'd0) ? 1'b0 : EMIOI2C1SDAI;

  wire [0:0] emiopjtagtck = (_TECHMAP_CONSTMSK_EMIOPJTAGTCK_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOPJTAGTCK_ === 1'd0) ? 1'b0 : EMIOPJTAGTCK;

  wire [0:0] emiopjtagtdi = (_TECHMAP_CONSTMSK_EMIOPJTAGTDI_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOPJTAGTDI_ === 1'd0) ? 1'b0 : EMIOPJTAGTDI;

  wire [0:0] emiopjtagtms = (_TECHMAP_CONSTMSK_EMIOPJTAGTMS_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOPJTAGTMS_ === 1'd0) ? 1'b0 : EMIOPJTAGTMS;

  wire [0:0] emiosdio0cdn = (_TECHMAP_CONSTMSK_EMIOSDIO0CDN_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOSDIO0CDN_ === 1'd0) ? 1'b0 : EMIOSDIO0CDN;

  wire [0:0] emiosdio0clkfb = (_TECHMAP_CONSTMSK_EMIOSDIO0CLKFB_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOSDIO0CLKFB_ === 1'd0) ? 1'b0 : EMIOSDIO0CLKFB;

  wire [0:0] emiosdio0cmdi = (_TECHMAP_CONSTMSK_EMIOSDIO0CMDI_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOSDIO0CMDI_ === 1'd0) ? 1'b0 : EMIOSDIO0CMDI;

  wire [3:0] emiosdio0datai = (_TECHMAP_CONSTMSK_EMIOSDIO0DATAI_ == 4'd0 && _TECHMAP_CONSTVAL_EMIOSDIO0DATAI_ === 4'd0) ? 4'b0 : EMIOSDIO0DATAI;

  wire [0:0] emiosdio0wp = (_TECHMAP_CONSTMSK_EMIOSDIO0WP_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOSDIO0WP_ === 1'd0) ? 1'b0 : EMIOSDIO0WP;

  wire [0:0] emiosdio1cdn = (_TECHMAP_CONSTMSK_EMIOSDIO1CDN_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOSDIO1CDN_ === 1'd0) ? 1'b0 : EMIOSDIO1CDN;

  wire [0:0] emiosdio1clkfb = (_TECHMAP_CONSTMSK_EMIOSDIO1CLKFB_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOSDIO1CLKFB_ === 1'd0) ? 1'b0 : EMIOSDIO1CLKFB;

  wire [0:0] emiosdio1cmdi = (_TECHMAP_CONSTMSK_EMIOSDIO1CMDI_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOSDIO1CMDI_ === 1'd0) ? 1'b0 : EMIOSDIO1CMDI;

  wire [3:0] emiosdio1datai = (_TECHMAP_CONSTMSK_EMIOSDIO1DATAI_ == 4'd0 && _TECHMAP_CONSTVAL_EMIOSDIO1DATAI_ === 4'd0) ? 4'b0 : EMIOSDIO1DATAI;

  wire [0:0] emiosdio1wp = (_TECHMAP_CONSTMSK_EMIOSDIO1WP_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOSDIO1WP_ === 1'd0) ? 1'b0 : EMIOSDIO1WP;

  wire [0:0] emiospi0mi = (_TECHMAP_CONSTMSK_EMIOSPI0MI_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOSPI0MI_ === 1'd0) ? 1'b0 : EMIOSPI0MI;

  wire [0:0] emiospi0sclki = (_TECHMAP_CONSTMSK_EMIOSPI0SCLKI_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOSPI0SCLKI_ === 1'd0) ? 1'b0 : EMIOSPI0SCLKI;

  wire [0:0] emiospi0si = (_TECHMAP_CONSTMSK_EMIOSPI0SI_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOSPI0SI_ === 1'd0) ? 1'b0 : EMIOSPI0SI;

  wire [0:0] emiospi0ssin = (_TECHMAP_CONSTMSK_EMIOSPI0SSIN_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOSPI0SSIN_ === 1'd0) ? 1'b0 : EMIOSPI0SSIN;

  wire [0:0] emiospi1mi = (_TECHMAP_CONSTMSK_EMIOSPI1MI_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOSPI1MI_ === 1'd0) ? 1'b0 : EMIOSPI1MI;

  wire [0:0] emiospi1sclki = (_TECHMAP_CONSTMSK_EMIOSPI1SCLKI_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOSPI1SCLKI_ === 1'd0) ? 1'b0 : EMIOSPI1SCLKI;

  wire [0:0] emiospi1si = (_TECHMAP_CONSTMSK_EMIOSPI1SI_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOSPI1SI_ === 1'd0) ? 1'b0 : EMIOSPI1SI;

  wire [0:0] emiospi1ssin = (_TECHMAP_CONSTMSK_EMIOSPI1SSIN_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOSPI1SSIN_ === 1'd0) ? 1'b0 : EMIOSPI1SSIN;

  wire [0:0] emiosramintin = (_TECHMAP_CONSTMSK_EMIOSRAMINTIN_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOSRAMINTIN_ === 1'd0) ? 1'b0 : EMIOSRAMINTIN;

  wire [0:0] emiotraceclk = (_TECHMAP_CONSTMSK_EMIOTRACECLK_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOTRACECLK_ === 1'd0) ? 1'b0 : EMIOTRACECLK;

  wire [2:0] emiottc0clki = (_TECHMAP_CONSTMSK_EMIOTTC0CLKI_ == 3'd0 && _TECHMAP_CONSTVAL_EMIOTTC0CLKI_ === 3'd0) ? 3'b0 : EMIOTTC0CLKI;

  wire [2:0] emiottc1clki = (_TECHMAP_CONSTMSK_EMIOTTC1CLKI_ == 3'd0 && _TECHMAP_CONSTVAL_EMIOTTC1CLKI_ === 3'd0) ? 3'b0 : EMIOTTC1CLKI;

  wire [0:0] emiouart0ctsn = (_TECHMAP_CONSTMSK_EMIOUART0CTSN_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOUART0CTSN_ === 1'd0) ? 1'b0 : EMIOUART0CTSN;

  wire [0:0] emiouart0dcdn = (_TECHMAP_CONSTMSK_EMIOUART0DCDN_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOUART0DCDN_ === 1'd0) ? 1'b0 : EMIOUART0DCDN;

  wire [0:0] emiouart0dsrn = (_TECHMAP_CONSTMSK_EMIOUART0DSRN_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOUART0DSRN_ === 1'd0) ? 1'b0 : EMIOUART0DSRN;

  wire [0:0] emiouart0rin = (_TECHMAP_CONSTMSK_EMIOUART0RIN_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOUART0RIN_ === 1'd0) ? 1'b0 : EMIOUART0RIN;

  wire [0:0] emiouart0rx = (_TECHMAP_CONSTMSK_EMIOUART0RX_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOUART0RX_ === 1'd0) ? 1'b0 : EMIOUART0RX;

  wire [0:0] emiouart1ctsn = (_TECHMAP_CONSTMSK_EMIOUART1CTSN_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOUART1CTSN_ === 1'd0) ? 1'b0 : EMIOUART1CTSN;

  wire [0:0] emiouart1dcdn = (_TECHMAP_CONSTMSK_EMIOUART1DCDN_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOUART1DCDN_ === 1'd0) ? 1'b0 : EMIOUART1DCDN;

  wire [0:0] emiouart1dsrn = (_TECHMAP_CONSTMSK_EMIOUART1DSRN_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOUART1DSRN_ === 1'd0) ? 1'b0 : EMIOUART1DSRN;

  wire [0:0] emiouart1rin = (_TECHMAP_CONSTMSK_EMIOUART1RIN_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOUART1RIN_ === 1'd0) ? 1'b0 : EMIOUART1RIN;

  wire [0:0] emiouart1rx = (_TECHMAP_CONSTMSK_EMIOUART1RX_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOUART1RX_ === 1'd0) ? 1'b0 : EMIOUART1RX;

  wire [0:0] emiousb0vbuspwrfault = (_TECHMAP_CONSTMSK_EMIOUSB0VBUSPWRFAULT_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOUSB0VBUSPWRFAULT_ === 1'd0) ? 1'b0 : EMIOUSB0VBUSPWRFAULT;

  wire [0:0] emiousb1vbuspwrfault = (_TECHMAP_CONSTMSK_EMIOUSB1VBUSPWRFAULT_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOUSB1VBUSPWRFAULT_ === 1'd0) ? 1'b0 : EMIOUSB1VBUSPWRFAULT;

  wire [0:0] emiowdtclki = (_TECHMAP_CONSTMSK_EMIOWDTCLKI_ == 1'd0 && _TECHMAP_CONSTVAL_EMIOWDTCLKI_ === 1'd0) ? 1'b0 : EMIOWDTCLKI;

  wire [0:0] eventeventi = (_TECHMAP_CONSTMSK_EVENTEVENTI_ == 1'd0 && _TECHMAP_CONSTVAL_EVENTEVENTI_ === 1'd0) ? 1'b0 : EVENTEVENTI;

  wire [3:0] fclkclktrign = (_TECHMAP_CONSTMSK_FCLKCLKTRIGN_ == 4'd0 && _TECHMAP_CONSTVAL_FCLKCLKTRIGN_ === 4'd0) ? 4'b0 : FCLKCLKTRIGN;

  wire [0:0] fpgaidlen = (_TECHMAP_CONSTMSK_FPGAIDLEN_ == 1'd0 && _TECHMAP_CONSTVAL_FPGAIDLEN_ === 1'd0) ? 1'b0 : FPGAIDLEN;

  wire [3:0] ftmdtraceinatid = (_TECHMAP_CONSTMSK_FTMDTRACEINATID_ == 4'd0 && _TECHMAP_CONSTVAL_FTMDTRACEINATID_ === 4'd0) ? 4'b0 : FTMDTRACEINATID;

  wire [0:0] ftmdtraceinclock = (_TECHMAP_CONSTMSK_FTMDTRACEINCLOCK_ == 1'd0 && _TECHMAP_CONSTVAL_FTMDTRACEINCLOCK_ === 1'd0) ? 1'b0 : FTMDTRACEINCLOCK;

  wire [31:0] ftmdtraceindata = (_TECHMAP_CONSTMSK_FTMDTRACEINDATA_ == 32'd0 && _TECHMAP_CONSTVAL_FTMDTRACEINDATA_ === 32'd0) ? 32'b0 : FTMDTRACEINDATA;

  wire [0:0] ftmdtraceinvalid = (_TECHMAP_CONSTMSK_FTMDTRACEINVALID_ == 1'd0 && _TECHMAP_CONSTVAL_FTMDTRACEINVALID_ === 1'd0) ? 1'b0 : FTMDTRACEINVALID;

  wire [31:0] ftmtf2pdebug = (_TECHMAP_CONSTMSK_FTMTF2PDEBUG_ == 32'd0 && _TECHMAP_CONSTVAL_FTMTF2PDEBUG_ === 32'd0) ? 32'b0 : FTMTF2PDEBUG;

  wire [3:0] ftmtf2ptrig = (_TECHMAP_CONSTMSK_FTMTF2PTRIG_ == 4'd0 && _TECHMAP_CONSTVAL_FTMTF2PTRIG_ === 4'd0) ? 4'b0 : FTMTF2PTRIG;

  wire [3:0] ftmtp2ftrigack = (_TECHMAP_CONSTMSK_FTMTP2FTRIGACK_ == 4'd0 && _TECHMAP_CONSTVAL_FTMTP2FTRIGACK_ === 4'd0) ? 4'b0 : FTMTP2FTRIGACK;

  wire [19:0] irqf2p = (_TECHMAP_CONSTMSK_IRQF2P_ == 20'd0 && _TECHMAP_CONSTVAL_IRQF2P_ === 20'd0) ? 20'b0 : IRQF2P;

  wire [0:0] maxigp0aclk = (_TECHMAP_CONSTMSK_MAXIGP0ACLK_ == 1'd0 && _TECHMAP_CONSTVAL_MAXIGP0ACLK_ === 1'd0) ? 1'b0 : MAXIGP0ACLK;

  wire [0:0] maxigp0arready = (_TECHMAP_CONSTMSK_MAXIGP0ARREADY_ == 1'd0 && _TECHMAP_CONSTVAL_MAXIGP0ARREADY_ === 1'd0) ? 1'b0 : MAXIGP0ARREADY;

  wire [0:0] maxigp0awready = (_TECHMAP_CONSTMSK_MAXIGP0AWREADY_ == 1'd0 && _TECHMAP_CONSTVAL_MAXIGP0AWREADY_ === 1'd0) ? 1'b0 : MAXIGP0AWREADY;

  wire [11:0] maxigp0bid = (_TECHMAP_CONSTMSK_MAXIGP0BID_ == 12'd0 && _TECHMAP_CONSTVAL_MAXIGP0BID_ === 12'd0) ? 12'b0 : MAXIGP0BID;

  wire [1:0] maxigp0bresp = (_TECHMAP_CONSTMSK_MAXIGP0BRESP_ == 2'd0 && _TECHMAP_CONSTVAL_MAXIGP0BRESP_ === 2'd0) ? 2'b0 : MAXIGP0BRESP;

  wire [0:0] maxigp0bvalid = (_TECHMAP_CONSTMSK_MAXIGP0BVALID_ == 1'd0 && _TECHMAP_CONSTVAL_MAXIGP0BVALID_ === 1'd0) ? 1'b0 : MAXIGP0BVALID;

  wire [31:0] maxigp0rdata = (_TECHMAP_CONSTMSK_MAXIGP0RDATA_ == 32'd0 && _TECHMAP_CONSTVAL_MAXIGP0RDATA_ === 32'd0) ? 32'b0 : MAXIGP0RDATA;

  wire [11:0] maxigp0rid = (_TECHMAP_CONSTMSK_MAXIGP0RID_ == 12'd0 && _TECHMAP_CONSTVAL_MAXIGP0RID_ === 12'd0) ? 12'b0 : MAXIGP0RID;

  wire [0:0] maxigp0rlast = (_TECHMAP_CONSTMSK_MAXIGP0RLAST_ == 1'd0 && _TECHMAP_CONSTVAL_MAXIGP0RLAST_ === 1'd0) ? 1'b0 : MAXIGP0RLAST;

  wire [1:0] maxigp0rresp = (_TECHMAP_CONSTMSK_MAXIGP0RRESP_ == 2'd0 && _TECHMAP_CONSTVAL_MAXIGP0RRESP_ === 2'd0) ? 2'b0 : MAXIGP0RRESP;

  wire [0:0] maxigp0rvalid = (_TECHMAP_CONSTMSK_MAXIGP0RVALID_ == 1'd0 && _TECHMAP_CONSTVAL_MAXIGP0RVALID_ === 1'd0) ? 1'b0 : MAXIGP0RVALID;

  wire [0:0] maxigp0wready = (_TECHMAP_CONSTMSK_MAXIGP0WREADY_ == 1'd0 && _TECHMAP_CONSTVAL_MAXIGP0WREADY_ === 1'd0) ? 1'b0 : MAXIGP0WREADY;

  wire [0:0] maxigp1aclk = (_TECHMAP_CONSTMSK_MAXIGP1ACLK_ == 1'd0 && _TECHMAP_CONSTVAL_MAXIGP1ACLK_ === 1'd0) ? 1'b0 : MAXIGP1ACLK;

  wire [0:0] maxigp1arready = (_TECHMAP_CONSTMSK_MAXIGP1ARREADY_ == 1'd0 && _TECHMAP_CONSTVAL_MAXIGP1ARREADY_ === 1'd0) ? 1'b0 : MAXIGP1ARREADY;

  wire [0:0] maxigp1awready = (_TECHMAP_CONSTMSK_MAXIGP1AWREADY_ == 1'd0 && _TECHMAP_CONSTVAL_MAXIGP1AWREADY_ === 1'd0) ? 1'b0 : MAXIGP1AWREADY;

  wire [11:0] maxigp1bid = (_TECHMAP_CONSTMSK_MAXIGP1BID_ == 12'd0 && _TECHMAP_CONSTVAL_MAXIGP1BID_ === 12'd0) ? 12'b0 : MAXIGP1BID;

  wire [1:0] maxigp1bresp = (_TECHMAP_CONSTMSK_MAXIGP1BRESP_ == 2'd0 && _TECHMAP_CONSTVAL_MAXIGP1BRESP_ === 2'd0) ? 2'b0 : MAXIGP1BRESP;

  wire [0:0] maxigp1bvalid = (_TECHMAP_CONSTMSK_MAXIGP1BVALID_ == 1'd0 && _TECHMAP_CONSTVAL_MAXIGP1BVALID_ === 1'd0) ? 1'b0 : MAXIGP1BVALID;

  wire [31:0] maxigp1rdata = (_TECHMAP_CONSTMSK_MAXIGP1RDATA_ == 32'd0 && _TECHMAP_CONSTVAL_MAXIGP1RDATA_ === 32'd0) ? 32'b0 : MAXIGP1RDATA;

  wire [11:0] maxigp1rid = (_TECHMAP_CONSTMSK_MAXIGP1RID_ == 12'd0 && _TECHMAP_CONSTVAL_MAXIGP1RID_ === 12'd0) ? 12'b0 : MAXIGP1RID;

  wire [0:0] maxigp1rlast = (_TECHMAP_CONSTMSK_MAXIGP1RLAST_ == 1'd0 && _TECHMAP_CONSTVAL_MAXIGP1RLAST_ === 1'd0) ? 1'b0 : MAXIGP1RLAST;

  wire [1:0] maxigp1rresp = (_TECHMAP_CONSTMSK_MAXIGP1RRESP_ == 2'd0 && _TECHMAP_CONSTVAL_MAXIGP1RRESP_ === 2'd0) ? 2'b0 : MAXIGP1RRESP;

  wire [0:0] maxigp1rvalid = (_TECHMAP_CONSTMSK_MAXIGP1RVALID_ == 1'd0 && _TECHMAP_CONSTVAL_MAXIGP1RVALID_ === 1'd0) ? 1'b0 : MAXIGP1RVALID;

  wire [0:0] maxigp1wready = (_TECHMAP_CONSTMSK_MAXIGP1WREADY_ == 1'd0 && _TECHMAP_CONSTVAL_MAXIGP1WREADY_ === 1'd0) ? 1'b0 : MAXIGP1WREADY;

  wire [0:0] saxiacpaclk = (_TECHMAP_CONSTMSK_SAXIACPACLK_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIACPACLK_ === 1'd0) ? 1'b0 : SAXIACPACLK;

  wire [31:0] saxiacparaddr = (_TECHMAP_CONSTMSK_SAXIACPARADDR_ == 32'd0 && _TECHMAP_CONSTVAL_SAXIACPARADDR_ === 32'd0) ? 32'b0 : SAXIACPARADDR;

  wire [1:0] saxiacparburst = (_TECHMAP_CONSTMSK_SAXIACPARBURST_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIACPARBURST_ === 2'd0) ? 2'b0 : SAXIACPARBURST;

  wire [3:0] saxiacparcache = (_TECHMAP_CONSTMSK_SAXIACPARCACHE_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIACPARCACHE_ === 4'd0) ? 4'b0 : SAXIACPARCACHE;

  wire [2:0] saxiacparid = (_TECHMAP_CONSTMSK_SAXIACPARID_ == 3'd0 && _TECHMAP_CONSTVAL_SAXIACPARID_ === 3'd0) ? 3'b0 : SAXIACPARID;

  wire [3:0] saxiacparlen = (_TECHMAP_CONSTMSK_SAXIACPARLEN_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIACPARLEN_ === 4'd0) ? 4'b0 : SAXIACPARLEN;

  wire [1:0] saxiacparlock = (_TECHMAP_CONSTMSK_SAXIACPARLOCK_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIACPARLOCK_ === 2'd0) ? 2'b0 : SAXIACPARLOCK;

  wire [2:0] saxiacparprot = (_TECHMAP_CONSTMSK_SAXIACPARPROT_ == 3'd0 && _TECHMAP_CONSTVAL_SAXIACPARPROT_ === 3'd0) ? 3'b0 : SAXIACPARPROT;

  wire [3:0] saxiacparqos = (_TECHMAP_CONSTMSK_SAXIACPARQOS_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIACPARQOS_ === 4'd0) ? 4'b0 : SAXIACPARQOS;

  wire [1:0] saxiacparsize = (_TECHMAP_CONSTMSK_SAXIACPARSIZE_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIACPARSIZE_ === 2'd0) ? 2'b0 : SAXIACPARSIZE;

  wire [4:0] saxiacparuser = (_TECHMAP_CONSTMSK_SAXIACPARUSER_ == 5'd0 && _TECHMAP_CONSTVAL_SAXIACPARUSER_ === 5'd0) ? 5'b0 : SAXIACPARUSER;

  wire [0:0] saxiacparvalid = (_TECHMAP_CONSTMSK_SAXIACPARVALID_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIACPARVALID_ === 1'd0) ? 1'b0 : SAXIACPARVALID;

  wire [31:0] saxiacpawaddr = (_TECHMAP_CONSTMSK_SAXIACPAWADDR_ == 32'd0 && _TECHMAP_CONSTVAL_SAXIACPAWADDR_ === 32'd0) ? 32'b0 : SAXIACPAWADDR;

  wire [1:0] saxiacpawburst = (_TECHMAP_CONSTMSK_SAXIACPAWBURST_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIACPAWBURST_ === 2'd0) ? 2'b0 : SAXIACPAWBURST;

  wire [3:0] saxiacpawcache = (_TECHMAP_CONSTMSK_SAXIACPAWCACHE_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIACPAWCACHE_ === 4'd0) ? 4'b0 : SAXIACPAWCACHE;

  wire [2:0] saxiacpawid = (_TECHMAP_CONSTMSK_SAXIACPAWID_ == 3'd0 && _TECHMAP_CONSTVAL_SAXIACPAWID_ === 3'd0) ? 3'b0 : SAXIACPAWID;

  wire [3:0] saxiacpawlen = (_TECHMAP_CONSTMSK_SAXIACPAWLEN_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIACPAWLEN_ === 4'd0) ? 4'b0 : SAXIACPAWLEN;

  wire [1:0] saxiacpawlock = (_TECHMAP_CONSTMSK_SAXIACPAWLOCK_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIACPAWLOCK_ === 2'd0) ? 2'b0 : SAXIACPAWLOCK;

  wire [2:0] saxiacpawprot = (_TECHMAP_CONSTMSK_SAXIACPAWPROT_ == 3'd0 && _TECHMAP_CONSTVAL_SAXIACPAWPROT_ === 3'd0) ? 3'b0 : SAXIACPAWPROT;

  wire [3:0] saxiacpawqos = (_TECHMAP_CONSTMSK_SAXIACPAWQOS_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIACPAWQOS_ === 4'd0) ? 4'b0 : SAXIACPAWQOS;

  wire [1:0] saxiacpawsize = (_TECHMAP_CONSTMSK_SAXIACPAWSIZE_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIACPAWSIZE_ === 2'd0) ? 2'b0 : SAXIACPAWSIZE;

  wire [4:0] saxiacpawuser = (_TECHMAP_CONSTMSK_SAXIACPAWUSER_ == 5'd0 && _TECHMAP_CONSTVAL_SAXIACPAWUSER_ === 5'd0) ? 5'b0 : SAXIACPAWUSER;

  wire [0:0] saxiacpawvalid = (_TECHMAP_CONSTMSK_SAXIACPAWVALID_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIACPAWVALID_ === 1'd0) ? 1'b0 : SAXIACPAWVALID;

  wire [0:0] saxiacpbready = (_TECHMAP_CONSTMSK_SAXIACPBREADY_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIACPBREADY_ === 1'd0) ? 1'b0 : SAXIACPBREADY;

  wire [0:0] saxiacprready = (_TECHMAP_CONSTMSK_SAXIACPRREADY_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIACPRREADY_ === 1'd0) ? 1'b0 : SAXIACPRREADY;

  wire [63:0] saxiacpwdata = (_TECHMAP_CONSTMSK_SAXIACPWDATA_ == 64'd0 && _TECHMAP_CONSTVAL_SAXIACPWDATA_ === 64'd0) ? 64'b0 : SAXIACPWDATA;

  wire [2:0] saxiacpwid = (_TECHMAP_CONSTMSK_SAXIACPWID_ == 3'd0 && _TECHMAP_CONSTVAL_SAXIACPWID_ === 3'd0) ? 3'b0 : SAXIACPWID;

  wire [0:0] saxiacpwlast = (_TECHMAP_CONSTMSK_SAXIACPWLAST_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIACPWLAST_ === 1'd0) ? 1'b0 : SAXIACPWLAST;

  wire [7:0] saxiacpwstrb = (_TECHMAP_CONSTMSK_SAXIACPWSTRB_ == 8'd0 && _TECHMAP_CONSTVAL_SAXIACPWSTRB_ === 8'd0) ? 8'b0 : SAXIACPWSTRB;

  wire [0:0] saxiacpwvalid = (_TECHMAP_CONSTMSK_SAXIACPWVALID_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIACPWVALID_ === 1'd0) ? 1'b0 : SAXIACPWVALID;

  wire [0:0] saxigp0aclk = (_TECHMAP_CONSTMSK_SAXIGP0ACLK_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIGP0ACLK_ === 1'd0) ? 1'b0 : SAXIGP0ACLK;

  wire [31:0] saxigp0araddr = (_TECHMAP_CONSTMSK_SAXIGP0ARADDR_ == 32'd0 && _TECHMAP_CONSTVAL_SAXIGP0ARADDR_ === 32'd0) ? 32'b0 : SAXIGP0ARADDR;

  wire [1:0] saxigp0arburst = (_TECHMAP_CONSTMSK_SAXIGP0ARBURST_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIGP0ARBURST_ === 2'd0) ? 2'b0 : SAXIGP0ARBURST;

  wire [3:0] saxigp0arcache = (_TECHMAP_CONSTMSK_SAXIGP0ARCACHE_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIGP0ARCACHE_ === 4'd0) ? 4'b0 : SAXIGP0ARCACHE;

  wire [5:0] saxigp0arid = (_TECHMAP_CONSTMSK_SAXIGP0ARID_ == 6'd0 && _TECHMAP_CONSTVAL_SAXIGP0ARID_ === 6'd0) ? 6'b0 : SAXIGP0ARID;

  wire [3:0] saxigp0arlen = (_TECHMAP_CONSTMSK_SAXIGP0ARLEN_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIGP0ARLEN_ === 4'd0) ? 4'b0 : SAXIGP0ARLEN;

  wire [1:0] saxigp0arlock = (_TECHMAP_CONSTMSK_SAXIGP0ARLOCK_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIGP0ARLOCK_ === 2'd0) ? 2'b0 : SAXIGP0ARLOCK;

  wire [2:0] saxigp0arprot = (_TECHMAP_CONSTMSK_SAXIGP0ARPROT_ == 3'd0 && _TECHMAP_CONSTVAL_SAXIGP0ARPROT_ === 3'd0) ? 3'b0 : SAXIGP0ARPROT;

  wire [3:0] saxigp0arqos = (_TECHMAP_CONSTMSK_SAXIGP0ARQOS_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIGP0ARQOS_ === 4'd0) ? 4'b0 : SAXIGP0ARQOS;

  wire [1:0] saxigp0arsize = (_TECHMAP_CONSTMSK_SAXIGP0ARSIZE_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIGP0ARSIZE_ === 2'd0) ? 2'b0 : SAXIGP0ARSIZE;

  wire [0:0] saxigp0arvalid = (_TECHMAP_CONSTMSK_SAXIGP0ARVALID_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIGP0ARVALID_ === 1'd0) ? 1'b0 : SAXIGP0ARVALID;

  wire [31:0] saxigp0awaddr = (_TECHMAP_CONSTMSK_SAXIGP0AWADDR_ == 32'd0 && _TECHMAP_CONSTVAL_SAXIGP0AWADDR_ === 32'd0) ? 32'b0 : SAXIGP0AWADDR;

  wire [1:0] saxigp0awburst = (_TECHMAP_CONSTMSK_SAXIGP0AWBURST_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIGP0AWBURST_ === 2'd0) ? 2'b0 : SAXIGP0AWBURST;

  wire [3:0] saxigp0awcache = (_TECHMAP_CONSTMSK_SAXIGP0AWCACHE_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIGP0AWCACHE_ === 4'd0) ? 4'b0 : SAXIGP0AWCACHE;

  wire [5:0] saxigp0awid = (_TECHMAP_CONSTMSK_SAXIGP0AWID_ == 6'd0 && _TECHMAP_CONSTVAL_SAXIGP0AWID_ === 6'd0) ? 6'b0 : SAXIGP0AWID;

  wire [3:0] saxigp0awlen = (_TECHMAP_CONSTMSK_SAXIGP0AWLEN_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIGP0AWLEN_ === 4'd0) ? 4'b0 : SAXIGP0AWLEN;

  wire [1:0] saxigp0awlock = (_TECHMAP_CONSTMSK_SAXIGP0AWLOCK_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIGP0AWLOCK_ === 2'd0) ? 2'b0 : SAXIGP0AWLOCK;

  wire [2:0] saxigp0awprot = (_TECHMAP_CONSTMSK_SAXIGP0AWPROT_ == 3'd0 && _TECHMAP_CONSTVAL_SAXIGP0AWPROT_ === 3'd0) ? 3'b0 : SAXIGP0AWPROT;

  wire [3:0] saxigp0awqos = (_TECHMAP_CONSTMSK_SAXIGP0AWQOS_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIGP0AWQOS_ === 4'd0) ? 4'b0 : SAXIGP0AWQOS;

  wire [1:0] saxigp0awsize = (_TECHMAP_CONSTMSK_SAXIGP0AWSIZE_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIGP0AWSIZE_ === 2'd0) ? 2'b0 : SAXIGP0AWSIZE;

  wire [0:0] saxigp0awvalid = (_TECHMAP_CONSTMSK_SAXIGP0AWVALID_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIGP0AWVALID_ === 1'd0) ? 1'b0 : SAXIGP0AWVALID;

  wire [0:0] saxigp0bready = (_TECHMAP_CONSTMSK_SAXIGP0BREADY_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIGP0BREADY_ === 1'd0) ? 1'b0 : SAXIGP0BREADY;

  wire [0:0] saxigp0rready = (_TECHMAP_CONSTMSK_SAXIGP0RREADY_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIGP0RREADY_ === 1'd0) ? 1'b0 : SAXIGP0RREADY;

  wire [31:0] saxigp0wdata = (_TECHMAP_CONSTMSK_SAXIGP0WDATA_ == 32'd0 && _TECHMAP_CONSTVAL_SAXIGP0WDATA_ === 32'd0) ? 32'b0 : SAXIGP0WDATA;

  wire [5:0] saxigp0wid = (_TECHMAP_CONSTMSK_SAXIGP0WID_ == 6'd0 && _TECHMAP_CONSTVAL_SAXIGP0WID_ === 6'd0) ? 6'b0 : SAXIGP0WID;

  wire [0:0] saxigp0wlast = (_TECHMAP_CONSTMSK_SAXIGP0WLAST_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIGP0WLAST_ === 1'd0) ? 1'b0 : SAXIGP0WLAST;

  wire [3:0] saxigp0wstrb = (_TECHMAP_CONSTMSK_SAXIGP0WSTRB_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIGP0WSTRB_ === 4'd0) ? 4'b0 : SAXIGP0WSTRB;

  wire [0:0] saxigp0wvalid = (_TECHMAP_CONSTMSK_SAXIGP0WVALID_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIGP0WVALID_ === 1'd0) ? 1'b0 : SAXIGP0WVALID;

  wire [0:0] saxigp1aclk = (_TECHMAP_CONSTMSK_SAXIGP1ACLK_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIGP1ACLK_ === 1'd0) ? 1'b0 : SAXIGP1ACLK;

  wire [31:0] saxigp1araddr = (_TECHMAP_CONSTMSK_SAXIGP1ARADDR_ == 32'd0 && _TECHMAP_CONSTVAL_SAXIGP1ARADDR_ === 32'd0) ? 32'b0 : SAXIGP1ARADDR;

  wire [1:0] saxigp1arburst = (_TECHMAP_CONSTMSK_SAXIGP1ARBURST_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIGP1ARBURST_ === 2'd0) ? 2'b0 : SAXIGP1ARBURST;

  wire [3:0] saxigp1arcache = (_TECHMAP_CONSTMSK_SAXIGP1ARCACHE_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIGP1ARCACHE_ === 4'd0) ? 4'b0 : SAXIGP1ARCACHE;

  wire [5:0] saxigp1arid = (_TECHMAP_CONSTMSK_SAXIGP1ARID_ == 6'd0 && _TECHMAP_CONSTVAL_SAXIGP1ARID_ === 6'd0) ? 6'b0 : SAXIGP1ARID;

  wire [3:0] saxigp1arlen = (_TECHMAP_CONSTMSK_SAXIGP1ARLEN_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIGP1ARLEN_ === 4'd0) ? 4'b0 : SAXIGP1ARLEN;

  wire [1:0] saxigp1arlock = (_TECHMAP_CONSTMSK_SAXIGP1ARLOCK_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIGP1ARLOCK_ === 2'd0) ? 2'b0 : SAXIGP1ARLOCK;

  wire [2:0] saxigp1arprot = (_TECHMAP_CONSTMSK_SAXIGP1ARPROT_ == 3'd0 && _TECHMAP_CONSTVAL_SAXIGP1ARPROT_ === 3'd0) ? 3'b0 : SAXIGP1ARPROT;

  wire [3:0] saxigp1arqos = (_TECHMAP_CONSTMSK_SAXIGP1ARQOS_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIGP1ARQOS_ === 4'd0) ? 4'b0 : SAXIGP1ARQOS;

  wire [1:0] saxigp1arsize = (_TECHMAP_CONSTMSK_SAXIGP1ARSIZE_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIGP1ARSIZE_ === 2'd0) ? 2'b0 : SAXIGP1ARSIZE;

  wire [0:0] saxigp1arvalid = (_TECHMAP_CONSTMSK_SAXIGP1ARVALID_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIGP1ARVALID_ === 1'd0) ? 1'b0 : SAXIGP1ARVALID;

  wire [31:0] saxigp1awaddr = (_TECHMAP_CONSTMSK_SAXIGP1AWADDR_ == 32'd0 && _TECHMAP_CONSTVAL_SAXIGP1AWADDR_ === 32'd0) ? 32'b0 : SAXIGP1AWADDR;

  wire [1:0] saxigp1awburst = (_TECHMAP_CONSTMSK_SAXIGP1AWBURST_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIGP1AWBURST_ === 2'd0) ? 2'b0 : SAXIGP1AWBURST;

  wire [3:0] saxigp1awcache = (_TECHMAP_CONSTMSK_SAXIGP1AWCACHE_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIGP1AWCACHE_ === 4'd0) ? 4'b0 : SAXIGP1AWCACHE;

  wire [5:0] saxigp1awid = (_TECHMAP_CONSTMSK_SAXIGP1AWID_ == 6'd0 && _TECHMAP_CONSTVAL_SAXIGP1AWID_ === 6'd0) ? 6'b0 : SAXIGP1AWID;

  wire [3:0] saxigp1awlen = (_TECHMAP_CONSTMSK_SAXIGP1AWLEN_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIGP1AWLEN_ === 4'd0) ? 4'b0 : SAXIGP1AWLEN;

  wire [1:0] saxigp1awlock = (_TECHMAP_CONSTMSK_SAXIGP1AWLOCK_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIGP1AWLOCK_ === 2'd0) ? 2'b0 : SAXIGP1AWLOCK;

  wire [2:0] saxigp1awprot = (_TECHMAP_CONSTMSK_SAXIGP1AWPROT_ == 3'd0 && _TECHMAP_CONSTVAL_SAXIGP1AWPROT_ === 3'd0) ? 3'b0 : SAXIGP1AWPROT;

  wire [3:0] saxigp1awqos = (_TECHMAP_CONSTMSK_SAXIGP1AWQOS_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIGP1AWQOS_ === 4'd0) ? 4'b0 : SAXIGP1AWQOS;

  wire [1:0] saxigp1awsize = (_TECHMAP_CONSTMSK_SAXIGP1AWSIZE_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIGP1AWSIZE_ === 2'd0) ? 2'b0 : SAXIGP1AWSIZE;

  wire [0:0] saxigp1awvalid = (_TECHMAP_CONSTMSK_SAXIGP1AWVALID_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIGP1AWVALID_ === 1'd0) ? 1'b0 : SAXIGP1AWVALID;

  wire [0:0] saxigp1bready = (_TECHMAP_CONSTMSK_SAXIGP1BREADY_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIGP1BREADY_ === 1'd0) ? 1'b0 : SAXIGP1BREADY;

  wire [0:0] saxigp1rready = (_TECHMAP_CONSTMSK_SAXIGP1RREADY_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIGP1RREADY_ === 1'd0) ? 1'b0 : SAXIGP1RREADY;

  wire [31:0] saxigp1wdata = (_TECHMAP_CONSTMSK_SAXIGP1WDATA_ == 32'd0 && _TECHMAP_CONSTVAL_SAXIGP1WDATA_ === 32'd0) ? 32'b0 : SAXIGP1WDATA;

  wire [5:0] saxigp1wid = (_TECHMAP_CONSTMSK_SAXIGP1WID_ == 6'd0 && _TECHMAP_CONSTVAL_SAXIGP1WID_ === 6'd0) ? 6'b0 : SAXIGP1WID;

  wire [0:0] saxigp1wlast = (_TECHMAP_CONSTMSK_SAXIGP1WLAST_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIGP1WLAST_ === 1'd0) ? 1'b0 : SAXIGP1WLAST;

  wire [3:0] saxigp1wstrb = (_TECHMAP_CONSTMSK_SAXIGP1WSTRB_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIGP1WSTRB_ === 4'd0) ? 4'b0 : SAXIGP1WSTRB;

  wire [0:0] saxigp1wvalid = (_TECHMAP_CONSTMSK_SAXIGP1WVALID_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIGP1WVALID_ === 1'd0) ? 1'b0 : SAXIGP1WVALID;

  wire [0:0] saxihp0aclk = (_TECHMAP_CONSTMSK_SAXIHP0ACLK_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP0ACLK_ === 1'd0) ? 1'b0 : SAXIHP0ACLK;

  wire [31:0] saxihp0araddr = (_TECHMAP_CONSTMSK_SAXIHP0ARADDR_ == 32'd0 && _TECHMAP_CONSTVAL_SAXIHP0ARADDR_ === 32'd0) ? 32'b0 : SAXIHP0ARADDR;

  wire [1:0] saxihp0arburst = (_TECHMAP_CONSTMSK_SAXIHP0ARBURST_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP0ARBURST_ === 2'd0) ? 2'b0 : SAXIHP0ARBURST;

  wire [3:0] saxihp0arcache = (_TECHMAP_CONSTMSK_SAXIHP0ARCACHE_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP0ARCACHE_ === 4'd0) ? 4'b0 : SAXIHP0ARCACHE;

  wire [5:0] saxihp0arid = (_TECHMAP_CONSTMSK_SAXIHP0ARID_ == 6'd0 && _TECHMAP_CONSTVAL_SAXIHP0ARID_ === 6'd0) ? 6'b0 : SAXIHP0ARID;

  wire [3:0] saxihp0arlen = (_TECHMAP_CONSTMSK_SAXIHP0ARLEN_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP0ARLEN_ === 4'd0) ? 4'b0 : SAXIHP0ARLEN;

  wire [1:0] saxihp0arlock = (_TECHMAP_CONSTMSK_SAXIHP0ARLOCK_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP0ARLOCK_ === 2'd0) ? 2'b0 : SAXIHP0ARLOCK;

  wire [2:0] saxihp0arprot = (_TECHMAP_CONSTMSK_SAXIHP0ARPROT_ == 3'd0 && _TECHMAP_CONSTVAL_SAXIHP0ARPROT_ === 3'd0) ? 3'b0 : SAXIHP0ARPROT;

  wire [3:0] saxihp0arqos = (_TECHMAP_CONSTMSK_SAXIHP0ARQOS_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP0ARQOS_ === 4'd0) ? 4'b0 : SAXIHP0ARQOS;

  wire [1:0] saxihp0arsize = (_TECHMAP_CONSTMSK_SAXIHP0ARSIZE_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP0ARSIZE_ === 2'd0) ? 2'b0 : SAXIHP0ARSIZE;

  wire [0:0] saxihp0arvalid = (_TECHMAP_CONSTMSK_SAXIHP0ARVALID_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP0ARVALID_ === 1'd0) ? 1'b0 : SAXIHP0ARVALID;

  wire [31:0] saxihp0awaddr = (_TECHMAP_CONSTMSK_SAXIHP0AWADDR_ == 32'd0 && _TECHMAP_CONSTVAL_SAXIHP0AWADDR_ === 32'd0) ? 32'b0 : SAXIHP0AWADDR;

  wire [1:0] saxihp0awburst = (_TECHMAP_CONSTMSK_SAXIHP0AWBURST_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP0AWBURST_ === 2'd0) ? 2'b0 : SAXIHP0AWBURST;

  wire [3:0] saxihp0awcache = (_TECHMAP_CONSTMSK_SAXIHP0AWCACHE_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP0AWCACHE_ === 4'd0) ? 4'b0 : SAXIHP0AWCACHE;

  wire [5:0] saxihp0awid = (_TECHMAP_CONSTMSK_SAXIHP0AWID_ == 6'd0 && _TECHMAP_CONSTVAL_SAXIHP0AWID_ === 6'd0) ? 6'b0 : SAXIHP0AWID;

  wire [3:0] saxihp0awlen = (_TECHMAP_CONSTMSK_SAXIHP0AWLEN_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP0AWLEN_ === 4'd0) ? 4'b0 : SAXIHP0AWLEN;

  wire [1:0] saxihp0awlock = (_TECHMAP_CONSTMSK_SAXIHP0AWLOCK_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP0AWLOCK_ === 2'd0) ? 2'b0 : SAXIHP0AWLOCK;

  wire [2:0] saxihp0awprot = (_TECHMAP_CONSTMSK_SAXIHP0AWPROT_ == 3'd0 && _TECHMAP_CONSTVAL_SAXIHP0AWPROT_ === 3'd0) ? 3'b0 : SAXIHP0AWPROT;

  wire [3:0] saxihp0awqos = (_TECHMAP_CONSTMSK_SAXIHP0AWQOS_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP0AWQOS_ === 4'd0) ? 4'b0 : SAXIHP0AWQOS;

  wire [1:0] saxihp0awsize = (_TECHMAP_CONSTMSK_SAXIHP0AWSIZE_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP0AWSIZE_ === 2'd0) ? 2'b0 : SAXIHP0AWSIZE;

  wire [0:0] saxihp0awvalid = (_TECHMAP_CONSTMSK_SAXIHP0AWVALID_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP0AWVALID_ === 1'd0) ? 1'b0 : SAXIHP0AWVALID;

  wire [0:0] saxihp0bready = (_TECHMAP_CONSTMSK_SAXIHP0BREADY_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP0BREADY_ === 1'd0) ? 1'b0 : SAXIHP0BREADY;

  wire [0:0] saxihp0rdissuecap1en = (_TECHMAP_CONSTMSK_SAXIHP0RDISSUECAP1EN_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP0RDISSUECAP1EN_ === 1'd0) ? 1'b0 : SAXIHP0RDISSUECAP1EN;

  wire [0:0] saxihp0rready = (_TECHMAP_CONSTMSK_SAXIHP0RREADY_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP0RREADY_ === 1'd0) ? 1'b0 : SAXIHP0RREADY;

  wire [63:0] saxihp0wdata = (_TECHMAP_CONSTMSK_SAXIHP0WDATA_ == 64'd0 && _TECHMAP_CONSTVAL_SAXIHP0WDATA_ === 64'd0) ? 64'b0 : SAXIHP0WDATA;

  wire [5:0] saxihp0wid = (_TECHMAP_CONSTMSK_SAXIHP0WID_ == 6'd0 && _TECHMAP_CONSTVAL_SAXIHP0WID_ === 6'd0) ? 6'b0 : SAXIHP0WID;

  wire [0:0] saxihp0wlast = (_TECHMAP_CONSTMSK_SAXIHP0WLAST_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP0WLAST_ === 1'd0) ? 1'b0 : SAXIHP0WLAST;

  wire [0:0] saxihp0wrissuecap1en = (_TECHMAP_CONSTMSK_SAXIHP0WRISSUECAP1EN_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP0WRISSUECAP1EN_ === 1'd0) ? 1'b0 : SAXIHP0WRISSUECAP1EN;

  wire [7:0] saxihp0wstrb = (_TECHMAP_CONSTMSK_SAXIHP0WSTRB_ == 8'd0 && _TECHMAP_CONSTVAL_SAXIHP0WSTRB_ === 8'd0) ? 8'b0 : SAXIHP0WSTRB;

  wire [0:0] saxihp0wvalid = (_TECHMAP_CONSTMSK_SAXIHP0WVALID_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP0WVALID_ === 1'd0) ? 1'b0 : SAXIHP0WVALID;

  wire [0:0] saxihp1aclk = (_TECHMAP_CONSTMSK_SAXIHP1ACLK_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP1ACLK_ === 1'd0) ? 1'b0 : SAXIHP1ACLK;

  wire [31:0] saxihp1araddr = (_TECHMAP_CONSTMSK_SAXIHP1ARADDR_ == 32'd0 && _TECHMAP_CONSTVAL_SAXIHP1ARADDR_ === 32'd0) ? 32'b0 : SAXIHP1ARADDR;

  wire [1:0] saxihp1arburst = (_TECHMAP_CONSTMSK_SAXIHP1ARBURST_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP1ARBURST_ === 2'd0) ? 2'b0 : SAXIHP1ARBURST;

  wire [3:0] saxihp1arcache = (_TECHMAP_CONSTMSK_SAXIHP1ARCACHE_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP1ARCACHE_ === 4'd0) ? 4'b0 : SAXIHP1ARCACHE;

  wire [5:0] saxihp1arid = (_TECHMAP_CONSTMSK_SAXIHP1ARID_ == 6'd0 && _TECHMAP_CONSTVAL_SAXIHP1ARID_ === 6'd0) ? 6'b0 : SAXIHP1ARID;

  wire [3:0] saxihp1arlen = (_TECHMAP_CONSTMSK_SAXIHP1ARLEN_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP1ARLEN_ === 4'd0) ? 4'b0 : SAXIHP1ARLEN;

  wire [1:0] saxihp1arlock = (_TECHMAP_CONSTMSK_SAXIHP1ARLOCK_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP1ARLOCK_ === 2'd0) ? 2'b0 : SAXIHP1ARLOCK;

  wire [2:0] saxihp1arprot = (_TECHMAP_CONSTMSK_SAXIHP1ARPROT_ == 3'd0 && _TECHMAP_CONSTVAL_SAXIHP1ARPROT_ === 3'd0) ? 3'b0 : SAXIHP1ARPROT;

  wire [3:0] saxihp1arqos = (_TECHMAP_CONSTMSK_SAXIHP1ARQOS_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP1ARQOS_ === 4'd0) ? 4'b0 : SAXIHP1ARQOS;

  wire [1:0] saxihp1arsize = (_TECHMAP_CONSTMSK_SAXIHP1ARSIZE_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP1ARSIZE_ === 2'd0) ? 2'b0 : SAXIHP1ARSIZE;

  wire [0:0] saxihp1arvalid = (_TECHMAP_CONSTMSK_SAXIHP1ARVALID_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP1ARVALID_ === 1'd0) ? 1'b0 : SAXIHP1ARVALID;

  wire [31:0] saxihp1awaddr = (_TECHMAP_CONSTMSK_SAXIHP1AWADDR_ == 32'd0 && _TECHMAP_CONSTVAL_SAXIHP1AWADDR_ === 32'd0) ? 32'b0 : SAXIHP1AWADDR;

  wire [1:0] saxihp1awburst = (_TECHMAP_CONSTMSK_SAXIHP1AWBURST_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP1AWBURST_ === 2'd0) ? 2'b0 : SAXIHP1AWBURST;

  wire [3:0] saxihp1awcache = (_TECHMAP_CONSTMSK_SAXIHP1AWCACHE_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP1AWCACHE_ === 4'd0) ? 4'b0 : SAXIHP1AWCACHE;

  wire [5:0] saxihp1awid = (_TECHMAP_CONSTMSK_SAXIHP1AWID_ == 6'd0 && _TECHMAP_CONSTVAL_SAXIHP1AWID_ === 6'd0) ? 6'b0 : SAXIHP1AWID;

  wire [3:0] saxihp1awlen = (_TECHMAP_CONSTMSK_SAXIHP1AWLEN_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP1AWLEN_ === 4'd0) ? 4'b0 : SAXIHP1AWLEN;

  wire [1:0] saxihp1awlock = (_TECHMAP_CONSTMSK_SAXIHP1AWLOCK_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP1AWLOCK_ === 2'd0) ? 2'b0 : SAXIHP1AWLOCK;

  wire [2:0] saxihp1awprot = (_TECHMAP_CONSTMSK_SAXIHP1AWPROT_ == 3'd0 && _TECHMAP_CONSTVAL_SAXIHP1AWPROT_ === 3'd0) ? 3'b0 : SAXIHP1AWPROT;

  wire [3:0] saxihp1awqos = (_TECHMAP_CONSTMSK_SAXIHP1AWQOS_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP1AWQOS_ === 4'd0) ? 4'b0 : SAXIHP1AWQOS;

  wire [1:0] saxihp1awsize = (_TECHMAP_CONSTMSK_SAXIHP1AWSIZE_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP1AWSIZE_ === 2'd0) ? 2'b0 : SAXIHP1AWSIZE;

  wire [0:0] saxihp1awvalid = (_TECHMAP_CONSTMSK_SAXIHP1AWVALID_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP1AWVALID_ === 1'd0) ? 1'b0 : SAXIHP1AWVALID;

  wire [0:0] saxihp1bready = (_TECHMAP_CONSTMSK_SAXIHP1BREADY_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP1BREADY_ === 1'd0) ? 1'b0 : SAXIHP1BREADY;

  wire [0:0] saxihp1rdissuecap1en = (_TECHMAP_CONSTMSK_SAXIHP1RDISSUECAP1EN_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP1RDISSUECAP1EN_ === 1'd0) ? 1'b0 : SAXIHP1RDISSUECAP1EN;

  wire [0:0] saxihp1rready = (_TECHMAP_CONSTMSK_SAXIHP1RREADY_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP1RREADY_ === 1'd0) ? 1'b0 : SAXIHP1RREADY;

  wire [63:0] saxihp1wdata = (_TECHMAP_CONSTMSK_SAXIHP1WDATA_ == 64'd0 && _TECHMAP_CONSTVAL_SAXIHP1WDATA_ === 64'd0) ? 64'b0 : SAXIHP1WDATA;

  wire [5:0] saxihp1wid = (_TECHMAP_CONSTMSK_SAXIHP1WID_ == 6'd0 && _TECHMAP_CONSTVAL_SAXIHP1WID_ === 6'd0) ? 6'b0 : SAXIHP1WID;

  wire [0:0] saxihp1wlast = (_TECHMAP_CONSTMSK_SAXIHP1WLAST_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP1WLAST_ === 1'd0) ? 1'b0 : SAXIHP1WLAST;

  wire [0:0] saxihp1wrissuecap1en = (_TECHMAP_CONSTMSK_SAXIHP1WRISSUECAP1EN_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP1WRISSUECAP1EN_ === 1'd0) ? 1'b0 : SAXIHP1WRISSUECAP1EN;

  wire [7:0] saxihp1wstrb = (_TECHMAP_CONSTMSK_SAXIHP1WSTRB_ == 8'd0 && _TECHMAP_CONSTVAL_SAXIHP1WSTRB_ === 8'd0) ? 8'b0 : SAXIHP1WSTRB;

  wire [0:0] saxihp1wvalid = (_TECHMAP_CONSTMSK_SAXIHP1WVALID_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP1WVALID_ === 1'd0) ? 1'b0 : SAXIHP1WVALID;

  wire [0:0] saxihp2aclk = (_TECHMAP_CONSTMSK_SAXIHP2ACLK_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP2ACLK_ === 1'd0) ? 1'b0 : SAXIHP2ACLK;

  wire [31:0] saxihp2araddr = (_TECHMAP_CONSTMSK_SAXIHP2ARADDR_ == 32'd0 && _TECHMAP_CONSTVAL_SAXIHP2ARADDR_ === 32'd0) ? 32'b0 : SAXIHP2ARADDR;

  wire [1:0] saxihp2arburst = (_TECHMAP_CONSTMSK_SAXIHP2ARBURST_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP2ARBURST_ === 2'd0) ? 2'b0 : SAXIHP2ARBURST;

  wire [3:0] saxihp2arcache = (_TECHMAP_CONSTMSK_SAXIHP2ARCACHE_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP2ARCACHE_ === 4'd0) ? 4'b0 : SAXIHP2ARCACHE;

  wire [5:0] saxihp2arid = (_TECHMAP_CONSTMSK_SAXIHP2ARID_ == 6'd0 && _TECHMAP_CONSTVAL_SAXIHP2ARID_ === 6'd0) ? 6'b0 : SAXIHP2ARID;

  wire [3:0] saxihp2arlen = (_TECHMAP_CONSTMSK_SAXIHP2ARLEN_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP2ARLEN_ === 4'd0) ? 4'b0 : SAXIHP2ARLEN;

  wire [1:0] saxihp2arlock = (_TECHMAP_CONSTMSK_SAXIHP2ARLOCK_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP2ARLOCK_ === 2'd0) ? 2'b0 : SAXIHP2ARLOCK;

  wire [2:0] saxihp2arprot = (_TECHMAP_CONSTMSK_SAXIHP2ARPROT_ == 3'd0 && _TECHMAP_CONSTVAL_SAXIHP2ARPROT_ === 3'd0) ? 3'b0 : SAXIHP2ARPROT;

  wire [3:0] saxihp2arqos = (_TECHMAP_CONSTMSK_SAXIHP2ARQOS_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP2ARQOS_ === 4'd0) ? 4'b0 : SAXIHP2ARQOS;

  wire [1:0] saxihp2arsize = (_TECHMAP_CONSTMSK_SAXIHP2ARSIZE_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP2ARSIZE_ === 2'd0) ? 2'b0 : SAXIHP2ARSIZE;

  wire [0:0] saxihp2arvalid = (_TECHMAP_CONSTMSK_SAXIHP2ARVALID_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP2ARVALID_ === 1'd0) ? 1'b0 : SAXIHP2ARVALID;

  wire [31:0] saxihp2awaddr = (_TECHMAP_CONSTMSK_SAXIHP2AWADDR_ == 32'd0 && _TECHMAP_CONSTVAL_SAXIHP2AWADDR_ === 32'd0) ? 32'b0 : SAXIHP2AWADDR;

  wire [1:0] saxihp2awburst = (_TECHMAP_CONSTMSK_SAXIHP2AWBURST_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP2AWBURST_ === 2'd0) ? 2'b0 : SAXIHP2AWBURST;

  wire [3:0] saxihp2awcache = (_TECHMAP_CONSTMSK_SAXIHP2AWCACHE_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP2AWCACHE_ === 4'd0) ? 4'b0 : SAXIHP2AWCACHE;

  wire [5:0] saxihp2awid = (_TECHMAP_CONSTMSK_SAXIHP2AWID_ == 6'd0 && _TECHMAP_CONSTVAL_SAXIHP2AWID_ === 6'd0) ? 6'b0 : SAXIHP2AWID;

  wire [3:0] saxihp2awlen = (_TECHMAP_CONSTMSK_SAXIHP2AWLEN_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP2AWLEN_ === 4'd0) ? 4'b0 : SAXIHP2AWLEN;

  wire [1:0] saxihp2awlock = (_TECHMAP_CONSTMSK_SAXIHP2AWLOCK_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP2AWLOCK_ === 2'd0) ? 2'b0 : SAXIHP2AWLOCK;

  wire [2:0] saxihp2awprot = (_TECHMAP_CONSTMSK_SAXIHP2AWPROT_ == 3'd0 && _TECHMAP_CONSTVAL_SAXIHP2AWPROT_ === 3'd0) ? 3'b0 : SAXIHP2AWPROT;

  wire [3:0] saxihp2awqos = (_TECHMAP_CONSTMSK_SAXIHP2AWQOS_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP2AWQOS_ === 4'd0) ? 4'b0 : SAXIHP2AWQOS;

  wire [1:0] saxihp2awsize = (_TECHMAP_CONSTMSK_SAXIHP2AWSIZE_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP2AWSIZE_ === 2'd0) ? 2'b0 : SAXIHP2AWSIZE;

  wire [0:0] saxihp2awvalid = (_TECHMAP_CONSTMSK_SAXIHP2AWVALID_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP2AWVALID_ === 1'd0) ? 1'b0 : SAXIHP2AWVALID;

  wire [0:0] saxihp2bready = (_TECHMAP_CONSTMSK_SAXIHP2BREADY_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP2BREADY_ === 1'd0) ? 1'b0 : SAXIHP2BREADY;

  wire [0:0] saxihp2rdissuecap1en = (_TECHMAP_CONSTMSK_SAXIHP2RDISSUECAP1EN_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP2RDISSUECAP1EN_ === 1'd0) ? 1'b0 : SAXIHP2RDISSUECAP1EN;

  wire [0:0] saxihp2rready = (_TECHMAP_CONSTMSK_SAXIHP2RREADY_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP2RREADY_ === 1'd0) ? 1'b0 : SAXIHP2RREADY;

  wire [63:0] saxihp2wdata = (_TECHMAP_CONSTMSK_SAXIHP2WDATA_ == 64'd0 && _TECHMAP_CONSTVAL_SAXIHP2WDATA_ === 64'd0) ? 64'b0 : SAXIHP2WDATA;

  wire [5:0] saxihp2wid = (_TECHMAP_CONSTMSK_SAXIHP2WID_ == 6'd0 && _TECHMAP_CONSTVAL_SAXIHP2WID_ === 6'd0) ? 6'b0 : SAXIHP2WID;

  wire [0:0] saxihp2wlast = (_TECHMAP_CONSTMSK_SAXIHP2WLAST_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP2WLAST_ === 1'd0) ? 1'b0 : SAXIHP2WLAST;

  wire [0:0] saxihp2wrissuecap1en = (_TECHMAP_CONSTMSK_SAXIHP2WRISSUECAP1EN_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP2WRISSUECAP1EN_ === 1'd0) ? 1'b0 : SAXIHP2WRISSUECAP1EN;

  wire [7:0] saxihp2wstrb = (_TECHMAP_CONSTMSK_SAXIHP2WSTRB_ == 8'd0 && _TECHMAP_CONSTVAL_SAXIHP2WSTRB_ === 8'd0) ? 8'b0 : SAXIHP2WSTRB;

  wire [0:0] saxihp2wvalid = (_TECHMAP_CONSTMSK_SAXIHP2WVALID_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP2WVALID_ === 1'd0) ? 1'b0 : SAXIHP2WVALID;

  wire [0:0] saxihp3aclk = (_TECHMAP_CONSTMSK_SAXIHP3ACLK_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP3ACLK_ === 1'd0) ? 1'b0 : SAXIHP3ACLK;

  wire [31:0] saxihp3araddr = (_TECHMAP_CONSTMSK_SAXIHP3ARADDR_ == 32'd0 && _TECHMAP_CONSTVAL_SAXIHP3ARADDR_ === 32'd0) ? 32'b0 : SAXIHP3ARADDR;

  wire [1:0] saxihp3arburst = (_TECHMAP_CONSTMSK_SAXIHP3ARBURST_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP3ARBURST_ === 2'd0) ? 2'b0 : SAXIHP3ARBURST;

  wire [3:0] saxihp3arcache = (_TECHMAP_CONSTMSK_SAXIHP3ARCACHE_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP3ARCACHE_ === 4'd0) ? 4'b0 : SAXIHP3ARCACHE;

  wire [5:0] saxihp3arid = (_TECHMAP_CONSTMSK_SAXIHP3ARID_ == 6'd0 && _TECHMAP_CONSTVAL_SAXIHP3ARID_ === 6'd0) ? 6'b0 : SAXIHP3ARID;

  wire [3:0] saxihp3arlen = (_TECHMAP_CONSTMSK_SAXIHP3ARLEN_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP3ARLEN_ === 4'd0) ? 4'b0 : SAXIHP3ARLEN;

  wire [1:0] saxihp3arlock = (_TECHMAP_CONSTMSK_SAXIHP3ARLOCK_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP3ARLOCK_ === 2'd0) ? 2'b0 : SAXIHP3ARLOCK;

  wire [2:0] saxihp3arprot = (_TECHMAP_CONSTMSK_SAXIHP3ARPROT_ == 3'd0 && _TECHMAP_CONSTVAL_SAXIHP3ARPROT_ === 3'd0) ? 3'b0 : SAXIHP3ARPROT;

  wire [3:0] saxihp3arqos = (_TECHMAP_CONSTMSK_SAXIHP3ARQOS_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP3ARQOS_ === 4'd0) ? 4'b0 : SAXIHP3ARQOS;

  wire [1:0] saxihp3arsize = (_TECHMAP_CONSTMSK_SAXIHP3ARSIZE_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP3ARSIZE_ === 2'd0) ? 2'b0 : SAXIHP3ARSIZE;

  wire [0:0] saxihp3arvalid = (_TECHMAP_CONSTMSK_SAXIHP3ARVALID_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP3ARVALID_ === 1'd0) ? 1'b0 : SAXIHP3ARVALID;

  wire [31:0] saxihp3awaddr = (_TECHMAP_CONSTMSK_SAXIHP3AWADDR_ == 32'd0 && _TECHMAP_CONSTVAL_SAXIHP3AWADDR_ === 32'd0) ? 32'b0 : SAXIHP3AWADDR;

  wire [1:0] saxihp3awburst = (_TECHMAP_CONSTMSK_SAXIHP3AWBURST_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP3AWBURST_ === 2'd0) ? 2'b0 : SAXIHP3AWBURST;

  wire [3:0] saxihp3awcache = (_TECHMAP_CONSTMSK_SAXIHP3AWCACHE_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP3AWCACHE_ === 4'd0) ? 4'b0 : SAXIHP3AWCACHE;

  wire [5:0] saxihp3awid = (_TECHMAP_CONSTMSK_SAXIHP3AWID_ == 6'd0 && _TECHMAP_CONSTVAL_SAXIHP3AWID_ === 6'd0) ? 6'b0 : SAXIHP3AWID;

  wire [3:0] saxihp3awlen = (_TECHMAP_CONSTMSK_SAXIHP3AWLEN_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP3AWLEN_ === 4'd0) ? 4'b0 : SAXIHP3AWLEN;

  wire [1:0] saxihp3awlock = (_TECHMAP_CONSTMSK_SAXIHP3AWLOCK_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP3AWLOCK_ === 2'd0) ? 2'b0 : SAXIHP3AWLOCK;

  wire [2:0] saxihp3awprot = (_TECHMAP_CONSTMSK_SAXIHP3AWPROT_ == 3'd0 && _TECHMAP_CONSTVAL_SAXIHP3AWPROT_ === 3'd0) ? 3'b0 : SAXIHP3AWPROT;

  wire [3:0] saxihp3awqos = (_TECHMAP_CONSTMSK_SAXIHP3AWQOS_ == 4'd0 && _TECHMAP_CONSTVAL_SAXIHP3AWQOS_ === 4'd0) ? 4'b0 : SAXIHP3AWQOS;

  wire [1:0] saxihp3awsize = (_TECHMAP_CONSTMSK_SAXIHP3AWSIZE_ == 2'd0 && _TECHMAP_CONSTVAL_SAXIHP3AWSIZE_ === 2'd0) ? 2'b0 : SAXIHP3AWSIZE;

  wire [0:0] saxihp3awvalid = (_TECHMAP_CONSTMSK_SAXIHP3AWVALID_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP3AWVALID_ === 1'd0) ? 1'b0 : SAXIHP3AWVALID;

  wire [0:0] saxihp3bready = (_TECHMAP_CONSTMSK_SAXIHP3BREADY_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP3BREADY_ === 1'd0) ? 1'b0 : SAXIHP3BREADY;

  wire [0:0] saxihp3rdissuecap1en = (_TECHMAP_CONSTMSK_SAXIHP3RDISSUECAP1EN_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP3RDISSUECAP1EN_ === 1'd0) ? 1'b0 : SAXIHP3RDISSUECAP1EN;

  wire [0:0] saxihp3rready = (_TECHMAP_CONSTMSK_SAXIHP3RREADY_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP3RREADY_ === 1'd0) ? 1'b0 : SAXIHP3RREADY;

  wire [63:0] saxihp3wdata = (_TECHMAP_CONSTMSK_SAXIHP3WDATA_ == 64'd0 && _TECHMAP_CONSTVAL_SAXIHP3WDATA_ === 64'd0) ? 64'b0 : SAXIHP3WDATA;

  wire [5:0] saxihp3wid = (_TECHMAP_CONSTMSK_SAXIHP3WID_ == 6'd0 && _TECHMAP_CONSTVAL_SAXIHP3WID_ === 6'd0) ? 6'b0 : SAXIHP3WID;

  wire [0:0] saxihp3wlast = (_TECHMAP_CONSTMSK_SAXIHP3WLAST_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP3WLAST_ === 1'd0) ? 1'b0 : SAXIHP3WLAST;

  wire [0:0] saxihp3wrissuecap1en = (_TECHMAP_CONSTMSK_SAXIHP3WRISSUECAP1EN_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP3WRISSUECAP1EN_ === 1'd0) ? 1'b0 : SAXIHP3WRISSUECAP1EN;

  wire [7:0] saxihp3wstrb = (_TECHMAP_CONSTMSK_SAXIHP3WSTRB_ == 8'd0 && _TECHMAP_CONSTVAL_SAXIHP3WSTRB_ === 8'd0) ? 8'b0 : SAXIHP3WSTRB;

  wire [0:0] saxihp3wvalid = (_TECHMAP_CONSTMSK_SAXIHP3WVALID_ == 1'd0 && _TECHMAP_CONSTVAL_SAXIHP3WVALID_ === 1'd0) ? 1'b0 : SAXIHP3WVALID;

  // Replacement cell.
  PS7_VPR _TECHMAP_REPLACE_ (
  .DDRARB                   (ddrarb),
  .DMA0ACLK                 (dma0aclk),
  .DMA0DAREADY              (dma0daready),
  .DMA0DATYPE               (DMA0DATYPE),
  .DMA0DAVALID              (DMA0DAVALID),
  .DMA0DRLAST               (dma0drlast),
  .DMA0DRREADY              (DMA0DRREADY),
  .DMA0DRTYPE               (dma0drtype),
  .DMA0DRVALID              (dma0drvalid),
  .DMA0RSTN                 (DMA0RSTN),
  .DMA1ACLK                 (dma1aclk),
  .DMA1DAREADY              (dma1daready),
  .DMA1DATYPE               (DMA1DATYPE),
  .DMA1DAVALID              (DMA1DAVALID),
  .DMA1DRLAST               (dma1drlast),
  .DMA1DRREADY              (DMA1DRREADY),
  .DMA1DRTYPE               (dma1drtype),
  .DMA1DRVALID              (dma1drvalid),
  .DMA1RSTN                 (DMA1RSTN),
  .DMA2ACLK                 (dma2aclk),
  .DMA2DAREADY              (dma2daready),
  .DMA2DATYPE               (DMA2DATYPE),
  .DMA2DAVALID              (DMA2DAVALID),
  .DMA2DRLAST               (dma2drlast),
  .DMA2DRREADY              (DMA2DRREADY),
  .DMA2DRTYPE               (dma2drtype),
  .DMA2DRVALID              (dma2drvalid),
  .DMA2RSTN                 (DMA2RSTN),
  .DMA3ACLK                 (dma3aclk),
  .DMA3DAREADY              (dma3daready),
  .DMA3DATYPE               (DMA3DATYPE),
  .DMA3DAVALID              (DMA3DAVALID),
  .DMA3DRLAST               (dma3drlast),
  .DMA3DRREADY              (DMA3DRREADY),
  .DMA3DRTYPE               (dma3drtype),
  .DMA3DRVALID              (dma3drvalid),
  .DMA3RSTN                 (DMA3RSTN),
  .EMIOCAN0PHYRX            (emiocan0phyrx),
  .EMIOCAN0PHYTX            (EMIOCAN0PHYTX),
  .EMIOCAN1PHYRX            (emiocan1phyrx),
  .EMIOCAN1PHYTX            (EMIOCAN1PHYTX),
  .EMIOENET0EXTINTIN        (emioenet0extintin),
  .EMIOENET0GMIICOL         (emioenet0gmiicol),
  .EMIOENET0GMIICRS         (emioenet0gmiicrs),
  .EMIOENET0GMIIRXCLK       (emioenet0gmiirxclk),
  .EMIOENET0GMIIRXD         (emioenet0gmiirxd),
  .EMIOENET0GMIIRXDV        (emioenet0gmiirxdv),
  .EMIOENET0GMIIRXER        (emioenet0gmiirxer),
  .EMIOENET0GMIITXCLK       (emioenet0gmiitxclk),
  .EMIOENET0GMIITXD         (EMIOENET0GMIITXD),
  .EMIOENET0GMIITXEN        (EMIOENET0GMIITXEN),
  .EMIOENET0GMIITXER        (EMIOENET0GMIITXER),
  .EMIOENET0MDIOI           (emioenet0mdioi),
  .EMIOENET0MDIOMDC         (EMIOENET0MDIOMDC),
  .EMIOENET0MDIOO           (EMIOENET0MDIOO),
  .EMIOENET0MDIOTN          (EMIOENET0MDIOTN),
  .EMIOENET0PTPDELAYREQRX   (EMIOENET0PTPDELAYREQRX),
  .EMIOENET0PTPDELAYREQTX   (EMIOENET0PTPDELAYREQTX),
  .EMIOENET0PTPPDELAYREQRX  (EMIOENET0PTPPDELAYREQRX),
  .EMIOENET0PTPPDELAYREQTX  (EMIOENET0PTPPDELAYREQTX),
  .EMIOENET0PTPPDELAYRESPRX (EMIOENET0PTPPDELAYRESPRX),
  .EMIOENET0PTPPDELAYRESPTX (EMIOENET0PTPPDELAYRESPTX),
  .EMIOENET0PTPSYNCFRAMERX  (EMIOENET0PTPSYNCFRAMERX),
  .EMIOENET0PTPSYNCFRAMETX  (EMIOENET0PTPSYNCFRAMETX),
  .EMIOENET0SOFRX           (EMIOENET0SOFRX),
  .EMIOENET0SOFTX           (EMIOENET0SOFTX),
  .EMIOENET1EXTINTIN        (emioenet1extintin),
  .EMIOENET1GMIICOL         (emioenet1gmiicol),
  .EMIOENET1GMIICRS         (emioenet1gmiicrs),
  .EMIOENET1GMIIRXCLK       (emioenet1gmiirxclk),
  .EMIOENET1GMIIRXD         (emioenet1gmiirxd),
  .EMIOENET1GMIIRXDV        (emioenet1gmiirxdv),
  .EMIOENET1GMIIRXER        (emioenet1gmiirxer),
  .EMIOENET1GMIITXCLK       (emioenet1gmiitxclk),
  .EMIOENET1GMIITXD         (EMIOENET1GMIITXD),
  .EMIOENET1GMIITXEN        (EMIOENET1GMIITXEN),
  .EMIOENET1GMIITXER        (EMIOENET1GMIITXER),
  .EMIOENET1MDIOI           (emioenet1mdioi),
  .EMIOENET1MDIOMDC         (EMIOENET1MDIOMDC),
  .EMIOENET1MDIOO           (EMIOENET1MDIOO),
  .EMIOENET1MDIOTN          (EMIOENET1MDIOTN),
  .EMIOENET1PTPDELAYREQRX   (EMIOENET1PTPDELAYREQRX),
  .EMIOENET1PTPDELAYREQTX   (EMIOENET1PTPDELAYREQTX),
  .EMIOENET1PTPPDELAYREQRX  (EMIOENET1PTPPDELAYREQRX),
  .EMIOENET1PTPPDELAYREQTX  (EMIOENET1PTPPDELAYREQTX),
  .EMIOENET1PTPPDELAYRESPRX (EMIOENET1PTPPDELAYRESPRX),
  .EMIOENET1PTPPDELAYRESPTX (EMIOENET1PTPPDELAYRESPTX),
  .EMIOENET1PTPSYNCFRAMERX  (EMIOENET1PTPSYNCFRAMERX),
  .EMIOENET1PTPSYNCFRAMETX  (EMIOENET1PTPSYNCFRAMETX),
  .EMIOENET1SOFRX           (EMIOENET1SOFRX),
  .EMIOENET1SOFTX           (EMIOENET1SOFTX),
  .EMIOGPIOI                (emiogpioi),
  .EMIOGPIOO                (EMIOGPIOO),
  .EMIOGPIOTN               (EMIOGPIOTN),
  .EMIOI2C0SCLI             (emioi2c0scli),
  .EMIOI2C0SCLO             (EMIOI2C0SCLO),
  .EMIOI2C0SCLTN            (EMIOI2C0SCLTN),
  .EMIOI2C0SDAI             (emioi2c0sdai),
  .EMIOI2C0SDAO             (EMIOI2C0SDAO),
  .EMIOI2C0SDATN            (EMIOI2C0SDATN),
  .EMIOI2C1SCLI             (emioi2c1scli),
  .EMIOI2C1SCLO             (EMIOI2C1SCLO),
  .EMIOI2C1SCLTN            (EMIOI2C1SCLTN),
  .EMIOI2C1SDAI             (emioi2c1sdai),
  .EMIOI2C1SDAO             (EMIOI2C1SDAO),
  .EMIOI2C1SDATN            (EMIOI2C1SDATN),
  .EMIOPJTAGTCK             (emiopjtagtck),
  .EMIOPJTAGTDI             (emiopjtagtdi),
  .EMIOPJTAGTDO             (EMIOPJTAGTDO),
  .EMIOPJTAGTDTN            (EMIOPJTAGTDTN),
  .EMIOPJTAGTMS             (emiopjtagtms),
  .EMIOSDIO0BUSPOW          (EMIOSDIO0BUSPOW),
  .EMIOSDIO0BUSVOLT         (EMIOSDIO0BUSVOLT),
  .EMIOSDIO0CDN             (emiosdio0cdn),
  .EMIOSDIO0CLK             (EMIOSDIO0CLK),
  .EMIOSDIO0CLKFB           (emiosdio0clkfb),
  .EMIOSDIO0CMDI            (emiosdio0cmdi),
  .EMIOSDIO0CMDO            (EMIOSDIO0CMDO),
  .EMIOSDIO0CMDTN           (EMIOSDIO0CMDTN),
  .EMIOSDIO0DATAI           (emiosdio0datai),
  .EMIOSDIO0DATAO           (EMIOSDIO0DATAO),
  .EMIOSDIO0DATATN          (EMIOSDIO0DATATN),
  .EMIOSDIO0LED             (EMIOSDIO0LED),
  .EMIOSDIO0WP              (emiosdio0wp),
  .EMIOSDIO1BUSPOW          (EMIOSDIO1BUSPOW),
  .EMIOSDIO1BUSVOLT         (EMIOSDIO1BUSVOLT),
  .EMIOSDIO1CDN             (emiosdio1cdn),
  .EMIOSDIO1CLK             (EMIOSDIO1CLK),
  .EMIOSDIO1CLKFB           (emiosdio1clkfb),
  .EMIOSDIO1CMDI            (emiosdio1cmdi),
  .EMIOSDIO1CMDO            (EMIOSDIO1CMDO),
  .EMIOSDIO1CMDTN           (EMIOSDIO1CMDTN),
  .EMIOSDIO1DATAI           (emiosdio1datai),
  .EMIOSDIO1DATAO           (EMIOSDIO1DATAO),
  .EMIOSDIO1DATATN          (EMIOSDIO1DATATN),
  .EMIOSDIO1LED             (EMIOSDIO1LED),
  .EMIOSDIO1WP              (emiosdio1wp),
  .EMIOSPI0MI               (emiospi0mi),
  .EMIOSPI0MO               (EMIOSPI0MO),
  .EMIOSPI0MOTN             (EMIOSPI0MOTN),
  .EMIOSPI0SCLKI            (emiospi0sclki),
  .EMIOSPI0SCLKO            (EMIOSPI0SCLKO),
  .EMIOSPI0SCLKTN           (EMIOSPI0SCLKTN),
  .EMIOSPI0SI               (emiospi0si),
  .EMIOSPI0SO               (EMIOSPI0SO),
  .EMIOSPI0SSIN             (emiospi0ssin),
  .EMIOSPI0SSNTN            (EMIOSPI0SSNTN),
  .EMIOSPI0SSON             (EMIOSPI0SSON),
  .EMIOSPI0STN              (EMIOSPI0STN),
  .EMIOSPI1MI               (emiospi1mi),
  .EMIOSPI1MO               (EMIOSPI1MO),
  .EMIOSPI1MOTN             (EMIOSPI1MOTN),
  .EMIOSPI1SCLKI            (emiospi1sclki),
  .EMIOSPI1SCLKO            (EMIOSPI1SCLKO),
  .EMIOSPI1SCLKTN           (EMIOSPI1SCLKTN),
  .EMIOSPI1SI               (emiospi1si),
  .EMIOSPI1SO               (EMIOSPI1SO),
  .EMIOSPI1SSIN             (emiospi1ssin),
  .EMIOSPI1SSNTN            (EMIOSPI1SSNTN),
  .EMIOSPI1SSON             (EMIOSPI1SSON),
  .EMIOSPI1STN              (EMIOSPI1STN),
  .EMIOSRAMINTIN            (emiosramintin),
  .EMIOTRACECLK             (emiotraceclk),
  .EMIOTRACECTL             (EMIOTRACECTL),
  .EMIOTRACEDATA            (EMIOTRACEDATA),
  .EMIOTTC0CLKI             (emiottc0clki),
  .EMIOTTC0WAVEO            (EMIOTTC0WAVEO),
  .EMIOTTC1CLKI             (emiottc1clki),
  .EMIOTTC1WAVEO            (EMIOTTC1WAVEO),
  .EMIOUART0CTSN            (emiouart0ctsn),
  .EMIOUART0DCDN            (emiouart0dcdn),
  .EMIOUART0DSRN            (emiouart0dsrn),
  .EMIOUART0DTRN            (EMIOUART0DTRN),
  .EMIOUART0RIN             (emiouart0rin),
  .EMIOUART0RTSN            (EMIOUART0RTSN),
  .EMIOUART0RX              (emiouart0rx),
  .EMIOUART0TX              (EMIOUART0TX),
  .EMIOUART1CTSN            (emiouart1ctsn),
  .EMIOUART1DCDN            (emiouart1dcdn),
  .EMIOUART1DSRN            (emiouart1dsrn),
  .EMIOUART1DTRN            (EMIOUART1DTRN),
  .EMIOUART1RIN             (emiouart1rin),
  .EMIOUART1RTSN            (EMIOUART1RTSN),
  .EMIOUART1RX              (emiouart1rx),
  .EMIOUART1TX              (EMIOUART1TX),
  .EMIOUSB0PORTINDCTL       (EMIOUSB0PORTINDCTL),
  .EMIOUSB0VBUSPWRFAULT     (emiousb0vbuspwrfault),
  .EMIOUSB0VBUSPWRSELECT    (EMIOUSB0VBUSPWRSELECT),
  .EMIOUSB1PORTINDCTL       (EMIOUSB1PORTINDCTL),
  .EMIOUSB1VBUSPWRFAULT     (emiousb1vbuspwrfault),
  .EMIOUSB1VBUSPWRSELECT    (EMIOUSB1VBUSPWRSELECT),
  .EMIOWDTCLKI              (emiowdtclki),
  .EMIOWDTRSTO              (EMIOWDTRSTO),
  .EVENTEVENTI              (eventeventi),
  .EVENTEVENTO              (EVENTEVENTO),
  .EVENTSTANDBYWFE          (EVENTSTANDBYWFE),
  .EVENTSTANDBYWFI          (EVENTSTANDBYWFI),
  .FCLKCLK                  (FCLKCLK),
  .FCLKCLKTRIGN             (fclkclktrign),
  .FCLKRESETN               (FCLKRESETN),
  .FPGAIDLEN                (fpgaidlen),
  .FTMDTRACEINATID          (ftmdtraceinatid),
  .FTMDTRACEINCLOCK         (ftmdtraceinclock),
  .FTMDTRACEINDATA          (ftmdtraceindata),
  .FTMDTRACEINVALID         (ftmdtraceinvalid),
  .FTMTF2PDEBUG             (ftmtf2pdebug),
  .FTMTF2PTRIG              (ftmtf2ptrig),
  .FTMTF2PTRIGACK           (FTMTF2PTRIGACK),
  .FTMTP2FDEBUG             (FTMTP2FDEBUG),
  .FTMTP2FTRIG              (FTMTP2FTRIG),
  .FTMTP2FTRIGACK           (ftmtp2ftrigack),
  .IRQF2P                   (irqf2p),
  .IRQP2F                   (IRQP2F),
  .MAXIGP0ACLK              (maxigp0aclk),
  .MAXIGP0ARADDR            (MAXIGP0ARADDR),
  .MAXIGP0ARBURST           (MAXIGP0ARBURST),
  .MAXIGP0ARCACHE           (MAXIGP0ARCACHE),
  .MAXIGP0ARESETN           (MAXIGP0ARESETN),
  .MAXIGP0ARID              (MAXIGP0ARID),
  .MAXIGP0ARLEN             (MAXIGP0ARLEN),
  .MAXIGP0ARLOCK            (MAXIGP0ARLOCK),
  .MAXIGP0ARPROT            (MAXIGP0ARPROT),
  .MAXIGP0ARQOS             (MAXIGP0ARQOS),
  .MAXIGP0ARREADY           (maxigp0arready),
  .MAXIGP0ARSIZE            (MAXIGP0ARSIZE),
  .MAXIGP0ARVALID           (MAXIGP0ARVALID),
  .MAXIGP0AWADDR            (MAXIGP0AWADDR),
  .MAXIGP0AWBURST           (MAXIGP0AWBURST),
  .MAXIGP0AWCACHE           (MAXIGP0AWCACHE),
  .MAXIGP0AWID              (MAXIGP0AWID),
  .MAXIGP0AWLEN             (MAXIGP0AWLEN),
  .MAXIGP0AWLOCK            (MAXIGP0AWLOCK),
  .MAXIGP0AWPROT            (MAXIGP0AWPROT),
  .MAXIGP0AWQOS             (MAXIGP0AWQOS),
  .MAXIGP0AWREADY           (maxigp0awready),
  .MAXIGP0AWSIZE            (MAXIGP0AWSIZE),
  .MAXIGP0AWVALID           (MAXIGP0AWVALID),
  .MAXIGP0BID               (maxigp0bid),
  .MAXIGP0BREADY            (MAXIGP0BREADY),
  .MAXIGP0BRESP             (maxigp0bresp),
  .MAXIGP0BVALID            (maxigp0bvalid),
  .MAXIGP0RDATA             (maxigp0rdata),
  .MAXIGP0RID               (maxigp0rid),
  .MAXIGP0RLAST             (maxigp0rlast),
  .MAXIGP0RREADY            (MAXIGP0RREADY),
  .MAXIGP0RRESP             (maxigp0rresp),
  .MAXIGP0RVALID            (maxigp0rvalid),
  .MAXIGP0WDATA             (MAXIGP0WDATA),
  .MAXIGP0WID               (MAXIGP0WID),
  .MAXIGP0WLAST             (MAXIGP0WLAST),
  .MAXIGP0WREADY            (maxigp0wready),
  .MAXIGP0WSTRB             (MAXIGP0WSTRB),
  .MAXIGP0WVALID            (MAXIGP0WVALID),
  .MAXIGP1ACLK              (maxigp1aclk),
  .MAXIGP1ARADDR            (MAXIGP1ARADDR),
  .MAXIGP1ARBURST           (MAXIGP1ARBURST),
  .MAXIGP1ARCACHE           (MAXIGP1ARCACHE),
  .MAXIGP1ARESETN           (MAXIGP1ARESETN),
  .MAXIGP1ARID              (MAXIGP1ARID),
  .MAXIGP1ARLEN             (MAXIGP1ARLEN),
  .MAXIGP1ARLOCK            (MAXIGP1ARLOCK),
  .MAXIGP1ARPROT            (MAXIGP1ARPROT),
  .MAXIGP1ARQOS             (MAXIGP1ARQOS),
  .MAXIGP1ARREADY           (maxigp1arready),
  .MAXIGP1ARSIZE            (MAXIGP1ARSIZE),
  .MAXIGP1ARVALID           (MAXIGP1ARVALID),
  .MAXIGP1AWADDR            (MAXIGP1AWADDR),
  .MAXIGP1AWBURST           (MAXIGP1AWBURST),
  .MAXIGP1AWCACHE           (MAXIGP1AWCACHE),
  .MAXIGP1AWID              (MAXIGP1AWID),
  .MAXIGP1AWLEN             (MAXIGP1AWLEN),
  .MAXIGP1AWLOCK            (MAXIGP1AWLOCK),
  .MAXIGP1AWPROT            (MAXIGP1AWPROT),
  .MAXIGP1AWQOS             (MAXIGP1AWQOS),
  .MAXIGP1AWREADY           (maxigp1awready),
  .MAXIGP1AWSIZE            (MAXIGP1AWSIZE),
  .MAXIGP1AWVALID           (MAXIGP1AWVALID),
  .MAXIGP1BID               (maxigp1bid),
  .MAXIGP1BREADY            (MAXIGP1BREADY),
  .MAXIGP1BRESP             (maxigp1bresp),
  .MAXIGP1BVALID            (maxigp1bvalid),
  .MAXIGP1RDATA             (maxigp1rdata),
  .MAXIGP1RID               (maxigp1rid),
  .MAXIGP1RLAST             (maxigp1rlast),
  .MAXIGP1RREADY            (MAXIGP1RREADY),
  .MAXIGP1RRESP             (maxigp1rresp),
  .MAXIGP1RVALID            (maxigp1rvalid),
  .MAXIGP1WDATA             (MAXIGP1WDATA),
  .MAXIGP1WID               (MAXIGP1WID),
  .MAXIGP1WLAST             (MAXIGP1WLAST),
  .MAXIGP1WREADY            (maxigp1wready),
  .MAXIGP1WSTRB             (MAXIGP1WSTRB),
  .MAXIGP1WVALID            (MAXIGP1WVALID),
  .SAXIACPACLK              (saxiacpaclk),
  .SAXIACPARADDR            (saxiacparaddr),
  .SAXIACPARBURST           (saxiacparburst),
  .SAXIACPARCACHE           (saxiacparcache),
  .SAXIACPARESETN           (SAXIACPARESETN),
  .SAXIACPARID              (saxiacparid),
  .SAXIACPARLEN             (saxiacparlen),
  .SAXIACPARLOCK            (saxiacparlock),
  .SAXIACPARPROT            (saxiacparprot),
  .SAXIACPARQOS             (saxiacparqos),
  .SAXIACPARREADY           (SAXIACPARREADY),
  .SAXIACPARSIZE            (saxiacparsize),
  .SAXIACPARUSER            (saxiacparuser),
  .SAXIACPARVALID           (saxiacparvalid),
  .SAXIACPAWADDR            (saxiacpawaddr),
  .SAXIACPAWBURST           (saxiacpawburst),
  .SAXIACPAWCACHE           (saxiacpawcache),
  .SAXIACPAWID              (saxiacpawid),
  .SAXIACPAWLEN             (saxiacpawlen),
  .SAXIACPAWLOCK            (saxiacpawlock),
  .SAXIACPAWPROT            (saxiacpawprot),
  .SAXIACPAWQOS             (saxiacpawqos),
  .SAXIACPAWREADY           (SAXIACPAWREADY),
  .SAXIACPAWSIZE            (saxiacpawsize),
  .SAXIACPAWUSER            (saxiacpawuser),
  .SAXIACPAWVALID           (saxiacpawvalid),
  .SAXIACPBID               (SAXIACPBID),
  .SAXIACPBREADY            (saxiacpbready),
  .SAXIACPBRESP             (SAXIACPBRESP),
  .SAXIACPBVALID            (SAXIACPBVALID),
  .SAXIACPRDATA             (SAXIACPRDATA),
  .SAXIACPRID               (SAXIACPRID),
  .SAXIACPRLAST             (SAXIACPRLAST),
  .SAXIACPRREADY            (saxiacprready),
  .SAXIACPRRESP             (SAXIACPRRESP),
  .SAXIACPRVALID            (SAXIACPRVALID),
  .SAXIACPWDATA             (saxiacpwdata),
  .SAXIACPWID               (saxiacpwid),
  .SAXIACPWLAST             (saxiacpwlast),
  .SAXIACPWREADY            (SAXIACPWREADY),
  .SAXIACPWSTRB             (saxiacpwstrb),
  .SAXIACPWVALID            (saxiacpwvalid),
  .SAXIGP0ACLK              (saxigp0aclk),
  .SAXIGP0ARADDR            (saxigp0araddr),
  .SAXIGP0ARBURST           (saxigp0arburst),
  .SAXIGP0ARCACHE           (saxigp0arcache),
  .SAXIGP0ARESETN           (SAXIGP0ARESETN),
  .SAXIGP0ARID              (saxigp0arid),
  .SAXIGP0ARLEN             (saxigp0arlen),
  .SAXIGP0ARLOCK            (saxigp0arlock),
  .SAXIGP0ARPROT            (saxigp0arprot),
  .SAXIGP0ARQOS             (saxigp0arqos),
  .SAXIGP0ARREADY           (SAXIGP0ARREADY),
  .SAXIGP0ARSIZE            (saxigp0arsize),
  .SAXIGP0ARVALID           (saxigp0arvalid),
  .SAXIGP0AWADDR            (saxigp0awaddr),
  .SAXIGP0AWBURST           (saxigp0awburst),
  .SAXIGP0AWCACHE           (saxigp0awcache),
  .SAXIGP0AWID              (saxigp0awid),
  .SAXIGP0AWLEN             (saxigp0awlen),
  .SAXIGP0AWLOCK            (saxigp0awlock),
  .SAXIGP0AWPROT            (saxigp0awprot),
  .SAXIGP0AWQOS             (saxigp0awqos),
  .SAXIGP0AWREADY           (SAXIGP0AWREADY),
  .SAXIGP0AWSIZE            (saxigp0awsize),
  .SAXIGP0AWVALID           (saxigp0awvalid),
  .SAXIGP0BID               (SAXIGP0BID),
  .SAXIGP0BREADY            (saxigp0bready),
  .SAXIGP0BRESP             (SAXIGP0BRESP),
  .SAXIGP0BVALID            (SAXIGP0BVALID),
  .SAXIGP0RDATA             (SAXIGP0RDATA),
  .SAXIGP0RID               (SAXIGP0RID),
  .SAXIGP0RLAST             (SAXIGP0RLAST),
  .SAXIGP0RREADY            (saxigp0rready),
  .SAXIGP0RRESP             (SAXIGP0RRESP),
  .SAXIGP0RVALID            (SAXIGP0RVALID),
  .SAXIGP0WDATA             (saxigp0wdata),
  .SAXIGP0WID               (saxigp0wid),
  .SAXIGP0WLAST             (saxigp0wlast),
  .SAXIGP0WREADY            (SAXIGP0WREADY),
  .SAXIGP0WSTRB             (saxigp0wstrb),
  .SAXIGP0WVALID            (saxigp0wvalid),
  .SAXIGP1ACLK              (saxigp1aclk),
  .SAXIGP1ARADDR            (saxigp1araddr),
  .SAXIGP1ARBURST           (saxigp1arburst),
  .SAXIGP1ARCACHE           (saxigp1arcache),
  .SAXIGP1ARESETN           (SAXIGP1ARESETN),
  .SAXIGP1ARID              (saxigp1arid),
  .SAXIGP1ARLEN             (saxigp1arlen),
  .SAXIGP1ARLOCK            (saxigp1arlock),
  .SAXIGP1ARPROT            (saxigp1arprot),
  .SAXIGP1ARQOS             (saxigp1arqos),
  .SAXIGP1ARREADY           (SAXIGP1ARREADY),
  .SAXIGP1ARSIZE            (saxigp1arsize),
  .SAXIGP1ARVALID           (saxigp1arvalid),
  .SAXIGP1AWADDR            (saxigp1awaddr),
  .SAXIGP1AWBURST           (saxigp1awburst),
  .SAXIGP1AWCACHE           (saxigp1awcache),
  .SAXIGP1AWID              (saxigp1awid),
  .SAXIGP1AWLEN             (saxigp1awlen),
  .SAXIGP1AWLOCK            (saxigp1awlock),
  .SAXIGP1AWPROT            (saxigp1awprot),
  .SAXIGP1AWQOS             (saxigp1awqos),
  .SAXIGP1AWREADY           (SAXIGP1AWREADY),
  .SAXIGP1AWSIZE            (saxigp1awsize),
  .SAXIGP1AWVALID           (saxigp1awvalid),
  .SAXIGP1BID               (SAXIGP1BID),
  .SAXIGP1BREADY            (saxigp1bready),
  .SAXIGP1BRESP             (SAXIGP1BRESP),
  .SAXIGP1BVALID            (SAXIGP1BVALID),
  .SAXIGP1RDATA             (SAXIGP1RDATA),
  .SAXIGP1RID               (SAXIGP1RID),
  .SAXIGP1RLAST             (SAXIGP1RLAST),
  .SAXIGP1RREADY            (saxigp1rready),
  .SAXIGP1RRESP             (SAXIGP1RRESP),
  .SAXIGP1RVALID            (SAXIGP1RVALID),
  .SAXIGP1WDATA             (saxigp1wdata),
  .SAXIGP1WID               (saxigp1wid),
  .SAXIGP1WLAST             (saxigp1wlast),
  .SAXIGP1WREADY            (SAXIGP1WREADY),
  .SAXIGP1WSTRB             (saxigp1wstrb),
  .SAXIGP1WVALID            (saxigp1wvalid),
  .SAXIHP0ACLK              (saxihp0aclk),
  .SAXIHP0ARADDR            (saxihp0araddr),
  .SAXIHP0ARBURST           (saxihp0arburst),
  .SAXIHP0ARCACHE           (saxihp0arcache),
  .SAXIHP0ARESETN           (SAXIHP0ARESETN),
  .SAXIHP0ARID              (saxihp0arid),
  .SAXIHP0ARLEN             (saxihp0arlen),
  .SAXIHP0ARLOCK            (saxihp0arlock),
  .SAXIHP0ARPROT            (saxihp0arprot),
  .SAXIHP0ARQOS             (saxihp0arqos),
  .SAXIHP0ARREADY           (SAXIHP0ARREADY),
  .SAXIHP0ARSIZE            (saxihp0arsize),
  .SAXIHP0ARVALID           (saxihp0arvalid),
  .SAXIHP0AWADDR            (saxihp0awaddr),
  .SAXIHP0AWBURST           (saxihp0awburst),
  .SAXIHP0AWCACHE           (saxihp0awcache),
  .SAXIHP0AWID              (saxihp0awid),
  .SAXIHP0AWLEN             (saxihp0awlen),
  .SAXIHP0AWLOCK            (saxihp0awlock),
  .SAXIHP0AWPROT            (saxihp0awprot),
  .SAXIHP0AWQOS             (saxihp0awqos),
  .SAXIHP0AWREADY           (SAXIHP0AWREADY),
  .SAXIHP0AWSIZE            (saxihp0awsize),
  .SAXIHP0AWVALID           (saxihp0awvalid),
  .SAXIHP0BID               (SAXIHP0BID),
  .SAXIHP0BREADY            (saxihp0bready),
  .SAXIHP0BRESP             (SAXIHP0BRESP),
  .SAXIHP0BVALID            (SAXIHP0BVALID),
  .SAXIHP0RACOUNT           (SAXIHP0RACOUNT),
  .SAXIHP0RCOUNT            (SAXIHP0RCOUNT),
  .SAXIHP0RDATA             (SAXIHP0RDATA),
  .SAXIHP0RDISSUECAP1EN     (saxihp0rdissuecap1en),
  .SAXIHP0RID               (SAXIHP0RID),
  .SAXIHP0RLAST             (SAXIHP0RLAST),
  .SAXIHP0RREADY            (saxihp0rready),
  .SAXIHP0RRESP             (SAXIHP0RRESP),
  .SAXIHP0RVALID            (SAXIHP0RVALID),
  .SAXIHP0WACOUNT           (SAXIHP0WACOUNT),
  .SAXIHP0WCOUNT            (SAXIHP0WCOUNT),
  .SAXIHP0WDATA             (saxihp0wdata),
  .SAXIHP0WID               (saxihp0wid),
  .SAXIHP0WLAST             (saxihp0wlast),
  .SAXIHP0WREADY            (SAXIHP0WREADY),
  .SAXIHP0WRISSUECAP1EN     (saxihp0wrissuecap1en),
  .SAXIHP0WSTRB             (saxihp0wstrb),
  .SAXIHP0WVALID            (saxihp0wvalid),
  .SAXIHP1ACLK              (saxihp1aclk),
  .SAXIHP1ARADDR            (saxihp1araddr),
  .SAXIHP1ARBURST           (saxihp1arburst),
  .SAXIHP1ARCACHE           (saxihp1arcache),
  .SAXIHP1ARESETN           (SAXIHP1ARESETN),
  .SAXIHP1ARID              (saxihp1arid),
  .SAXIHP1ARLEN             (saxihp1arlen),
  .SAXIHP1ARLOCK            (saxihp1arlock),
  .SAXIHP1ARPROT            (saxihp1arprot),
  .SAXIHP1ARQOS             (saxihp1arqos),
  .SAXIHP1ARREADY           (SAXIHP1ARREADY),
  .SAXIHP1ARSIZE            (saxihp1arsize),
  .SAXIHP1ARVALID           (saxihp1arvalid),
  .SAXIHP1AWADDR            (saxihp1awaddr),
  .SAXIHP1AWBURST           (saxihp1awburst),
  .SAXIHP1AWCACHE           (saxihp1awcache),
  .SAXIHP1AWID              (saxihp1awid),
  .SAXIHP1AWLEN             (saxihp1awlen),
  .SAXIHP1AWLOCK            (saxihp1awlock),
  .SAXIHP1AWPROT            (saxihp1awprot),
  .SAXIHP1AWQOS             (saxihp1awqos),
  .SAXIHP1AWREADY           (SAXIHP1AWREADY),
  .SAXIHP1AWSIZE            (saxihp1awsize),
  .SAXIHP1AWVALID           (saxihp1awvalid),
  .SAXIHP1BID               (SAXIHP1BID),
  .SAXIHP1BREADY            (saxihp1bready),
  .SAXIHP1BRESP             (SAXIHP1BRESP),
  .SAXIHP1BVALID            (SAXIHP1BVALID),
  .SAXIHP1RACOUNT           (SAXIHP1RACOUNT),
  .SAXIHP1RCOUNT            (SAXIHP1RCOUNT),
  .SAXIHP1RDATA             (SAXIHP1RDATA),
  .SAXIHP1RDISSUECAP1EN     (saxihp1rdissuecap1en),
  .SAXIHP1RID               (SAXIHP1RID),
  .SAXIHP1RLAST             (SAXIHP1RLAST),
  .SAXIHP1RREADY            (saxihp1rready),
  .SAXIHP1RRESP             (SAXIHP1RRESP),
  .SAXIHP1RVALID            (SAXIHP1RVALID),
  .SAXIHP1WACOUNT           (SAXIHP1WACOUNT),
  .SAXIHP1WCOUNT            (SAXIHP1WCOUNT),
  .SAXIHP1WDATA             (saxihp1wdata),
  .SAXIHP1WID               (saxihp1wid),
  .SAXIHP1WLAST             (saxihp1wlast),
  .SAXIHP1WREADY            (SAXIHP1WREADY),
  .SAXIHP1WRISSUECAP1EN     (saxihp1wrissuecap1en),
  .SAXIHP1WSTRB             (saxihp1wstrb),
  .SAXIHP1WVALID            (saxihp1wvalid),
  .SAXIHP2ACLK              (saxihp2aclk),
  .SAXIHP2ARADDR            (saxihp2araddr),
  .SAXIHP2ARBURST           (saxihp2arburst),
  .SAXIHP2ARCACHE           (saxihp2arcache),
  .SAXIHP2ARESETN           (SAXIHP2ARESETN),
  .SAXIHP2ARID              (saxihp2arid),
  .SAXIHP2ARLEN             (saxihp2arlen),
  .SAXIHP2ARLOCK            (saxihp2arlock),
  .SAXIHP2ARPROT            (saxihp2arprot),
  .SAXIHP2ARQOS             (saxihp2arqos),
  .SAXIHP2ARREADY           (SAXIHP2ARREADY),
  .SAXIHP2ARSIZE            (saxihp2arsize),
  .SAXIHP2ARVALID           (saxihp2arvalid),
  .SAXIHP2AWADDR            (saxihp2awaddr),
  .SAXIHP2AWBURST           (saxihp2awburst),
  .SAXIHP2AWCACHE           (saxihp2awcache),
  .SAXIHP2AWID              (saxihp2awid),
  .SAXIHP2AWLEN             (saxihp2awlen),
  .SAXIHP2AWLOCK            (saxihp2awlock),
  .SAXIHP2AWPROT            (saxihp2awprot),
  .SAXIHP2AWQOS             (saxihp2awqos),
  .SAXIHP2AWREADY           (SAXIHP2AWREADY),
  .SAXIHP2AWSIZE            (saxihp2awsize),
  .SAXIHP2AWVALID           (saxihp2awvalid),
  .SAXIHP2BID               (SAXIHP2BID),
  .SAXIHP2BREADY            (saxihp2bready),
  .SAXIHP2BRESP             (SAXIHP2BRESP),
  .SAXIHP2BVALID            (SAXIHP2BVALID),
  .SAXIHP2RACOUNT           (SAXIHP2RACOUNT),
  .SAXIHP2RCOUNT            (SAXIHP2RCOUNT),
  .SAXIHP2RDATA             (SAXIHP2RDATA),
  .SAXIHP2RDISSUECAP1EN     (saxihp2rdissuecap1en),
  .SAXIHP2RID               (SAXIHP2RID),
  .SAXIHP2RLAST             (SAXIHP2RLAST),
  .SAXIHP2RREADY            (saxihp2rready),
  .SAXIHP2RRESP             (SAXIHP2RRESP),
  .SAXIHP2RVALID            (SAXIHP2RVALID),
  .SAXIHP2WACOUNT           (SAXIHP2WACOUNT),
  .SAXIHP2WCOUNT            (SAXIHP2WCOUNT),
  .SAXIHP2WDATA             (saxihp2wdata),
  .SAXIHP2WID               (saxihp2wid),
  .SAXIHP2WLAST             (saxihp2wlast),
  .SAXIHP2WREADY            (SAXIHP2WREADY),
  .SAXIHP2WRISSUECAP1EN     (saxihp2wrissuecap1en),
  .SAXIHP2WSTRB             (saxihp2wstrb),
  .SAXIHP2WVALID            (saxihp2wvalid),
  .SAXIHP3ACLK              (saxihp3aclk),
  .SAXIHP3ARADDR            (saxihp3araddr),
  .SAXIHP3ARBURST           (saxihp3arburst),
  .SAXIHP3ARCACHE           (saxihp3arcache),
  .SAXIHP3ARESETN           (SAXIHP3ARESETN),
  .SAXIHP3ARID              (saxihp3arid),
  .SAXIHP3ARLEN             (saxihp3arlen),
  .SAXIHP3ARLOCK            (saxihp3arlock),
  .SAXIHP3ARPROT            (saxihp3arprot),
  .SAXIHP3ARQOS             (saxihp3arqos),
  .SAXIHP3ARREADY           (SAXIHP3ARREADY),
  .SAXIHP3ARSIZE            (saxihp3arsize),
  .SAXIHP3ARVALID           (saxihp3arvalid),
  .SAXIHP3AWADDR            (saxihp3awaddr),
  .SAXIHP3AWBURST           (saxihp3awburst),
  .SAXIHP3AWCACHE           (saxihp3awcache),
  .SAXIHP3AWID              (saxihp3awid),
  .SAXIHP3AWLEN             (saxihp3awlen),
  .SAXIHP3AWLOCK            (saxihp3awlock),
  .SAXIHP3AWPROT            (saxihp3awprot),
  .SAXIHP3AWQOS             (saxihp3awqos),
  .SAXIHP3AWREADY           (SAXIHP3AWREADY),
  .SAXIHP3AWSIZE            (saxihp3awsize),
  .SAXIHP3AWVALID           (saxihp3awvalid),
  .SAXIHP3BID               (SAXIHP3BID),
  .SAXIHP3BREADY            (saxihp3bready),
  .SAXIHP3BRESP             (SAXIHP3BRESP),
  .SAXIHP3BVALID            (SAXIHP3BVALID),
  .SAXIHP3RACOUNT           (SAXIHP3RACOUNT),
  .SAXIHP3RCOUNT            (SAXIHP3RCOUNT),
  .SAXIHP3RDATA             (SAXIHP3RDATA),
  .SAXIHP3RDISSUECAP1EN     (saxihp3rdissuecap1en),
  .SAXIHP3RID               (SAXIHP3RID),
  .SAXIHP3RLAST             (SAXIHP3RLAST),
  .SAXIHP3RREADY            (saxihp3rready),
  .SAXIHP3RRESP             (SAXIHP3RRESP),
  .SAXIHP3RVALID            (SAXIHP3RVALID),
  .SAXIHP3WACOUNT           (SAXIHP3WACOUNT),
  .SAXIHP3WCOUNT            (SAXIHP3WCOUNT),
  .SAXIHP3WDATA             (saxihp3wdata),
  .SAXIHP3WID               (saxihp3wid),
  .SAXIHP3WLAST             (saxihp3wlast),
  .SAXIHP3WREADY            (SAXIHP3WREADY),
  .SAXIHP3WRISSUECAP1EN     (saxihp3wrissuecap1en),
  .SAXIHP3WSTRB             (saxihp3wstrb),
  .SAXIHP3WVALID            (saxihp3wvalid)
  );

endmodule

module CARRY4_FIX(output O0, O1, O2, O3, CO0, CO1, CO2, CO3, input CYINIT, CIN, DI0, DI1, DI2, DI3, S0, S1, S2, S3);
  parameter CYINIT_AX = 1'b0;
  parameter CYINIT_C0 = 1'b0;
  parameter CYINIT_C1 = 1'b0;

  if(CYINIT_AX) begin
    CARRY4_VPR #(
        .CYINIT_AX(1'b1),
        .CYINIT_C0(1'b0),
        .CYINIT_C1(1'b0)
    ) _TECHMAP_REPLACE_ (
        .CO0(CO0),
        .CO1(CO1),
        .CO2(CO2),
        .CO3(CO3),
        .CYINIT(CYINIT),
        .O0(O0),
        .O1(O1),
        .O2(O2),
        .O3(O3),
        .DI0(DI0),
        .DI1(DI1),
        .DI2(DI2),
        .DI3(DI3),
        .S0(S0),
        .S1(S1),
        .S2(S2),
        .S3(S3)
    );
  end else if(CYINIT_C0 || CYINIT_C1) begin
    CARRY4_VPR #(
        .CYINIT_AX(1'b0),
        .CYINIT_C0(CYINIT_C0),
        .CYINIT_C1(CYINIT_C1)
    ) _TECHMAP_REPLACE_ (
        .CO0(CO0),
        .CO1(CO1),
        .CO2(CO2),
        .CO3(CO3),
        .O0(O0),
        .O1(O1),
        .O2(O2),
        .O3(O3),
        .DI0(DI0),
        .DI1(DI1),
        .DI2(DI2),
        .DI3(DI3),
        .S0(S0),
        .S1(S1),
        .S2(S2),
        .S3(S3)
    );
  end else begin
    CARRY4_VPR #(
        .CYINIT_AX(1'b0),
        .CYINIT_C0(1'b0),
        .CYINIT_C1(1'b0)
    ) _TECHMAP_REPLACE_ (
        .CO0(CO0),
        .CO1(CO1),
        .CO2(CO2),
        .CO3(CO3),
        .O0(O0),
        .O1(O1),
        .O2(O2),
        .O3(O3),
        .DI0(DI0),
        .DI1(DI1),
        .DI2(DI2),
        .DI3(DI3),
        .S0(S0),
        .S1(S1),
        .S2(S2),
        .S3(S3),
        .CIN(CIN)
    );
  end
endmodule

module IBUFDS_GTE2 (
  output O,
  output ODIV2,
  input CEB,
  input I,
  input IB
  );

  parameter CLKCM_CFG = "TRUE";
  parameter CLKRCV_TRST = "TRUE";
  parameter [1:0] CLKSWING_CFG = 2'b11;
  parameter IO_LOC_PAIRS = "NONE";

  wire ipad_p_O, ipad_n_O;

  IPAD_GTP_VPR IPAD_P (
    .I(I),
    .O(ipad_p_O)
  );

  IPAD_GTP_VPR IPAD_N (
    .I(IB),
    .O(ipad_n_O)
  );

  IBUFDS_GTE2_VPR #(
    .CLKCM_CFG(CLKCM_CFG == "TRUE"),
    .CLKRCV_TRST(CLKRCV_TRST == "TRUE"),
    .CLKSWING_CFG(CLKSWING_CFG),
    .IO_LOC_PAIRS(IO_LOC_PAIRS)
  ) IBUFDS_GTE2_INST (
    .O(O),
    .ODIV2(ODIV2),
    .CEB(CEB),
    .I(ipad_p_O),
    .IB(ipad_n_O)
  );

endmodule

module GTPE2_COMMON (
  output DRPRDY,
  output PLL0FBCLKLOST,
  output PLL0LOCK,
  output PLL0OUTCLK,
  output PLL0OUTREFCLK,
  output PLL0REFCLKLOST,
  output PLL1FBCLKLOST,
  output PLL1LOCK,
  output PLL1OUTCLK,
  output PLL1OUTREFCLK,
  output PLL1REFCLKLOST,
  output REFCLKOUTMONITOR0,
  output REFCLKOUTMONITOR1,
  output [15:0] DRPDO,
  output [15:0] PMARSVDOUT,
  output [7:0] DMONITOROUT,
  input BGBYPASSB,
  input BGMONITORENB,
  input BGPDB,
  input BGRCALOVRDENB,
  input DRPCLK,
  input DRPEN,
  input DRPWE,
  input GTREFCLK0,
  input GTREFCLK1,
  input GTGREFCLK0,
  input GTGREFCLK1,
  input PLL0LOCKDETCLK,
  input PLL0LOCKEN,
  input PLL0PD,
  input PLL0RESET,
  input PLL1LOCKDETCLK,
  input PLL1LOCKEN,
  input PLL1PD,
  input PLL1RESET,
  input RCALENB,
  input [15:0] DRPDI,
  input [2:0] PLL0REFCLKSEL,
  input [2:0] PLL1REFCLKSEL,
  input [4:0] BGRCALOVRD,
  input [7:0] DRPADDR,
  input [7:0] PMARSVD
);
  parameter [63:0] BIAS_CFG = 64'h0000000000000000;
  parameter [31:0] COMMON_CFG = 32'h00000000;
  parameter [26:0] PLL0_CFG = 27'h01F03DC;
  parameter [0:0] PLL0_DMON_CFG = 1'b0;
  parameter [23:0] PLL0_INIT_CFG = 24'h00001E;
  parameter [8:0] PLL0_LOCK_CFG = 9'h1E8;
  parameter [26:0] PLL1_CFG = 27'h01F03DC;
  parameter [0:0] PLL1_DMON_CFG = 1'b0;
  parameter [23:0] PLL1_INIT_CFG = 24'h00001E;
  parameter [8:0] PLL1_LOCK_CFG = 9'h1E8;
  parameter [7:0] PLL_CLKOUT_CFG = 8'b00000000;
  parameter [15:0] RSVD_ATTR0 = 16'h0000;
  parameter [15:0] RSVD_ATTR1 = 16'h0000;

  parameter integer PLL0_REFCLK_DIV = 1;
  parameter integer PLL0_FBDIV = 4;
  parameter integer PLL0_FBDIV_45 = 5;
  parameter integer PLL1_REFCLK_DIV = 1;
  parameter integer PLL1_FBDIV = 4;
  parameter integer PLL1_FBDIV_45 = 5;

  localparam [4:0] PLL0_REFCLK_DIV_BIN = PLL0_REFCLK_DIV == 1 ? 5'b10000 : 5'b00000;
  localparam [4:0] PLL1_REFCLK_DIV_BIN = PLL1_REFCLK_DIV == 1 ? 5'b10000 : 5'b00000;

  localparam [5:0] PLL0_FBDIV_BIN = PLL0_FBDIV == 1 ? 6'b010000 :
                                    PLL0_FBDIV == 2 ? 6'b000000 :
                                    PLL0_FBDIV == 3 ? 6'b000001 :
                                    PLL0_FBDIV == 4 ? 6'b000010 :
                                  /*PLL0_FBDIV == 5*/ 6'b000011;
  localparam [5:0] PLL1_FBDIV_BIN = PLL1_FBDIV == 1 ? 6'b010000 :
                                    PLL1_FBDIV == 2 ? 6'b000000 :
                                    PLL1_FBDIV == 3 ? 6'b000001 :
                                    PLL1_FBDIV == 4 ? 6'b000010 :
                                  /*PLL1_FBDIV == 5*/ 6'b000011;

  localparam PLL0_FBDIV_45_BIN = PLL0_FBDIV_45 == 4 ? 1'b0 : 1'b1;
  localparam PLL1_FBDIV_45_BIN = PLL1_FBDIV_45 == 4 ? 1'b0 : 1'b1;

  parameter [0:0] IS_DRPCLK_INVERTED = 1'b0;
  parameter [0:0] IS_PLL0LOCKDETCLK_INVERTED = 1'b0;
  parameter [0:0] IS_PLL1LOCKDETCLK_INVERTED = 1'b0;

  parameter _TECHMAP_CONSTMSK_DRPCLK_         = 0;
  parameter _TECHMAP_CONSTVAL_DRPCLK_         = 0;
  parameter _TECHMAP_CONSTMSK_PLL0LOCKDETCLK_ = 0;
  parameter _TECHMAP_CONSTVAL_PLL0LOCKDETCLK_ = 0;
  parameter _TECHMAP_CONSTMSK_PLL1LOCKDETCLK_ = 0;
  parameter _TECHMAP_CONSTVAL_PLL1LOCKDETCLK_ = 0;

  localparam [0:0] INV_DRPCLK = (_TECHMAP_CONSTMSK_DRPCLK_ == 1) ? !_TECHMAP_CONSTVAL_DRPCLK_ ^ IS_DRPCLK_INVERTED :
                                (_TECHMAP_CONSTVAL_DRPCLK_ == 0) ? ~IS_DRPCLK_INVERTED : IS_DRPCLK_INVERTED;

  wire drpclk = (_TECHMAP_CONSTMSK_DRPCLK_ == 1) ? 1'b1 :
                (_TECHMAP_CONSTVAL_DRPCLK_ == 0) ? 1'b1 : DRPCLK;

  localparam [0:0] INV_PLL0LOCKDETCLK = (_TECHMAP_CONSTMSK_PLL0LOCKDETCLK_ == 1) ? !_TECHMAP_CONSTVAL_PLL0LOCKDETCLK_ ^ IS_PLL0LOCKDETCLK_INVERTED :
                                        (_TECHMAP_CONSTVAL_PLL0LOCKDETCLK_ == 0) ? ~IS_PLL0LOCKDETCLK_INVERTED : IS_PLL0LOCKDETCLK_INVERTED;

  wire pll0lockdetclk = (_TECHMAP_CONSTMSK_PLL0LOCKDETCLK_ == 1) ? 1'b1 :
                        (_TECHMAP_CONSTVAL_PLL0LOCKDETCLK_ == 0) ? 1'b1 : PLL0LOCKDETCLK;

  localparam [0:0] INV_PLL1LOCKDETCLK = (_TECHMAP_CONSTMSK_PLL1LOCKDETCLK_ == 1) ? !_TECHMAP_CONSTVAL_PLL1LOCKDETCLK_ ^ IS_PLL1LOCKDETCLK_INVERTED :
                                        (_TECHMAP_CONSTVAL_PLL1LOCKDETCLK_ == 0) ? ~IS_PLL1LOCKDETCLK_INVERTED : IS_PLL1LOCKDETCLK_INVERTED;

  wire pll1lockdetclk = (_TECHMAP_CONSTMSK_PLL1LOCKDETCLK_ == 1) ? 1'b1 :
                        (_TECHMAP_CONSTVAL_PLL1LOCKDETCLK_ == 0) ? 1'b1 : PLL1LOCKDETCLK;

  parameter _TECHMAP_CONSTMSK_GTREFCLK0_ = 0;
  parameter _TECHMAP_CONSTVAL_GTREFCLK0_ = 0;
  parameter _TECHMAP_CONSTMSK_GTREFCLK1_ = 0;
  parameter _TECHMAP_CONSTVAL_GTREFCLK1_ = 0;

  localparam [0:0] GTREFCLK0_USED = (_TECHMAP_CONSTMSK_GTREFCLK0_ == 1)  ? 1'b0 :
                                    (_TECHMAP_CONSTVAL_GTREFCLK0_ === 0) ? 1'b0 : 1'b1;
  localparam [0:0] GTREFCLK1_USED = (_TECHMAP_CONSTMSK_GTREFCLK1_ == 1)  ? 1'b0 :
                                    (_TECHMAP_CONSTVAL_GTREFCLK1_ === 0) ? 1'b0 : 1'b1;
  localparam [0:0] BOTH_GTREFCLK_USED = GTREFCLK0_USED && GTREFCLK1_USED;
  localparam [0:0] NONE_GTREFCLK_USED = !(GTREFCLK0_USED || GTREFCLK1_USED);

  if (NONE_GTREFCLK_USED) begin
    wire _TECHMAP_FAIL_ = 1'b1;
  end

  if (BOTH_GTREFCLK_USED) begin
      GTPE2_COMMON_VPR #(
        .BIAS_CFG                   (BIAS_CFG),
        .COMMON_CFG                 (COMMON_CFG),
        .PLL0_CFG                   (PLL0_CFG),
        .PLL0_DMON_CFG              (PLL0_DMON_CFG),
        .PLL0_FBDIV                 (PLL0_FBDIV_BIN),
        .PLL0_FBDIV_45              (PLL0_FBDIV_45_BIN),
        .PLL0_INIT_CFG              (PLL0_INIT_CFG),
        .PLL0_LOCK_CFG              (PLL0_LOCK_CFG),
        .PLL0_REFCLK_DIV            (PLL0_REFCLK_DIV_BIN),
        .PLL1_CFG                   (PLL1_CFG),
        .PLL1_DMON_CFG              (PLL1_DMON_CFG),
        .PLL1_FBDIV                 (PLL1_FBDIV_BIN),
        .PLL1_FBDIV_45              (PLL1_FBDIV_45_BIN),
        .PLL1_INIT_CFG              (PLL1_INIT_CFG),
        .PLL1_LOCK_CFG              (PLL1_LOCK_CFG),
        .PLL1_REFCLK_DIV            (PLL1_REFCLK_DIV_BIN),
        .PLL_CLKOUT_CFG             (PLL_CLKOUT_CFG),
        .RSVD_ATTR0                 (RSVD_ATTR0),
        .RSVD_ATTR1                 (RSVD_ATTR1),
        .INV_DRPCLK                 (INV_DRPCLK),
        .INV_PLL0LOCKDETCLK         (INV_PLL0LOCKDETCLK),
        .INV_PLL1LOCKDETCLK         (INV_PLL1LOCKDETCLK),
        .GTREFCLK0_USED             (GTREFCLK0_USED == 1'b1),
        .GTREFCLK1_USED             (GTREFCLK1_USED == 1'b1),
        .BOTH_GTREFCLK_USED         (BOTH_GTREFCLK_USED),
        .ENABLE_DRP                 (1'b1),
        .IBUFDS_GTE2_CLKSWING_CFG   (2'b11)
      ) _TECHMAP_REPLACE_ (
        .DRPRDY             (DRPRDY),
        .PLL0FBCLKLOST      (PLL0FBCLKLOST),
        .PLL0LOCK           (PLL0LOCK),
        .PLL0OUTCLK         (PLL0OUTCLK),
        .PLL0OUTREFCLK      (PLL0OUTREFCLK),
        .PLL0REFCLKLOST     (PLL0REFCLKLOST),
        .PLL1FBCLKLOST      (PLL1FBCLKLOST),
        .PLL1LOCK           (PLL1LOCK),
        .PLL1OUTCLK         (PLL1OUTCLK),
        .PLL1OUTREFCLK      (PLL1OUTREFCLK),
        .PLL1REFCLKLOST     (PLL1REFCLKLOST),
        .REFCLKOUTMONITOR0  (REFCLKOUTMONITOR0),
        .REFCLKOUTMONITOR1  (REFCLKOUTMONITOR1),
        .DRPDO              (DRPDO),
        .PMARSVDOUT         (PMARSVDOUT),
        .DMONITOROUT        (DMONITOROUT),
        .BGBYPASSB          (BGBYPASSB),
        .BGMONITORENB       (BGMONITORENB),
        .BGPDB              (BGPDB),
        .BGRCALOVRDENB      (BGRCALOVRDENB),
        .DRPCLK             (drpclk),
        .DRPEN              (DRPEN),
        .DRPWE              (DRPWE),
        .GTREFCLK0          (GTREFCLK0),
        .GTREFCLK1          (GTREFCLK1),
        .PLL0LOCKDETCLK     (pll0lockdetclk),
        .PLL0LOCKEN         (PLL0LOCKEN),
        .PLL0PD             (PLL0PD),
        .PLL0RESET          (PLL0RESET),
        .PLL1LOCKDETCLK     (pll1lockdetclk),
        .PLL1LOCKEN         (PLL1LOCKEN),
        .PLL1PD             (PLL1PD),
        .PLL1RESET          (PLL1RESET),
        .RCALENB            (RCALENB),
        .DRPDI              (DRPDI),
        .PLL0REFCLKSEL      (PLL0REFCLKSEL),
        .PLL1REFCLKSEL      (PLL1REFCLKSEL),
        .BGRCALOVRD         (BGRCALOVRD),
        .DRPADDR            (DRPADDR),
        .PMARSVD            (PMARSVD)
      );
  end else if (GTREFCLK0_USED) begin
      GTPE2_COMMON_VPR #(
        .BIAS_CFG                   (BIAS_CFG),
        .COMMON_CFG                 (COMMON_CFG),
        .PLL0_CFG                   (PLL0_CFG),
        .PLL0_DMON_CFG              (PLL0_DMON_CFG),
        .PLL0_FBDIV                 (PLL0_FBDIV_BIN),
        .PLL0_FBDIV_45              (PLL0_FBDIV_45_BIN),
        .PLL0_INIT_CFG              (PLL0_INIT_CFG),
        .PLL0_LOCK_CFG              (PLL0_LOCK_CFG),
        .PLL0_REFCLK_DIV            (PLL0_REFCLK_DIV_BIN),
        .PLL1_CFG                   (PLL1_CFG),
        .PLL1_DMON_CFG              (PLL1_DMON_CFG),
        .PLL1_FBDIV                 (PLL1_FBDIV_BIN),
        .PLL1_FBDIV_45              (PLL1_FBDIV_45_BIN),
        .PLL1_INIT_CFG              (PLL1_INIT_CFG),
        .PLL1_LOCK_CFG              (PLL1_LOCK_CFG),
        .PLL1_REFCLK_DIV            (PLL1_REFCLK_DIV_BIN),
        .PLL_CLKOUT_CFG             (PLL_CLKOUT_CFG),
        .RSVD_ATTR0                 (RSVD_ATTR0),
        .RSVD_ATTR1                 (RSVD_ATTR1),
        .INV_DRPCLK                 (INV_DRPCLK),
        .INV_PLL0LOCKDETCLK         (INV_PLL0LOCKDETCLK),
        .INV_PLL1LOCKDETCLK         (INV_PLL1LOCKDETCLK),
        .GTREFCLK0_USED             (GTREFCLK0_USED == 1'b1),
        .GTREFCLK1_USED             (GTREFCLK1_USED == 1'b1),
        .BOTH_GTREFCLK_USED         (BOTH_GTREFCLK_USED),
        .ENABLE_DRP                 (1'b1),
        .IBUFDS_GTE2_CLKSWING_CFG   (2'b11)
      ) _TECHMAP_REPLACE_ (
        .DRPRDY             (DRPRDY),
        .PLL0FBCLKLOST      (PLL0FBCLKLOST),
        .PLL0LOCK           (PLL0LOCK),
        .PLL0OUTCLK         (PLL0OUTCLK),
        .PLL0OUTREFCLK      (PLL0OUTREFCLK),
        .PLL0REFCLKLOST     (PLL0REFCLKLOST),
        .PLL1FBCLKLOST      (PLL1FBCLKLOST),
        .PLL1LOCK           (PLL1LOCK),
        .PLL1OUTCLK         (PLL1OUTCLK),
        .PLL1OUTREFCLK      (PLL1OUTREFCLK),
        .PLL1REFCLKLOST     (PLL1REFCLKLOST),
        .REFCLKOUTMONITOR0  (REFCLKOUTMONITOR0),
        .REFCLKOUTMONITOR1  (REFCLKOUTMONITOR1),
        .DRPDO              (DRPDO),
        .PMARSVDOUT         (PMARSVDOUT),
        .DMONITOROUT        (DMONITOROUT),
        .BGBYPASSB          (BGBYPASSB),
        .BGMONITORENB       (BGMONITORENB),
        .BGPDB              (BGPDB),
        .BGRCALOVRDENB      (BGRCALOVRDENB),
        .DRPCLK             (drpclk),
        .DRPEN              (DRPEN),
        .DRPWE              (DRPWE),
        .GTREFCLK0          (GTREFCLK0),
        .PLL0LOCKDETCLK     (pll0lockdetclk),
        .PLL0LOCKEN         (PLL0LOCKEN),
        .PLL0PD             (PLL0PD),
        .PLL0RESET          (PLL0RESET),
        .PLL1LOCKDETCLK     (pll1lockdetclk),
        .PLL1LOCKEN         (PLL1LOCKEN),
        .PLL1PD             (PLL1PD),
        .PLL1RESET          (PLL1RESET),
        .RCALENB            (RCALENB),
        .DRPDI              (DRPDI),
        .PLL0REFCLKSEL      (PLL0REFCLKSEL),
        .PLL1REFCLKSEL      (PLL1REFCLKSEL),
        .BGRCALOVRD         (BGRCALOVRD),
        .DRPADDR            (DRPADDR),
        .PMARSVD            (PMARSVD)
      );
  end else begin
      GTPE2_COMMON_VPR #(
        .BIAS_CFG                   (BIAS_CFG),
        .COMMON_CFG                 (COMMON_CFG),
        .PLL0_CFG                   (PLL0_CFG),
        .PLL0_DMON_CFG              (PLL0_DMON_CFG),
        .PLL0_FBDIV                 (PLL0_FBDIV_BIN),
        .PLL0_FBDIV_45              (PLL0_FBDIV_45_BIN),
        .PLL0_INIT_CFG              (PLL0_INIT_CFG),
        .PLL0_LOCK_CFG              (PLL0_LOCK_CFG),
        .PLL0_REFCLK_DIV            (PLL0_REFCLK_DIV_BIN),
        .PLL1_CFG                   (PLL1_CFG),
        .PLL1_DMON_CFG              (PLL1_DMON_CFG),
        .PLL1_FBDIV                 (PLL1_FBDIV_BIN),
        .PLL1_FBDIV_45              (PLL1_FBDIV_45_BIN),
        .PLL1_INIT_CFG              (PLL1_INIT_CFG),
        .PLL1_LOCK_CFG              (PLL1_LOCK_CFG),
        .PLL1_REFCLK_DIV            (PLL1_REFCLK_DIV_BIN),
        .PLL_CLKOUT_CFG             (PLL_CLKOUT_CFG),
        .RSVD_ATTR0                 (RSVD_ATTR0),
        .RSVD_ATTR1                 (RSVD_ATTR1),
        .INV_DRPCLK                 (INV_DRPCLK),
        .INV_PLL0LOCKDETCLK         (INV_PLL0LOCKDETCLK),
        .INV_PLL1LOCKDETCLK         (INV_PLL1LOCKDETCLK),
        .GTREFCLK0_USED             (GTREFCLK0_USED == 1'b1),
        .GTREFCLK1_USED             (GTREFCLK1_USED == 1'b1),
        .BOTH_GTREFCLK_USED         (BOTH_GTREFCLK_USED),
        .ENABLE_DRP                 (1'b1),
        .IBUFDS_GTE2_CLKSWING_CFG   (2'b11)
      ) _TECHMAP_REPLACE_ (
        .DRPRDY             (DRPRDY),
        .PLL0FBCLKLOST      (PLL0FBCLKLOST),
        .PLL0LOCK           (PLL0LOCK),
        .PLL0OUTCLK         (PLL0OUTCLK),
        .PLL0OUTREFCLK      (PLL0OUTREFCLK),
        .PLL0REFCLKLOST     (PLL0REFCLKLOST),
        .PLL1FBCLKLOST      (PLL1FBCLKLOST),
        .PLL1LOCK           (PLL1LOCK),
        .PLL1OUTCLK         (PLL1OUTCLK),
        .PLL1OUTREFCLK      (PLL1OUTREFCLK),
        .PLL1REFCLKLOST     (PLL1REFCLKLOST),
        .REFCLKOUTMONITOR0  (REFCLKOUTMONITOR0),
        .REFCLKOUTMONITOR1  (REFCLKOUTMONITOR1),
        .DRPDO              (DRPDO),
        .PMARSVDOUT         (PMARSVDOUT),
        .DMONITOROUT        (DMONITOROUT),
        .BGBYPASSB          (BGBYPASSB),
        .BGMONITORENB       (BGMONITORENB),
        .BGPDB              (BGPDB),
        .BGRCALOVRDENB      (BGRCALOVRDENB),
        .DRPCLK             (drpclk),
        .DRPEN              (DRPEN),
        .DRPWE              (DRPWE),
        .GTREFCLK1          (GTREFCLK1),
        .PLL0LOCKDETCLK     (pll0lockdetclk),
        .PLL0LOCKEN         (PLL0LOCKEN),
        .PLL0PD             (PLL0PD),
        .PLL0RESET          (PLL0RESET),
        .PLL1LOCKDETCLK     (pll1lockdetclk),
        .PLL1LOCKEN         (PLL1LOCKEN),
        .PLL1PD             (PLL1PD),
        .PLL1RESET          (PLL1RESET),
        .RCALENB            (RCALENB),
        .DRPDI              (DRPDI),
        .PLL0REFCLKSEL      (PLL0REFCLKSEL),
        .PLL1REFCLKSEL      (PLL1REFCLKSEL),
        .BGRCALOVRD         (BGRCALOVRD),
        .DRPADDR            (DRPADDR),
        .PMARSVD            (PMARSVD)
      );
  end
endmodule

module GTPE2_CHANNEL (
  output DRPRDY,
  output EYESCANDATAERROR,
  output GTPTXN,
  output GTPTXP,
  output PHYSTATUS,
  output PMARSVDOUT0,
  output PMARSVDOUT1,
  output RXBYTEISALIGNED,
  output RXBYTEREALIGN,
  output RXCDRLOCK,
  output RXCHANBONDSEQ,
  output RXCHANISALIGNED,
  output RXCHANREALIGN,
  output RXCOMINITDET,
  output RXCOMMADET,
  output RXCOMSASDET,
  output RXCOMWAKEDET,
  output RXDLYSRESETDONE,
  output RXELECIDLE,
  output RXHEADERVALID,
  output RXOSINTDONE,
  output RXOSINTSTARTED,
  output RXOSINTSTROBEDONE,
  output RXOSINTSTROBESTARTED,
  output RXOUTCLK,
  output RXOUTCLKFABRIC,
  output RXOUTCLKPCS,
  output RXPHALIGNDONE,
  output RXPMARESETDONE,
  output RXPRBSERR,
  output RXRATEDONE,
  output RXRESETDONE,
  output RXSYNCDONE,
  output RXSYNCOUT,
  output RXVALID,
  output TXCOMFINISH,
  output TXDLYSRESETDONE,
  output TXGEARBOXREADY,
  output TXOUTCLK,
  output TXOUTCLKFABRIC,
  output TXOUTCLKPCS,
  output TXPHALIGNDONE,
  output TXPHINITDONE,
  output TXPMARESETDONE,
  output TXRATEDONE,
  output TXRESETDONE,
  output TXSYNCDONE,
  output TXSYNCOUT,
  output [14:0] DMONITOROUT,
  output [15:0] DRPDO,
  output [15:0] PCSRSVDOUT,
  output [1:0] RXCLKCORCNT,
  output [1:0] RXDATAVALID,
  output [1:0] RXSTARTOFSEQ,
  output [1:0] TXBUFSTATUS,
  output [2:0] RXBUFSTATUS,
  output [2:0] RXHEADER,
  output [2:0] RXSTATUS,
  output [31:0] RXDATA,
  output [3:0] RXCHARISCOMMA,
  output [3:0] RXCHARISK,
  output [3:0] RXCHBONDO,
  output [3:0] RXDISPERR,
  output [3:0] RXNOTINTABLE,
  output [4:0] RXPHMONITOR,
  output [4:0] RXPHSLIPMONITOR,
  input CFGRESET,
  input CLKRSVD0,
  input CLKRSVD1,
  input DMONFIFORESET,
  input DMONITORCLK,
  input DRPCLK,
  input DRPEN,
  input DRPWE,
  input EYESCANMODE,
  input EYESCANRESET,
  input EYESCANTRIGGER,
  input GTPRXN,
  input GTPRXP,
  input GTRESETSEL,
  input GTRXRESET,
  input GTTXRESET,
  input PLL0CLK,
  input PLL0REFCLK,
  input PLL1CLK,
  input PLL1REFCLK,
  input PMARSVDIN0,
  input PMARSVDIN1,
  input PMARSVDIN2,
  input PMARSVDIN3,
  input PMARSVDIN4,
  input RESETOVRD,
  input RX8B10BEN,
  input RXBUFRESET,
  input RXCDRFREQRESET,
  input RXCDRHOLD,
  input RXCDROVRDEN,
  input RXCDRRESET,
  input RXCDRRESETRSV,
  input RXCHBONDEN,
  input RXCHBONDMASTER,
  input RXCHBONDSLAVE,
  input RXCOMMADETEN,
  input RXDDIEN,
  input RXDFEXYDEN,
  input RXDLYBYPASS,
  input RXDLYEN,
  input RXDLYOVRDEN,
  input RXDLYSRESET,
  input RXGEARBOXSLIP,
  input RXLPMHFHOLD,
  input RXLPMHFOVRDEN,
  input RXLPMLFHOLD,
  input RXLPMLFOVRDEN,
  input RXLPMOSINTNTRLEN,
  input RXLPMRESET,
  input RXMCOMMAALIGNEN,
  input RXOOBRESET,
  input RXOSCALRESET,
  input RXOSHOLD,
  input RXOSINTEN,
  input RXOSINTHOLD,
  input RXOSINTNTRLEN,
  input RXOSINTOVRDEN,
  input RXOSINTPD,
  input RXOSINTSTROBE,
  input RXOSINTTESTOVRDEN,
  input RXOSOVRDEN,
  input RXPCOMMAALIGNEN,
  input RXPCSRESET,
  input RXPHALIGN,
  input RXPHALIGNEN,
  input RXPHDLYPD,
  input RXPHDLYRESET,
  input RXPHOVRDEN,
  input RXPMARESET,
  input RXPOLARITY,
  input RXPRBSCNTRESET,
  input RXRATEMODE,
  input RXSLIDE,
  input RXSYNCALLIN,
  input RXSYNCIN,
  input RXSYNCMODE,
  input RXUSERRDY,
  input RXUSRCLK2,
  input RXUSRCLK,
  input SETERRSTATUS,
  input SIGVALIDCLK,
  input TX8B10BEN,
  input TXCOMINIT,
  input TXCOMSAS,
  input TXCOMWAKE,
  input TXDEEMPH,
  input TXDETECTRX,
  input TXDIFFPD,
  input TXDLYBYPASS,
  input TXDLYEN,
  input TXDLYHOLD,
  input TXDLYOVRDEN,
  input TXDLYSRESET,
  input TXDLYUPDOWN,
  input TXELECIDLE,
  input TXINHIBIT,
  input TXPCSRESET,
  input TXPDELECIDLEMODE,
  input TXPHALIGN,
  input TXPHALIGNEN,
  input TXPHDLYPD,
  input TXPHDLYRESET,
  input TXPHDLYTSTCLK,
  input TXPHINIT,
  input TXPHOVRDEN,
  input TXPIPPMEN,
  input TXPIPPMOVRDEN,
  input TXPIPPMPD,
  input TXPIPPMSEL,
  input TXPISOPD,
  input TXPMARESET,
  input TXPOLARITY,
  input TXPOSTCURSORINV,
  input TXPRBSFORCEERR,
  input TXPRECURSORINV,
  input TXRATEMODE,
  input TXSTARTSEQ,
  input TXSWING,
  input TXSYNCALLIN,
  input TXSYNCIN,
  input TXSYNCMODE,
  input TXUSERRDY,
  input TXUSRCLK2,
  input TXUSRCLK,
  input [13:0] RXADAPTSELTEST,
  input [15:0] DRPDI,
  input [15:0] GTRSVD,
  input [15:0] PCSRSVDIN,
  input [19:0] TSTIN,
  input [1:0] RXELECIDLEMODE,
  input [1:0] RXPD,
  input [1:0] RXSYSCLKSEL,
  input [1:0] TXPD,
  input [1:0] TXSYSCLKSEL,
  input [2:0] LOOPBACK,
  input [2:0] RXCHBONDLEVEL,
  input [2:0] RXOUTCLKSEL,
  input [2:0] RXPRBSSEL,
  input [2:0] RXRATE,
  input [2:0] TXBUFDIFFCTRL,
  input [2:0] TXHEADER,
  input [2:0] TXMARGIN,
  input [2:0] TXOUTCLKSEL,
  input [2:0] TXPRBSSEL,
  input [2:0] TXRATE,
  input [31:0] TXDATA,
  input [3:0] RXCHBONDI,
  input [3:0] RXOSINTCFG,
  input [3:0] RXOSINTID0,
  input [3:0] TX8B10BBYPASS,
  input [3:0] TXCHARDISPMODE,
  input [3:0] TXCHARDISPVAL,
  input [3:0] TXCHARISK,
  input [3:0] TXDIFFCTRL,
  input [4:0] TXPIPPMSTEPSIZE,
  input [4:0] TXPOSTCURSOR,
  input [4:0] TXPRECURSOR,
  input [6:0] TXMAINCURSOR,
  input [6:0] TXSEQUENCE,
  input [8:0] DRPADDR
);
  parameter [0:0] ACJTAG_DEBUG_MODE = 1'b0;
  parameter [0:0] ACJTAG_MODE = 1'b0;
  parameter [0:0] ACJTAG_RESET = 1'b0;
  parameter [19:0] ADAPT_CFG0 = 20'b00000000000000000000;
  parameter ALIGN_COMMA_DOUBLE = "FALSE";
  parameter [9:0] ALIGN_COMMA_ENABLE = 10'b0001111111;
  parameter [1:0] ALIGN_COMMA_WORD = 1;
  parameter ALIGN_MCOMMA_DET = "TRUE";
  parameter [9:0] ALIGN_MCOMMA_VALUE = 10'b1010000011;
  parameter ALIGN_PCOMMA_DET = "TRUE";
  parameter [9:0] ALIGN_PCOMMA_VALUE = 10'b0101111100;
  parameter CBCC_DATA_SOURCE_SEL = "DECODED";
  parameter [42:0] CFOK_CFG = 43'b1001001000000000000000001000000111010000000;
  parameter [6:0] CFOK_CFG2 = 7'b0100000;
  parameter [6:0] CFOK_CFG3 = 7'b0100000;
  parameter [0:0] CFOK_CFG4 = 1'b0;
  parameter [1:0] CFOK_CFG5 = 2'b00;
  parameter [3:0] CFOK_CFG6 = 4'b0000;
  parameter CHAN_BOND_KEEP_ALIGN = "FALSE";
  parameter [3:0] CHAN_BOND_MAX_SKEW = 7;
  parameter [9:0] CHAN_BOND_SEQ_1_1 = 10'b0101111100;
  parameter [9:0] CHAN_BOND_SEQ_1_2 = 10'b0000000000;
  parameter [9:0] CHAN_BOND_SEQ_1_3 = 10'b0000000000;
  parameter [9:0] CHAN_BOND_SEQ_1_4 = 10'b0000000000;
  parameter [3:0] CHAN_BOND_SEQ_1_ENABLE = 4'b1111;
  parameter [9:0] CHAN_BOND_SEQ_2_1 = 10'b0100000000;
  parameter [9:0] CHAN_BOND_SEQ_2_2 = 10'b0100000000;
  parameter [9:0] CHAN_BOND_SEQ_2_3 = 10'b0100000000;
  parameter [9:0] CHAN_BOND_SEQ_2_4 = 10'b0100000000;
  parameter [3:0] CHAN_BOND_SEQ_2_ENABLE = 4'b1111;
  parameter CHAN_BOND_SEQ_2_USE = "FALSE";
  parameter integer CHAN_BOND_SEQ_LEN = 1;
  parameter [0:0] CLK_COMMON_SWING = 1'b0;
  parameter CLK_CORRECT_USE = "TRUE";
  parameter CLK_COR_KEEP_IDLE = "FALSE";
  parameter [5:0] CLK_COR_MAX_LAT = 20;
  parameter [5:0] CLK_COR_MIN_LAT = 18;
  parameter CLK_COR_PRECEDENCE = "TRUE";
  parameter [4:0] CLK_COR_REPEAT_WAIT = 0;
  parameter [9:0] CLK_COR_SEQ_1_1 = 10'b0100011100;
  parameter [9:0] CLK_COR_SEQ_1_2 = 10'b0000000000;
  parameter [9:0] CLK_COR_SEQ_1_3 = 10'b0000000000;
  parameter [9:0] CLK_COR_SEQ_1_4 = 10'b0000000000;
  parameter [3:0] CLK_COR_SEQ_1_ENABLE = 4'b1111;
  parameter [9:0] CLK_COR_SEQ_2_1 = 10'b0100000000;
  parameter [9:0] CLK_COR_SEQ_2_2 = 10'b0100000000;
  parameter [9:0] CLK_COR_SEQ_2_3 = 10'b0100000000;
  parameter [9:0] CLK_COR_SEQ_2_4 = 10'b0100000000;
  parameter [3:0] CLK_COR_SEQ_2_ENABLE = 4'b1111;
  parameter CLK_COR_SEQ_2_USE = "FALSE";
  parameter integer CLK_COR_SEQ_LEN = 1;
  parameter DEC_MCOMMA_DETECT = "TRUE";
  parameter DEC_PCOMMA_DETECT = "TRUE";
  parameter DEC_VALID_COMMA_ONLY = "TRUE";
  parameter [23:0] DMONITOR_CFG = 24'h000A00;
  parameter [0:0] ES_CLK_PHASE_SEL = 1'b0;
  parameter [5:0] ES_CONTROL = 6'b000000;
  parameter ES_ERRDET_EN = "FALSE";
  parameter ES_EYE_SCAN_EN = "FALSE";
  parameter [11:0] ES_HORZ_OFFSET = 12'h010;
  parameter [9:0] ES_PMA_CFG = 10'b0000000000;
  parameter [4:0] ES_PRESCALE = 5'b00000;
  parameter [79:0] ES_QUALIFIER = 80'h00000000000000000000;
  parameter [79:0] ES_QUAL_MASK = 80'h00000000000000000000;
  parameter [79:0] ES_SDATA_MASK = 80'h00000000000000000000;
  parameter [8:0] ES_VERT_OFFSET = 9'b000000000;
  parameter [3:0] FTS_DESKEW_SEQ_ENABLE = 4'b1111;
  parameter [3:0] FTS_LANE_DESKEW_CFG = 4'b1111;
  parameter FTS_LANE_DESKEW_EN = "FALSE";
  parameter [2:0] GEARBOX_MODE = 3'b000;
  parameter [0:0] LOOPBACK_CFG = 1'b0;
  parameter [1:0] OUTREFCLK_SEL_INV = 2'b11;
  parameter PCS_PCIE_EN = "FALSE";
  parameter [47:0] PCS_RSVD_ATTR = 48'h000000000000;
  parameter [11:0] PD_TRANS_TIME_FROM_P2 = 12'h03C;
  parameter [7:0] PD_TRANS_TIME_NONE_P2 = 8'h19;
  parameter [7:0] PD_TRANS_TIME_TO_P2 = 8'h64;
  parameter [0:0] PMA_LOOPBACK_CFG = 1'b0;
  parameter [31:0] PMA_RSV = 32'h00000333;
  parameter [31:0] PMA_RSV2 = 32'h00002050;
  parameter [1:0] PMA_RSV3 = 2'b00;
  parameter [3:0] PMA_RSV4 = 4'b0000;
  parameter [0:0] PMA_RSV5 = 1'b0;
  parameter [0:0] PMA_RSV6 = 1'b0;
  parameter [0:0] PMA_RSV7 = 1'b0;
  parameter [4:0] RXBUFRESET_TIME = 5'b00001;
  parameter RXBUF_ADDR_MODE = "FULL";
  parameter [3:0] RXBUF_EIDLE_HI_CNT = 4'b1000;
  parameter [3:0] RXBUF_EIDLE_LO_CNT = 4'b0000;
  parameter RXBUF_EN = "TRUE";
  parameter RXBUF_RESET_ON_CB_CHANGE = "TRUE";
  parameter RXBUF_RESET_ON_COMMAALIGN = "FALSE";
  parameter RXBUF_RESET_ON_EIDLE = "FALSE";
  parameter RXBUF_RESET_ON_RATE_CHANGE = "TRUE";
  parameter [5:0] RXBUF_THRESH_OVFLW = 61;
  parameter RXBUF_THRESH_OVRD = "FALSE";
  parameter [5:0] RXBUF_THRESH_UNDFLW = 4;
  parameter [4:0] RXCDRFREQRESET_TIME = 5'b00001;
  parameter [4:0] RXCDRPHRESET_TIME = 5'b00001;
  parameter [82:0] RXCDR_CFG = 83'h0000107FE406001041010;
  parameter [0:0] RXCDR_FR_RESET_ON_EIDLE = 1'b0;
  parameter [0:0] RXCDR_HOLD_DURING_EIDLE = 1'b0;
  parameter [5:0] RXCDR_LOCK_CFG = 6'b001001;
  parameter [0:0] RXCDR_PH_RESET_ON_EIDLE = 1'b0;
  parameter [15:0] RXDLY_CFG = 16'h0010;
  parameter [8:0] RXDLY_LCFG = 9'h020;
  parameter [15:0] RXDLY_TAP_CFG = 16'h0000;
  parameter RXGEARBOX_EN = "FALSE";
  parameter [4:0] RXISCANRESET_TIME = 5'b00001;
  parameter [6:0] RXLPMRESET_TIME = 7'b0001111;
  parameter [0:0] RXLPM_BIAS_STARTUP_DISABLE = 1'b0;
  parameter [3:0] RXLPM_CFG = 4'b0110;
  parameter [0:0] RXLPM_CFG1 = 1'b0;
  parameter [0:0] RXLPM_CM_CFG = 1'b0;
  parameter [8:0] RXLPM_GC_CFG = 9'b111100010;
  parameter [2:0] RXLPM_GC_CFG2 = 3'b001;
  parameter [13:0] RXLPM_HF_CFG = 14'b00001111110000;
  parameter [4:0] RXLPM_HF_CFG2 = 5'b01010;
  parameter [3:0] RXLPM_HF_CFG3 = 4'b0000;
  parameter [0:0] RXLPM_HOLD_DURING_EIDLE = 1'b0;
  parameter [0:0] RXLPM_INCM_CFG = 1'b0;
  parameter [0:0] RXLPM_IPCM_CFG = 1'b0;
  parameter [17:0] RXLPM_LF_CFG = 18'b000000001111110000;
  parameter [4:0] RXLPM_LF_CFG2 = 5'b01010;
  parameter [2:0] RXLPM_OSINT_CFG = 3'b100;
  parameter [6:0] RXOOB_CFG = 7'b0000110;
  parameter RXOOB_CLK_CFG = "PMA";
  parameter [4:0] RXOSCALRESET_TIME = 5'b00011;
  parameter [4:0] RXOSCALRESET_TIMEOUT = 5'b00000;
  parameter integer RXOUT_DIV = 2;
  parameter [4:0] RXPCSRESET_TIME = 5'b00001;
  parameter [23:0] RXPHDLY_CFG = 24'h084000;
  parameter [23:0] RXPH_CFG = 24'hC00002;
  parameter [4:0] RXPH_MONITOR_SEL = 5'b00000;
  parameter [2:0] RXPI_CFG0 = 3'b000;
  parameter [0:0] RXPI_CFG1 = 1'b0;
  parameter [0:0] RXPI_CFG2 = 1'b0;
  parameter [4:0] RXPMARESET_TIME = 5'b00011;
  parameter [0:0] RXPRBS_ERR_LOOPBACK = 1'b0;
  parameter [3:0] RXSLIDE_AUTO_WAIT = 7;
  parameter RXSLIDE_MODE = "OFF";
  parameter [0:0] RXSYNC_MULTILANE = 1'b0;
  parameter [0:0] RXSYNC_OVRD = 1'b0;
  parameter [0:0] RXSYNC_SKIP_DA = 1'b0;
  parameter [15:0] RX_BIAS_CFG = 16'b0000111100110011;
  parameter [5:0] RX_BUFFER_CFG = 6'b000000;
  parameter integer RX_CLK25_DIV = 7;
  parameter [0:0] RX_CLKMUX_EN = 1'b1;
  parameter [1:0] RX_CM_SEL = 2'b11;
  parameter [3:0] RX_CM_TRIM = 4'b0100;
  parameter integer RX_DATA_WIDTH = 20;
  parameter [5:0] RX_DDI_SEL = 6'b000000;
  parameter [13:0] RX_DEBUG_CFG = 14'b00000000000000;
  parameter RX_DEFER_RESET_BUF_EN = "TRUE";
  parameter RX_DISPERR_SEQ_MATCH = "TRUE";
  parameter [12:0] RX_OS_CFG = 13'b0001111110000;
  parameter integer RX_SIG_VALID_DLY = 10;
  parameter RX_XCLK_SEL = "RXREC";
  parameter [6:0] SAS_MAX_COM = 64;
  parameter [5:0] SAS_MIN_COM = 36;
  parameter [3:0] SATA_BURST_SEQ_LEN = 4'b1111;
  parameter [2:0] SATA_BURST_VAL = 3'b100;
  parameter [2:0] SATA_EIDLE_VAL = 3'b100;
  parameter [5:0] SATA_MAX_BURST = 8;
  parameter [5:0] SATA_MAX_INIT = 21;
  parameter [5:0] SATA_MAX_WAKE = 7;
  parameter [5:0] SATA_MIN_BURST = 4;
  parameter [5:0] SATA_MIN_INIT = 12;
  parameter [5:0] SATA_MIN_WAKE = 4;
  parameter SATA_PLL_CFG = "VCO_3000MHZ";
  parameter SHOW_REALIGN_COMMA = "TRUE";
  parameter SIM_RECEIVER_DETECT_PASS = "TRUE";
  parameter SIM_RESET_SPEEDUP = "TRUE";
  parameter SIM_TX_EIDLE_DRIVE_LEVEL = "X";
  parameter SIM_VERSION = "1.0";
  parameter [14:0] TERM_RCAL_CFG = 15'b100001000010000;
  parameter [2:0] TERM_RCAL_OVRD = 3'b000;
  parameter [7:0] TRANS_TIME_RATE = 8'h0E;
  parameter [31:0] TST_RSV = 32'h00000000;
  parameter TXBUF_EN = "TRUE";
  parameter TXBUF_RESET_ON_RATE_CHANGE = "FALSE";
  parameter [15:0] TXDLY_CFG = 16'h0010;
  parameter [8:0] TXDLY_LCFG = 9'h020;
  parameter [15:0] TXDLY_TAP_CFG = 16'h0000;
  parameter TXGEARBOX_EN = "FALSE";
  parameter [0:0] TXOOB_CFG = 1'b0;
  parameter integer TXOUT_DIV = 2;
  parameter [4:0] TXPCSRESET_TIME = 5'b00001;
  parameter [23:0] TXPHDLY_CFG = 24'h084000;
  parameter [15:0] TXPH_CFG = 16'h0400;
  parameter [4:0] TXPH_MONITOR_SEL = 5'b00000;
  parameter [1:0] TXPI_CFG0 = 2'b00;
  parameter [1:0] TXPI_CFG1 = 2'b00;
  parameter [1:0] TXPI_CFG2 = 2'b00;
  parameter [0:0] TXPI_CFG3 = 1'b0;
  parameter [0:0] TXPI_CFG4 = 1'b0;
  parameter [2:0] TXPI_CFG5 = 3'b000;
  parameter [0:0] TXPI_GREY_SEL = 1'b0;
  parameter [0:0] TXPI_INVSTROBE_SEL = 1'b0;
  parameter TXPI_PPMCLK_SEL = "TXUSRCLK2";
  parameter [7:0] TXPI_PPM_CFG = 8'b00000000;
  parameter [2:0] TXPI_SYNFREQ_PPM = 3'b000;
  parameter [4:0] TXPMARESET_TIME = 5'b00001;
  parameter [0:0] TXSYNC_MULTILANE = 1'b0;
  parameter [0:0] TXSYNC_OVRD = 1'b0;
  parameter [0:0] TXSYNC_SKIP_DA = 1'b0;
  parameter integer TX_CLK25_DIV = 7;
  parameter [0:0] TX_CLKMUX_EN = 1'b1;
  parameter integer TX_DATA_WIDTH = 20;
  parameter [5:0] TX_DEEMPH0 = 6'b000000;
  parameter [5:0] TX_DEEMPH1 = 6'b000000;
  parameter TX_DRIVE_MODE = "DIRECT";
  parameter [2:0] TX_EIDLE_ASSERT_DELAY = 3'b110;
  parameter [2:0] TX_EIDLE_DEASSERT_DELAY = 3'b100;
  parameter TX_LOOPBACK_DRIVE_HIZ = "FALSE";
  parameter [0:0] TX_MAINCURSOR_SEL = 1'b0;
  parameter [6:0] TX_MARGIN_FULL_0 = 7'b1001110;
  parameter [6:0] TX_MARGIN_FULL_1 = 7'b1001001;
  parameter [6:0] TX_MARGIN_FULL_2 = 7'b1000101;
  parameter [6:0] TX_MARGIN_FULL_3 = 7'b1000010;
  parameter [6:0] TX_MARGIN_FULL_4 = 7'b1000000;
  parameter [6:0] TX_MARGIN_LOW_0 = 7'b1000110;
  parameter [6:0] TX_MARGIN_LOW_1 = 7'b1000100;
  parameter [6:0] TX_MARGIN_LOW_2 = 7'b1000010;
  parameter [6:0] TX_MARGIN_LOW_3 = 7'b1000000;
  parameter [6:0] TX_MARGIN_LOW_4 = 7'b1000000;
  parameter [0:0] TX_PREDRIVER_MODE = 1'b0;
  parameter [13:0] TX_RXDETECT_CFG = 14'h1832;
  parameter [2:0] TX_RXDETECT_REF = 3'b100;
  parameter TX_XCLK_SEL = "TXUSR";
  parameter [0:0] UCODEER_CLR = 1'b0;
  parameter [0:0] USE_PCS_CLK_PHASE_SEL = 1'b0;

  parameter IO_LOC_PAIRS = "NONE";

  localparam [1:0] CHAN_BOND_SEQ_LEN_BIN = CHAN_BOND_SEQ_LEN - 1;
  localparam [1:0] CLK_COR_SEQ_LEN_BIN = CLK_COR_SEQ_LEN - 1;
  localparam [4:0] RX_CLK25_DIV_BIN = RX_CLK25_DIV - 1;
  localparam [4:0] TX_CLK25_DIV_BIN = TX_CLK25_DIV - 1;
  localparam [4:0] RX_SIG_VALID_DLY_BIN = RX_SIG_VALID_DLY - 1;

  localparam [2:0] RX_DATA_WIDTH_BIN = RX_DATA_WIDTH == 16 ? 3'b010 :
                                       RX_DATA_WIDTH == 20 ? 3'b011 :
                                       RX_DATA_WIDTH == 32 ? 3'b100 :
                                     /*RX_DATA_WIDTH == 40*/ 3'b101;
  localparam [2:0] TX_DATA_WIDTH_BIN = TX_DATA_WIDTH == 16 ? 3'b010 :
                                       TX_DATA_WIDTH == 20 ? 3'b011 :
                                       TX_DATA_WIDTH == 32 ? 3'b100 :
                                     /*TX_DATA_WIDTH == 40*/ 3'b101;

  localparam [1:0] RXOUT_DIV_BIN = RXOUT_DIV == 1 ? 2'b00 :
                                   RXOUT_DIV == 2 ? 2'b01 :
                                   RXOUT_DIV == 4 ? 2'b10 :
                                 /*RXOUT_DIV == 8*/ 2'b11;
  localparam [1:0] TXOUT_DIV_BIN = TXOUT_DIV == 1 ? 2'b00 :
                                   TXOUT_DIV == 2 ? 2'b01 :
                                   TXOUT_DIV == 4 ? 2'b10 :
                                 /*TXOUT_DIV == 8*/ 2'b11;

  parameter _TECHMAP_CONSTMSK_TXUSRCLK_      = 0;
  parameter _TECHMAP_CONSTVAL_TXUSRCLK_      = 0;
  parameter _TECHMAP_CONSTMSK_TXUSRCLK2_     = 0;
  parameter _TECHMAP_CONSTVAL_TXUSRCLK2_     = 0;
  parameter _TECHMAP_CONSTMSK_TXPHDLYTSTCLK_ = 0;
  parameter _TECHMAP_CONSTVAL_TXPHDLYTSTCLK_ = 0;
  parameter _TECHMAP_CONSTMSK_SIGVALIDCLK_   = 0;
  parameter _TECHMAP_CONSTVAL_SIGVALIDCLK_   = 0;
  parameter _TECHMAP_CONSTMSK_RXUSRCLK_      = 0;
  parameter _TECHMAP_CONSTVAL_RXUSRCLK_      = 0;
  parameter _TECHMAP_CONSTMSK_RXUSRCLK2_     = 0;
  parameter _TECHMAP_CONSTVAL_RXUSRCLK2_     = 0;
  parameter _TECHMAP_CONSTVAL_DRPCLK_        = 0;
  parameter _TECHMAP_CONSTMSK_DRPCLK_        = 0;
  parameter _TECHMAP_CONSTVAL_DMONITORCLK_   = 0;
  parameter _TECHMAP_CONSTMSK_DMONITORCLK_   = 0;
  parameter _TECHMAP_CONSTVAL_CLKRSVD0_      = 0;
  parameter _TECHMAP_CONSTMSK_CLKRSVD0_      = 0;
  parameter _TECHMAP_CONSTVAL_CLKRSVD1_      = 0;
  parameter _TECHMAP_CONSTMSK_CLKRSVD1_      = 0;

  parameter [0:0] IS_TXUSRCLK_INVERTED = 1'b0;
  parameter [0:0] IS_TXUSRCLK2_INVERTED = 1'b0;
  parameter [0:0] IS_TXPHDLYTSTCLK_INVERTED = 1'b0;
  parameter [0:0] IS_SIGVALIDCLK_INVERTED = 1'b0;
  parameter [0:0] IS_RXUSRCLK_INVERTED = 1'b0;
  parameter [0:0] IS_RXUSRCLK2_INVERTED = 1'b0;
  parameter [0:0] IS_DRPCLK_INVERTED = 1'b0;
  parameter [0:0] IS_DMONITORCLK_INVERTED = 1'b0;
  parameter [0:0] IS_CLKRSVD0_INVERTED = 1'b0;
  parameter [0:0] IS_CLKRSVD1_INVERTED = 1'b0;

  localparam [0:0] INV_TXUSRCLK = (_TECHMAP_CONSTMSK_TXUSRCLK_ == 1) ? !_TECHMAP_CONSTVAL_TXUSRCLK_ ^ IS_TXUSRCLK_INVERTED :
                                  (_TECHMAP_CONSTVAL_TXUSRCLK_ == 0) ? ~IS_TXUSRCLK_INVERTED : IS_TXUSRCLK_INVERTED;

  wire txusrclk = (_TECHMAP_CONSTMSK_TXUSRCLK_ == 1) ? 1'b1 :
                  (_TECHMAP_CONSTVAL_TXUSRCLK_ == 0) ? 1'b1 : TXUSRCLK;

  localparam [0:0] INV_TXUSRCLK2 = (_TECHMAP_CONSTMSK_TXUSRCLK2_ == 1) ? !_TECHMAP_CONSTVAL_TXUSRCLK2_ ^ IS_TXUSRCLK2_INVERTED :
                                   (_TECHMAP_CONSTVAL_TXUSRCLK2_ == 0) ? ~IS_TXUSRCLK2_INVERTED : IS_TXUSRCLK2_INVERTED;

  wire txusrclk2 = (_TECHMAP_CONSTMSK_TXUSRCLK2_ == 1) ? 1'b1 :
                   (_TECHMAP_CONSTVAL_TXUSRCLK2_ == 0) ? 1'b1 : TXUSRCLK2;

  localparam [0:0] INV_TXPHDLYTSTCLK = (_TECHMAP_CONSTMSK_TXPHDLYTSTCLK_ == 1) ? !_TECHMAP_CONSTVAL_TXPHDLYTSTCLK_ ^ IS_TXPHDLYTSTCLK_INVERTED :
                                       (_TECHMAP_CONSTVAL_TXPHDLYTSTCLK_ == 0) ? ~IS_TXPHDLYTSTCLK_INVERTED : IS_TXPHDLYTSTCLK_INVERTED;

  wire txphdlytstclk = (_TECHMAP_CONSTMSK_TXPHDLYTSTCLK_ == 1) ? 1'b1 :
                       (_TECHMAP_CONSTVAL_TXPHDLYTSTCLK_ == 0) ? 1'b1 : TXPHDLYTSTCLK;

  localparam [0:0] INV_SIGVALIDCLK = (_TECHMAP_CONSTMSK_SIGVALIDCLK_ == 1) ? !_TECHMAP_CONSTVAL_SIGVALIDCLK_ ^ IS_SIGVALIDCLK_INVERTED :
                                     (_TECHMAP_CONSTVAL_SIGVALIDCLK_ == 0) ? ~IS_SIGVALIDCLK_INVERTED : IS_SIGVALIDCLK_INVERTED;

  wire sigvalidclk  = (_TECHMAP_CONSTMSK_SIGVALIDCLK_ == 1) ? 1'b1 :
                      (_TECHMAP_CONSTVAL_SIGVALIDCLK_ == 0) ? 1'b1 : SIGVALIDCLK;

  localparam [0:0] INV_RXUSRCLK = (_TECHMAP_CONSTMSK_RXUSRCLK_ == 1) ? !_TECHMAP_CONSTVAL_RXUSRCLK_ ^ IS_RXUSRCLK_INVERTED :
                                  (_TECHMAP_CONSTVAL_RXUSRCLK_ == 0) ? ~IS_RXUSRCLK_INVERTED : IS_RXUSRCLK_INVERTED;

  wire rxusrclk = (_TECHMAP_CONSTMSK_RXUSRCLK_ == 1) ? 1'b1 :
                  (_TECHMAP_CONSTVAL_RXUSRCLK_ == 0) ? 1'b1 : RXUSRCLK;

  localparam [0:0] INV_RXUSRCLK2 = (_TECHMAP_CONSTMSK_RXUSRCLK2_ == 1) ? !_TECHMAP_CONSTVAL_RXUSRCLK2_ ^ IS_RXUSRCLK2_INVERTED :
                                   (_TECHMAP_CONSTVAL_RXUSRCLK2_ == 0) ? ~IS_RXUSRCLK2_INVERTED : IS_RXUSRCLK2_INVERTED;

  wire rxusrclk2 = (_TECHMAP_CONSTMSK_RXUSRCLK2_ == 1) ? 1'b1 :
                   (_TECHMAP_CONSTVAL_RXUSRCLK2_ == 0) ? 1'b1 : RXUSRCLK2;

  localparam [0:0] INV_DRPCLK = (_TECHMAP_CONSTMSK_DRPCLK_ == 1) ? !_TECHMAP_CONSTVAL_DRPCLK_ ^ IS_DRPCLK_INVERTED :
                                (_TECHMAP_CONSTVAL_DRPCLK_ == 0) ? ~IS_DRPCLK_INVERTED : IS_DRPCLK_INVERTED;

  wire drpclk = (_TECHMAP_CONSTMSK_DRPCLK_ == 1) ? 1'b1 :
                (_TECHMAP_CONSTVAL_DRPCLK_ == 0) ? 1'b1 : DRPCLK;

  localparam [0:0] INV_DMONITORCLK = (_TECHMAP_CONSTMSK_DMONITORCLK_ == 1) ? !_TECHMAP_CONSTVAL_DMONITORCLK_ ^ IS_DMONITORCLK_INVERTED :
                                     (_TECHMAP_CONSTVAL_DMONITORCLK_ == 0) ? ~IS_DMONITORCLK_INVERTED : IS_DMONITORCLK_INVERTED;

  wire dmonitorclk = (_TECHMAP_CONSTMSK_DMONITORCLK_ == 1) ? 1'b1 :
                     (_TECHMAP_CONSTVAL_DMONITORCLK_ == 0) ? 1'b1 : DMONITORCLK;

  localparam [0:0] INV_CLKRSVD0 = (_TECHMAP_CONSTMSK_CLKRSVD0_ == 1) ? !_TECHMAP_CONSTVAL_CLKRSVD0_ ^ IS_CLKRSVD0_INVERTED :
                                  (_TECHMAP_CONSTVAL_CLKRSVD0_ == 0) ? ~IS_CLKRSVD0_INVERTED : IS_CLKRSVD0_INVERTED;

  wire clkrsvd0 = (_TECHMAP_CONSTMSK_CLKRSVD0_ == 1) ? 1'b1 :
                  (_TECHMAP_CONSTVAL_CLKRSVD0_ == 0) ? 1'b1 : CLKRSVD0;

  localparam [0:0] INV_CLKRSVD1 = (_TECHMAP_CONSTMSK_CLKRSVD1_ == 1) ? !_TECHMAP_CONSTVAL_CLKRSVD1_ ^ IS_CLKRSVD1_INVERTED :
                                  (_TECHMAP_CONSTVAL_CLKRSVD1_ == 0) ? ~IS_CLKRSVD1_INVERTED : IS_CLKRSVD1_INVERTED;

  wire clkrsvd1 = (_TECHMAP_CONSTMSK_CLKRSVD1_ == 1) ? 1'b1 :
                  (_TECHMAP_CONSTVAL_CLKRSVD1_ == 0) ? 1'b1 : CLKRSVD1;



  parameter IN_USE = 1'b0;

  wire gtprxn, gtprxp;
  IPAD_GTP_VPR ibuf_rx_n (.I(GTPRXN), .O(gtprxn));
  IPAD_GTP_VPR ibuf_rx_p (.I(GTPRXP), .O(gtprxp));

  wire gtptxn, gtptxp;
  OPAD_GTP_VPR obuf_tx_n (.I(gtptxn), .O(GTPTXN));
  OPAD_GTP_VPR obuf_tx_p (.I(gtptxp), .O(GTPTXP));

  GTPE2_CHANNEL_VPR #(
    .ACJTAG_DEBUG_MODE              (ACJTAG_DEBUG_MODE),
    .ACJTAG_MODE                    (ACJTAG_MODE),
    .ACJTAG_RESET                   (ACJTAG_RESET),
    .ADAPT_CFG0                     (ADAPT_CFG0),
    .ALIGN_COMMA_DOUBLE             (ALIGN_COMMA_DOUBLE == "TRUE"),
    .ALIGN_COMMA_ENABLE             (ALIGN_COMMA_ENABLE),
    .ALIGN_COMMA_WORD               (ALIGN_COMMA_WORD),
    .ALIGN_MCOMMA_DET               (ALIGN_MCOMMA_DET == "TRUE"),
    .ALIGN_MCOMMA_VALUE             (ALIGN_MCOMMA_VALUE),
    .ALIGN_PCOMMA_DET               (ALIGN_PCOMMA_DET == "TRUE"),
    .ALIGN_PCOMMA_VALUE             (ALIGN_PCOMMA_VALUE),
    .CBCC_DATA_SOURCE_SEL_DECODED   (CBCC_DATA_SOURCE_SEL == "DECODED"),
    .CFOK_CFG                       (CFOK_CFG),
    .CFOK_CFG2                      (CFOK_CFG2),
    .CFOK_CFG3                      (CFOK_CFG3),
    .CFOK_CFG4                      (CFOK_CFG4),
    .CFOK_CFG5                      (CFOK_CFG5),
    .CFOK_CFG6                      (CFOK_CFG6),
    .CHAN_BOND_KEEP_ALIGN           (CHAN_BOND_KEEP_ALIGN == "TRUE"),
    .CHAN_BOND_MAX_SKEW             (CHAN_BOND_MAX_SKEW),
    .CHAN_BOND_SEQ_1_1              (CHAN_BOND_SEQ_1_1),
    .CHAN_BOND_SEQ_1_2              (CHAN_BOND_SEQ_1_2),
    .CHAN_BOND_SEQ_1_3              (CHAN_BOND_SEQ_1_3),
    .CHAN_BOND_SEQ_1_4              (CHAN_BOND_SEQ_1_4),
    .CHAN_BOND_SEQ_1_ENABLE         (CHAN_BOND_SEQ_1_ENABLE),
    .CHAN_BOND_SEQ_2_1              (CHAN_BOND_SEQ_2_1),
    .CHAN_BOND_SEQ_2_2              (CHAN_BOND_SEQ_2_2),
    .CHAN_BOND_SEQ_2_3              (CHAN_BOND_SEQ_2_3),
    .CHAN_BOND_SEQ_2_4              (CHAN_BOND_SEQ_2_4),
    .CHAN_BOND_SEQ_2_ENABLE         (CHAN_BOND_SEQ_2_ENABLE),
    .CHAN_BOND_SEQ_2_USE            (CHAN_BOND_SEQ_2_USE == "TRUE"),
    .CHAN_BOND_SEQ_LEN              (CHAN_BOND_SEQ_LEN_BIN),
    .CLK_COMMON_SWING               (CLK_COMMON_SWING),
    .CLK_CORRECT_USE                (CLK_CORRECT_USE == "TRUE"),
    .CLK_COR_KEEP_IDLE              (CLK_COR_KEEP_IDLE == "TRUE"),
    .CLK_COR_MAX_LAT                (CLK_COR_MAX_LAT),
    .CLK_COR_MIN_LAT                (CLK_COR_MIN_LAT),
    .CLK_COR_PRECEDENCE             (CLK_COR_PRECEDENCE == "TRUE"),
    .CLK_COR_REPEAT_WAIT            (CLK_COR_REPEAT_WAIT),
    .CLK_COR_SEQ_1_1                (CLK_COR_SEQ_1_1),
    .CLK_COR_SEQ_1_2                (CLK_COR_SEQ_1_2),
    .CLK_COR_SEQ_1_3                (CLK_COR_SEQ_1_3),
    .CLK_COR_SEQ_1_4                (CLK_COR_SEQ_1_4),
    .CLK_COR_SEQ_1_ENABLE           (CLK_COR_SEQ_1_ENABLE),
    .CLK_COR_SEQ_2_1                (CLK_COR_SEQ_2_1),
    .CLK_COR_SEQ_2_2                (CLK_COR_SEQ_2_2),
    .CLK_COR_SEQ_2_3                (CLK_COR_SEQ_2_3),
    .CLK_COR_SEQ_2_4                (CLK_COR_SEQ_2_4),
    .CLK_COR_SEQ_2_ENABLE           (CLK_COR_SEQ_2_ENABLE),
    .CLK_COR_SEQ_2_USE              (CLK_COR_SEQ_2_USE == "TRUE"),
    .CLK_COR_SEQ_LEN                (CLK_COR_SEQ_LEN_BIN),
    .DEC_MCOMMA_DETECT              (DEC_MCOMMA_DETECT == "TRUE"),
    .DEC_PCOMMA_DETECT              (DEC_PCOMMA_DETECT == "TRUE"),
    .DEC_VALID_COMMA_ONLY           (DEC_VALID_COMMA_ONLY == "TRUE"),
    .DMONITOR_CFG                   (DMONITOR_CFG),
    .ES_CLK_PHASE_SEL               (ES_CLK_PHASE_SEL),
    .ES_CONTROL                     (ES_CONTROL),
    .ES_ERRDET_EN                   (ES_ERRDET_EN == "TRUE"),
    .ES_EYE_SCAN_EN                 (ES_EYE_SCAN_EN == "TRUE"),
    .ES_HORZ_OFFSET                 (ES_HORZ_OFFSET),
    .ES_PMA_CFG                     (ES_PMA_CFG),
    .ES_PRESCALE                    (ES_PRESCALE),
    .ES_QUALIFIER                   (ES_QUALIFIER),
    .ES_QUAL_MASK                   (ES_QUAL_MASK),
    .ES_SDATA_MASK                  (ES_SDATA_MASK),
    .ES_VERT_OFFSET                 (ES_VERT_OFFSET),
    .FTS_DESKEW_SEQ_ENABLE          (FTS_DESKEW_SEQ_ENABLE),
    .FTS_LANE_DESKEW_CFG            (FTS_LANE_DESKEW_CFG),
    .FTS_LANE_DESKEW_EN             (FTS_LANE_DESKEW_EN == "TRUE"),
    .GEARBOX_MODE                   (GEARBOX_MODE),
    .LOOPBACK_CFG                   (LOOPBACK_CFG),
    .OUTREFCLK_SEL_INV              (OUTREFCLK_SEL_INV),
    .PCS_PCIE_EN                    (PCS_PCIE_EN == "TRUE"),
    .PCS_RSVD_ATTR                  (PCS_RSVD_ATTR),
    .PD_TRANS_TIME_FROM_P2          (PD_TRANS_TIME_FROM_P2),
    .PD_TRANS_TIME_NONE_P2          (PD_TRANS_TIME_NONE_P2),
    .PD_TRANS_TIME_TO_P2            (PD_TRANS_TIME_TO_P2),
    .PMA_LOOPBACK_CFG               (PMA_LOOPBACK_CFG),
    .PMA_RSV                        (PMA_RSV),
    .PMA_RSV2                       (PMA_RSV2),
    .PMA_RSV3                       (PMA_RSV3),
    .PMA_RSV4                       (PMA_RSV4),
    .PMA_RSV5                       (PMA_RSV5),
    .PMA_RSV6                       (PMA_RSV6),
    .PMA_RSV7                       (PMA_RSV7),
    .RXBUFRESET_TIME                (RXBUFRESET_TIME),
    .RXBUF_ADDR_MODE_FAST           (RXBUF_ADDR_MODE == "FAST"),
    .RXBUF_EIDLE_HI_CNT             (RXBUF_EIDLE_HI_CNT),
    .RXBUF_EIDLE_LO_CNT             (RXBUF_EIDLE_LO_CNT),
    .RXBUF_EN                       (RXBUF_EN == "TRUE"),
    .RXBUF_RESET_ON_CB_CHANGE       (RXBUF_RESET_ON_CB_CHANGE == "TRUE"),
    .RXBUF_RESET_ON_COMMAALIGN      (RXBUF_RESET_ON_COMMAALIGN == "TRUE"),
    .RXBUF_RESET_ON_EIDLE           (RXBUF_RESET_ON_EIDLE == "TRUE"),
    .RXBUF_RESET_ON_RATE_CHANGE     (RXBUF_RESET_ON_RATE_CHANGE == "TRUE"),
    .RXBUF_THRESH_OVFLW             (RXBUF_THRESH_OVFLW),
    .RXBUF_THRESH_OVRD              (RXBUF_THRESH_OVRD == "TRUE"),
    .RXBUF_THRESH_UNDFLW            (RXBUF_THRESH_UNDFLW),
    .RXCDRFREQRESET_TIME            (RXCDRFREQRESET_TIME),
    .RXCDRPHRESET_TIME              (RXCDRPHRESET_TIME),
    .RXCDR_CFG                      (RXCDR_CFG),
    .RXCDR_FR_RESET_ON_EIDLE        (RXCDR_FR_RESET_ON_EIDLE),
    .RXCDR_HOLD_DURING_EIDLE        (RXCDR_HOLD_DURING_EIDLE),
    .RXCDR_LOCK_CFG                 (RXCDR_LOCK_CFG),
    .RXCDR_PH_RESET_ON_EIDLE        (RXCDR_PH_RESET_ON_EIDLE),
    .RXDLY_CFG                      (RXDLY_CFG),
    .RXDLY_LCFG                     (RXDLY_LCFG),
    .RXDLY_TAP_CFG                  (RXDLY_TAP_CFG),
    .RXGEARBOX_EN                   (RXGEARBOX_EN == "TRUE"),
    .RXISCANRESET_TIME              (RXISCANRESET_TIME),
    .RXLPMRESET_TIME                (RXLPMRESET_TIME),
    .RXLPM_BIAS_STARTUP_DISABLE     (RXLPM_BIAS_STARTUP_DISABLE),
    .RXLPM_CFG                      (RXLPM_CFG),
    .RXLPM_CFG1                     (RXLPM_CFG1),
    .RXLPM_CM_CFG                   (RXLPM_CM_CFG),
    .RXLPM_GC_CFG                   (RXLPM_GC_CFG),
    .RXLPM_GC_CFG2                  (RXLPM_GC_CFG2),
    .RXLPM_HF_CFG                   (RXLPM_HF_CFG),
    .RXLPM_HF_CFG2                  (RXLPM_HF_CFG2),
    .RXLPM_HF_CFG3                  (RXLPM_HF_CFG3),
    .RXLPM_HOLD_DURING_EIDLE        (RXLPM_HOLD_DURING_EIDLE),
    .RXLPM_INCM_CFG                 (RXLPM_INCM_CFG),
    .RXLPM_IPCM_CFG                 (RXLPM_IPCM_CFG),
    .RXLPM_LF_CFG                   (RXLPM_LF_CFG),
    .RXLPM_LF_CFG2                  (RXLPM_LF_CFG2),
    .RXLPM_OSINT_CFG                (RXLPM_OSINT_CFG),
    .RXOOB_CFG                      (RXOOB_CFG),
    .RXOOB_CLK_CFG_FABRIC           (RXOOB_CLK_CFG == "FABRIC"),
    .RXOSCALRESET_TIME              (RXOSCALRESET_TIME),
    .RXOSCALRESET_TIMEOUT           (RXOSCALRESET_TIMEOUT),
    .RXOUT_DIV                      (RXOUT_DIV_BIN),
    .RXPCSRESET_TIME                (RXPCSRESET_TIME),
    .RXPHDLY_CFG                    (RXPHDLY_CFG),
    .RXPH_CFG                       (RXPH_CFG),
    .RXPH_MONITOR_SEL               (RXPH_MONITOR_SEL),
    .RXPI_CFG0                      (RXPI_CFG0),
    .RXPI_CFG1                      (RXPI_CFG1),
    .RXPI_CFG2                      (RXPI_CFG2),
    .RXPMARESET_TIME                (RXPMARESET_TIME),
    .RXPRBS_ERR_LOOPBACK            (RXPRBS_ERR_LOOPBACK),
    .RXSLIDE_AUTO_WAIT              (RXSLIDE_AUTO_WAIT),
    .RXSLIDE_MODE_AUTO              (RXSLIDE_MODE == "AUTO"),
    .RXSLIDE_MODE_PCS               (RXSLIDE_MODE == "PCS"),
    .RXSLIDE_MODE_PMA               (RXSLIDE_MODE == "PMA"),
    .RXSYNC_MULTILANE               (RXSYNC_MULTILANE),
    .RXSYNC_OVRD                    (RXSYNC_OVRD),
    .RXSYNC_SKIP_DA                 (RXSYNC_SKIP_DA),
    .RX_BIAS_CFG                    (RX_BIAS_CFG),
    .RX_BUFFER_CFG                  (RX_BUFFER_CFG),
    .RX_CLK25_DIV                   (RX_CLK25_DIV_BIN),
    .RX_CLKMUX_EN                   (RX_CLKMUX_EN),
    .RX_CM_SEL                      (RX_CM_SEL),
    .RX_CM_TRIM                     (RX_CM_TRIM),
    .RX_DATA_WIDTH                  (RX_DATA_WIDTH_BIN),
    .RX_DDI_SEL                     (RX_DDI_SEL),
    .RX_DEBUG_CFG                   (RX_DEBUG_CFG),
    .RX_DEFER_RESET_BUF_EN          (RX_DEFER_RESET_BUF_EN == "TRUE"),
    .RX_DISPERR_SEQ_MATCH           (RX_DISPERR_SEQ_MATCH == "TRUE"),
    .RX_OS_CFG                      (RX_OS_CFG),
    .RX_SIG_VALID_DLY               (RX_SIG_VALID_DLY_BIN),
    .RX_XCLK_SEL_RXUSR              (RX_XCLK_SEL == "RXUSR"),
    .SAS_MAX_COM                    (SAS_MAX_COM),
    .SAS_MIN_COM                    (SAS_MIN_COM),
    .SATA_BURST_SEQ_LEN             (SATA_BURST_SEQ_LEN),
    .SATA_BURST_VAL                 (SATA_BURST_VAL),
    .SATA_EIDLE_VAL                 (SATA_EIDLE_VAL),
    .SATA_MAX_BURST                 (SATA_MAX_BURST),
    .SATA_MAX_INIT                  (SATA_MAX_INIT),
    .SATA_MAX_WAKE                  (SATA_MAX_WAKE),
    .SATA_MIN_BURST                 (SATA_MIN_BURST),
    .SATA_MIN_INIT                  (SATA_MIN_INIT),
    .SATA_MIN_WAKE                  (SATA_MIN_WAKE),
    .SATA_PLL_CFG_VCO_1500MHZ       (SATA_PLL_CFG == "VCO_1500MHZ"),
    .SATA_PLL_CFG_VCO_750MHZ        (SATA_PLL_CFG == "VCO_750MHZ"),
    .SHOW_REALIGN_COMMA             (SHOW_REALIGN_COMMA == "TRUE"),
    .SIM_RECEIVER_DETECT_PASS       (SIM_RECEIVER_DETECT_PASS),
    .SIM_RESET_SPEEDUP              (SIM_RESET_SPEEDUP),
    .SIM_TX_EIDLE_DRIVE_LEVEL       (SIM_TX_EIDLE_DRIVE_LEVEL),
    .SIM_VERSION                    (SIM_VERSION),
    .TERM_RCAL_CFG                  (TERM_RCAL_CFG),
    .TERM_RCAL_OVRD                 (TERM_RCAL_OVRD),
    .TRANS_TIME_RATE                (TRANS_TIME_RATE),
    .TST_RSV                        (TST_RSV),
    .TXBUF_EN                       (TXBUF_EN == "TRUE"),
    .TXBUF_RESET_ON_RATE_CHANGE     (TXBUF_RESET_ON_RATE_CHANGE == "TRUE"),
    .TXDLY_CFG                      (TXDLY_CFG),
    .TXDLY_LCFG                     (TXDLY_LCFG),
    .TXDLY_TAP_CFG                  (TXDLY_TAP_CFG),
    .TXGEARBOX_EN                   (TXGEARBOX_EN == "TRUE"),
    .TXOOB_CFG                      (TXOOB_CFG),
    .TXOUT_DIV                      (TXOUT_DIV_BIN),
    .TXPCSRESET_TIME                (TXPCSRESET_TIME),
    .TXPHDLY_CFG                    (TXPHDLY_CFG),
    .TXPH_CFG                       (TXPH_CFG),
    .TXPH_MONITOR_SEL               (TXPH_MONITOR_SEL),
    .TXPI_CFG0                      (TXPI_CFG0),
    .TXPI_CFG1                      (TXPI_CFG1),
    .TXPI_CFG2                      (TXPI_CFG2),
    .TXPI_CFG3                      (TXPI_CFG3),
    .TXPI_CFG4                      (TXPI_CFG4),
    .TXPI_CFG5                      (TXPI_CFG5),
    .TXPI_GREY_SEL                  (TXPI_GREY_SEL),
    .TXPI_INVSTROBE_SEL             (TXPI_INVSTROBE_SEL),
    .TXPI_PPMCLK_SEL_TXUSRCLK2      (TXPI_PPMCLK_SEL == "TXUSRCLK2"),
    .TXPI_PPM_CFG                   (TXPI_PPM_CFG),
    .TXPI_SYNFREQ_PPM               (TXPI_SYNFREQ_PPM),
    .TXPMARESET_TIME                (TXPMARESET_TIME),
    .TXSYNC_MULTILANE               (TXSYNC_MULTILANE),
    .TXSYNC_OVRD                    (TXSYNC_OVRD),
    .TXSYNC_SKIP_DA                 (TXSYNC_SKIP_DA),
    .TX_CLK25_DIV                   (TX_CLK25_DIV_BIN),
    .TX_CLKMUX_EN                   (TX_CLKMUX_EN),
    .TX_DATA_WIDTH                  (TX_DATA_WIDTH_BIN),
    .TX_DEEMPH0                     (TX_DEEMPH0),
    .TX_DEEMPH1                     (TX_DEEMPH1),
    .TX_DRIVE_MODE_PIPE             (TX_DRIVE_MODE == "PIPE"),
    .TX_EIDLE_ASSERT_DELAY          (TX_EIDLE_ASSERT_DELAY),
    .TX_EIDLE_DEASSERT_DELAY        (TX_EIDLE_DEASSERT_DELAY),
    .TX_LOOPBACK_DRIVE_HIZ          (TX_LOOPBACK_DRIVE_HIZ == "TRUE"),
    .TX_MAINCURSOR_SEL              (TX_MAINCURSOR_SEL),
    .TX_MARGIN_FULL_0               (TX_MARGIN_FULL_0),
    .TX_MARGIN_FULL_1               (TX_MARGIN_FULL_1),
    .TX_MARGIN_FULL_2               (TX_MARGIN_FULL_2),
    .TX_MARGIN_FULL_3               (TX_MARGIN_FULL_3),
    .TX_MARGIN_FULL_4               (TX_MARGIN_FULL_4),
    .TX_MARGIN_LOW_0                (TX_MARGIN_LOW_0),
    .TX_MARGIN_LOW_1                (TX_MARGIN_LOW_1),
    .TX_MARGIN_LOW_2                (TX_MARGIN_LOW_2),
    .TX_MARGIN_LOW_3                (TX_MARGIN_LOW_3),
    .TX_MARGIN_LOW_4                (TX_MARGIN_LOW_4),
    .TX_PREDRIVER_MODE              (TX_PREDRIVER_MODE),
    .TX_RXDETECT_CFG                (TX_RXDETECT_CFG),
    .TX_RXDETECT_REF                (TX_RXDETECT_REF),
    .TX_XCLK_SEL_TXUSR              (TX_XCLK_SEL == "TXUSR"),
    .UCODEER_CLR                    (UCODEER_CLR),
    .USE_PCS_CLK_PHASE_SEL          (USE_PCS_CLK_PHASE_SEL),
    .INV_TXUSRCLK                   (INV_TXUSRCLK),
    .INV_TXUSRCLK2                  (INV_TXUSRCLK2),
    .INV_TXPHDLYTSTCLK              (INV_TXPHDLYTSTCLK),
    .INV_SIGVALIDCLK                (INV_SIGVALIDCLK),
    .INV_RXUSRCLK                   (INV_RXUSRCLK),
    .INV_RXUSRCLK2                  (INV_RXUSRCLK2),
    .INV_DRPCLK                     (INV_DRPCLK),
    .INV_DMONITORCLK                (INV_DMONITORCLK),
    .INV_CLKRSVD0                   (INV_CLKRSVD0),
    .INV_CLKRSVD1                   (INV_CLKRSVD1),
    .IO_LOC_PAIRS                   (IO_LOC_PAIRS)
  ) gtp_channel (
    .GTPRXN                         (gtprxn),
    .GTPRXP                         (gtprxp),
    .GTPTXN                         (gtptxn),
    .GTPTXP                         (gtptxp),
    .DRPRDY                         (DRPRDY),
    .EYESCANDATAERROR               (EYESCANDATAERROR),
    .PHYSTATUS                      (PHYSTATUS),
    .PMARSVDOUT0                    (PMARSVDOUT0),
    .PMARSVDOUT1                    (PMARSVDOUT1),
    .RXBYTEISALIGNED                (RXBYTEISALIGNED),
    .RXBYTEREALIGN                  (RXBYTEREALIGN),
    .RXCDRLOCK                      (RXCDRLOCK),
    .RXCHANBONDSEQ                  (RXCHANBONDSEQ),
    .RXCHANISALIGNED                (RXCHANISALIGNED),
    .RXCHANREALIGN                  (RXCHANREALIGN),
    .RXCOMINITDET                   (RXCOMINITDET),
    .RXCOMMADET                     (RXCOMMADET),
    .RXCOMSASDET                    (RXCOMSASDET),
    .RXCOMWAKEDET                   (RXCOMWAKEDET),
    .RXDLYSRESETDONE                (RXDLYSRESETDONE),
    .RXELECIDLE                     (RXELECIDLE),
    .RXHEADERVALID                  (RXHEADERVALID),
    .RXOSINTDONE                    (RXOSINTDONE),
    .RXOSINTSTARTED                 (RXOSINTSTARTED),
    .RXOSINTSTROBEDONE              (RXOSINTSTROBEDONE),
    .RXOSINTSTROBESTARTED           (RXOSINTSTROBESTARTED),
    .RXOUTCLK                       (RXOUTCLK),
    .RXOUTCLKFABRIC                 (RXOUTCLKFABRIC),
    .RXOUTCLKPCS                    (RXOUTCLKPCS),
    .RXPHALIGNDONE                  (RXPHALIGNDONE),
    .RXPMARESETDONE                 (RXPMARESETDONE),
    .RXPRBSERR                      (RXPRBSERR),
    .RXRATEDONE                     (RXRATEDONE),
    .RXRESETDONE                    (RXRESETDONE),
    .RXSYNCDONE                     (RXSYNCDONE),
    .RXSYNCOUT                      (RXSYNCOUT),
    .RXVALID                        (RXVALID),
    .TXCOMFINISH                    (TXCOMFINISH),
    .TXDLYSRESETDONE                (TXDLYSRESETDONE),
    .TXGEARBOXREADY                 (TXGEARBOXREADY),
    .TXOUTCLK                       (TXOUTCLK),
    .TXOUTCLKFABRIC                 (TXOUTCLKFABRIC),
    .TXOUTCLKPCS                    (TXOUTCLKPCS),
    .TXPHALIGNDONE                  (TXPHALIGNDONE),
    .TXPHINITDONE                   (TXPHINITDONE),
    .TXPMARESETDONE                 (TXPMARESETDONE),
    .TXRATEDONE                     (TXRATEDONE),
    .TXRESETDONE                    (TXRESETDONE),
    .TXSYNCDONE                     (TXSYNCDONE),
    .TXSYNCOUT                      (TXSYNCOUT),
    .DMONITOROUT                    (DMONITOROUT),
    .DRPDO                          (DRPDO),
    .PCSRSVDOUT                     (PCSRSVDOUT),
    .RXCLKCORCNT                    (RXCLKCORCNT),
    .RXDATAVALID                    (RXDATAVALID),
    .RXSTARTOFSEQ                   (RXSTARTOFSEQ),
    .TXBUFSTATUS                    (TXBUFSTATUS),
    .RXBUFSTATUS                    (RXBUFSTATUS),
    .RXHEADER                       (RXHEADER),
    .RXSTATUS                       (RXSTATUS),
    .RXDATA                         (RXDATA),
    .RXCHARISCOMMA                  (RXCHARISCOMMA),
    .RXCHARISK                      (RXCHARISK),
    .RXCHBONDO                      (RXCHBONDO),
    .RXDISPERR                      (RXDISPERR),
    .RXNOTINTABLE                   (RXNOTINTABLE),
    .RXPHMONITOR                    (RXPHMONITOR),
    .RXPHSLIPMONITOR                (RXPHSLIPMONITOR),
    .CFGRESET                       (CFGRESET),
    .CLKRSVD0                       (clkrsvd0),
    .CLKRSVD1                       (clkrsvd1),
    .DMONFIFORESET                  (DMONFIFORESET),
    .DMONITORCLK                    (dmonitorclk),
    .DRPCLK                         (drpclk),
    .DRPEN                          (DRPEN),
    .DRPWE                          (DRPWE),
    .EYESCANMODE                    (EYESCANMODE),
    .EYESCANRESET                   (EYESCANRESET),
    .EYESCANTRIGGER                 (EYESCANTRIGGER),
    .GTRESETSEL                     (GTRESETSEL),
    .GTRXRESET                      (GTRXRESET),
    .GTTXRESET                      (GTTXRESET),
    .PMARSVDIN0                     (PMARSVDIN0),
    .PMARSVDIN1                     (PMARSVDIN1),
    .PMARSVDIN2                     (PMARSVDIN2),
    .PMARSVDIN3                     (PMARSVDIN3),
    .PMARSVDIN4                     (PMARSVDIN4),
    .RESETOVRD                      (RESETOVRD),
    .RX8B10BEN                      (RX8B10BEN),
    .RXBUFRESET                     (RXBUFRESET),
    .RXCDRFREQRESET                 (RXCDRFREQRESET),
    .RXCDRHOLD                      (RXCDRHOLD),
    .RXCDROVRDEN                    (RXCDROVRDEN),
    .RXCDRRESET                     (RXCDRRESET),
    .RXCDRRESETRSV                  (RXCDRRESETRSV),
    .RXCHBONDEN                     (RXCHBONDEN),
    .RXCHBONDMASTER                 (RXCHBONDMASTER),
    .RXCHBONDSLAVE                  (RXCHBONDSLAVE),
    .RXCOMMADETEN                   (RXCOMMADETEN),
    .RXDDIEN                        (RXDDIEN),
    .RXDFEXYDEN                     (RXDFEXYDEN),
    .RXDLYBYPASS                    (RXDLYBYPASS),
    .RXDLYEN                        (RXDLYEN),
    .RXDLYOVRDEN                    (RXDLYOVRDEN),
    .RXDLYSRESET                    (RXDLYSRESET),
    .RXGEARBOXSLIP                  (RXGEARBOXSLIP),
    .RXLPMHFHOLD                    (RXLPMHFHOLD),
    .RXLPMHFOVRDEN                  (RXLPMHFOVRDEN),
    .RXLPMLFHOLD                    (RXLPMLFHOLD),
    .RXLPMLFOVRDEN                  (RXLPMLFOVRDEN),
    .RXLPMOSINTNTRLEN               (RXLPMOSINTNTRLEN),
    .RXLPMRESET                     (RXLPMRESET),
    .RXMCOMMAALIGNEN                (RXMCOMMAALIGNEN),
    .RXOOBRESET                     (RXOOBRESET),
    .RXOSCALRESET                   (RXOSCALRESET),
    .RXOSHOLD                       (RXOSHOLD),
    .RXOSINTEN                      (RXOSINTEN),
    .RXOSINTHOLD                    (RXOSINTHOLD),
    .RXOSINTNTRLEN                  (RXOSINTNTRLEN),
    .RXOSINTOVRDEN                  (RXOSINTOVRDEN),
    .RXOSINTPD                      (RXOSINTPD),
    .RXOSINTSTROBE                  (RXOSINTSTROBE),
    .RXOSINTTESTOVRDEN              (RXOSINTTESTOVRDEN),
    .RXOSOVRDEN                     (RXOSOVRDEN),
    .RXPCOMMAALIGNEN                (RXPCOMMAALIGNEN),
    .RXPCSRESET                     (RXPCSRESET),
    .RXPHALIGN                      (RXPHALIGN),
    .RXPHALIGNEN                    (RXPHALIGNEN),
    .RXPHDLYPD                      (RXPHDLYPD),
    .RXPHDLYRESET                   (RXPHDLYRESET),
    .RXPHOVRDEN                     (RXPHOVRDEN),
    .RXPMARESET                     (RXPMARESET),
    .RXPOLARITY                     (RXPOLARITY),
    .RXPRBSCNTRESET                 (RXPRBSCNTRESET),
    .RXRATEMODE                     (RXRATEMODE),
    .RXSLIDE                        (RXSLIDE),
    .RXSYNCALLIN                    (RXSYNCALLIN),
    .RXSYNCIN                       (RXSYNCIN),
    .RXSYNCMODE                     (RXSYNCMODE),
    .RXUSERRDY                      (RXUSERRDY),
    .RXUSRCLK2                      (rxusrclk2),
    .RXUSRCLK                       (rxusrclk),
    .SETERRSTATUS                   (SETERRSTATUS),
    .SIGVALIDCLK                    (sigvalidclk),
    .TX8B10BEN                      (TX8B10BEN),
    .TXCOMINIT                      (TXCOMINIT),
    .TXCOMSAS                       (TXCOMSAS),
    .TXCOMWAKE                      (TXCOMWAKE),
    .TXDEEMPH                       (TXDEEMPH),
    .TXDETECTRX                     (TXDETECTRX),
    .TXDIFFPD                       (TXDIFFPD),
    .TXDLYBYPASS                    (TXDLYBYPASS),
    .TXDLYEN                        (TXDLYEN),
    .TXDLYHOLD                      (TXDLYHOLD),
    .TXDLYOVRDEN                    (TXDLYOVRDEN),
    .TXDLYSRESET                    (TXDLYSRESET),
    .TXDLYUPDOWN                    (TXDLYUPDOWN),
    .TXELECIDLE                     (TXELECIDLE),
    .TXINHIBIT                      (TXINHIBIT),
    .TXPCSRESET                     (TXPCSRESET),
    .TXPDELECIDLEMODE               (TXPDELECIDLEMODE),
    .TXPHALIGN                      (TXPHALIGN),
    .TXPHALIGNEN                    (TXPHALIGNEN),
    .TXPHDLYPD                      (TXPHDLYPD),
    .TXPHDLYRESET                   (TXPHDLYRESET),
    .TXPHDLYTSTCLK                  (txphdlytstclk),
    .TXPHINIT                       (TXPHINIT),
    .TXPHOVRDEN                     (TXPHOVRDEN),
    .TXPIPPMEN                      (TXPIPPMEN),
    .TXPIPPMOVRDEN                  (TXPIPPMOVRDEN),
    .TXPIPPMPD                      (TXPIPPMPD),
    .TXPIPPMSEL                     (TXPIPPMSEL),
    .TXPISOPD                       (TXPISOPD),
    .TXPMARESET                     (TXPMARESET),
    .TXPOLARITY                     (TXPOLARITY),
    .TXPOSTCURSORINV                (TXPOSTCURSORINV),
    .TXPRBSFORCEERR                 (TXPRBSFORCEERR),
    .TXPRECURSORINV                 (TXPRECURSORINV),
    .TXRATEMODE                     (TXRATEMODE),
    .TXSTARTSEQ                     (TXSTARTSEQ),
    .TXSWING                        (TXSWING),
    .TXSYNCALLIN                    (TXSYNCALLIN),
    .TXSYNCIN                       (TXSYNCIN),
    .TXSYNCMODE                     (TXSYNCMODE),
    .TXUSERRDY                      (TXUSERRDY),
    .TXUSRCLK2                      (txusrclk2),
    .TXUSRCLK                       (txusrclk),
    .RXADAPTSELTEST                 (RXADAPTSELTEST),
    .DRPDI                          (DRPDI),
    .GTRSVD                         (GTRSVD),
    .PCSRSVDIN                      (PCSRSVDIN),
    .TSTIN                          (TSTIN),
    .RXELECIDLEMODE                 (RXELECIDLEMODE),
    .RXPD                           (RXPD),
    .RXSYSCLKSEL                    (RXSYSCLKSEL),
    .TXPD                           (TXPD),
    .TXSYSCLKSEL                    (TXSYSCLKSEL),
    .LOOPBACK                       (LOOPBACK),
    .RXCHBONDLEVEL                  (RXCHBONDLEVEL),
    .RXOUTCLKSEL                    (RXOUTCLKSEL),
    .RXPRBSSEL                      (RXPRBSSEL),
    .RXRATE                         (RXRATE),
    .TXBUFDIFFCTRL                  (TXBUFDIFFCTRL),
    .TXHEADER                       (TXHEADER),
    .TXMARGIN                       (TXMARGIN),
    .TXOUTCLKSEL                    (TXOUTCLKSEL),
    .TXPRBSSEL                      (TXPRBSSEL),
    .TXRATE                         (TXRATE),
    .TXDATA                         (TXDATA),
    .RXCHBONDI                      (RXCHBONDI),
    .RXOSINTCFG                     (RXOSINTCFG),
    .RXOSINTID0                     (RXOSINTID0),
    .TX8B10BBYPASS                  (TX8B10BBYPASS),
    .TXCHARDISPMODE                 (TXCHARDISPMODE),
    .TXCHARDISPVAL                  (TXCHARDISPVAL),
    .TXCHARISK                      (TXCHARISK),
    .TXDIFFCTRL                     (TXDIFFCTRL),
    .TXPIPPMSTEPSIZE                (TXPIPPMSTEPSIZE),
    .TXPOSTCURSOR                   (TXPOSTCURSOR),
    .TXPRECURSOR                    (TXPRECURSOR),
    .TXMAINCURSOR                   (TXMAINCURSOR),
    .TXSEQUENCE                     (TXSEQUENCE),
    .DRPADDR                        (DRPADDR)
  );
endmodule
