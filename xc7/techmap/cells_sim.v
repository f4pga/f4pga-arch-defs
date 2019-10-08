// ============================================================================
// Define FFs required by VPR
//
module CE_VCC (output VCC);
wire VCC = 1;
endmodule

module SR_GND (output GND);
wire GND = 0;
endmodule

module FDRE_ZINI (output reg Q, input C, CE, D, R);
  parameter [0:0] ZINI = 1'b0;
  parameter [0:0] IS_C_INVERTED = 1'b0;
  initial Q <= !ZINI;
  generate case (|IS_C_INVERTED)
    1'b0: always @(posedge C) if (R) Q <= 1'b0; else if (CE) Q <= D;
    1'b1: always @(negedge C) if (R) Q <= 1'b0; else if (CE) Q <= D;
  endcase endgenerate
endmodule

module FDSE_ZINI (output reg Q, input C, CE, D, S);
  parameter [0:0] ZINI = 1'b0;
  parameter [0:0] IS_C_INVERTED = 1'b0;
  initial Q <= !ZINI;
  generate case (|IS_C_INVERTED)
    1'b0: always @(posedge C) if (S) Q <= 1'b1; else if (CE) Q <= D;
    1'b1: always @(negedge C) if (S) Q <= 1'b1; else if (CE) Q <= D;
  endcase endgenerate
endmodule

module FDCE_ZINI (output reg Q, input C, CE, D, CLR);
  parameter [0:0] ZINI = 1'b0;
  parameter [0:0] IS_C_INVERTED = 1'b0;
  initial Q <= !ZINI;
  generate case (|IS_C_INVERTED)
    1'b0: always @(posedge C, posedge CLR) if (CLR) Q <= 1'b0; else if (CE) Q <= D;
    1'b1: always @(negedge C, posedge CLR) if (CLR) Q <= 1'b0; else if (CE) Q <= D;
  endcase endgenerate
endmodule

module FDPE_ZINI (output reg Q, input C, CE, D, PRE);
  parameter [0:0] ZINI = 1'b0;
  parameter [0:0] IS_C_INVERTED = 1'b0;
  initial Q <= !ZINI;
  generate case (|IS_C_INVERTED)
    1'b0: always @(posedge C, posedge PRE) if (PRE) Q <= 1'b1; else if (CE) Q <= D;
    1'b1: always @(negedge C, posedge PRE) if (PRE) Q <= 1'b1; else if (CE) Q <= D;
  endcase endgenerate
endmodule

// ============================================================================
// LUT related muxes

module MUXF6(output O, input I0, I1, S);
  assign O = S ? I1 : I0;
endmodule

// ============================================================================
// Carry chain primitives

module CARRY4_VPR(O0, O1, O2, O3, CO_CHAIN, CO_FABRIC0, CO_FABRIC1, CO_FABRIC2, CO_FABRIC3, CYINIT, CIN, DI0, DI1, DI2, DI3, S0, S1, S2, S3);
  parameter CYINIT_AX = 1'b0;
  parameter CYINIT_C0 = 1'b0;
  parameter CYINIT_C1 = 1'b0;

  (* DELAY_CONST_CYINIT="0.491e-9" *)
  (* DELAY_CONST_CIN="0.235e-9" *)
  (* DELAY_CONST_S0="0.223e-9" *)
  output wire O0;

  (* DELAY_CONST_CYINIT="0.613e-9" *)
  (* DELAY_CONST_CIN="0.348e-9" *)
  (* DELAY_CONST_S0="0.400e-9" *)
  (* DELAY_CONST_S1="0.205e-9" *)
  (* DELAY_CONST_DI0="0.337e-9" *)
  output wire O1;

  (* DELAY_CONST_CYINIT="0.600e-9" *)
  (* DELAY_CONST_CIN="0.256e-9" *)
  (* DELAY_CONST_S0="0.523e-9" *)
  (* DELAY_CONST_S1="0.558e-9" *)
  (* DELAY_CONST_S2="0.226e-9" *)
  (* DELAY_CONST_DI0="0.486e-9" *)
  (* DELAY_CONST_DI1="0.471e-9" *)
  output wire O2;

  (* DELAY_CONST_CYINIT="0.657e-9" *)
  (* DELAY_CONST_CIN="0.329e-9" *)
  (* DELAY_CONST_S0="0.582e-9" *)
  (* DELAY_CONST_S1="0.618e-9" *)
  (* DELAY_CONST_S2="0.330e-9" *)
  (* DELAY_CONST_S3="0.227e-9" *)
  (* DELAY_CONST_DI0="0.545e-9" *)
  (* DELAY_CONST_DI1="0.532e-9" *)
  (* DELAY_CONST_DI2="0.372e-9" *)
  output wire O3;

  (* DELAY_CONST_CYINIT="0.578e-9" *)
  (* DELAY_CONST_CIN="0.293e-9" *)
  (* DELAY_CONST_S0="0.340e-9" *)
  (* DELAY_CONST_DI0="0.329e-9" *)
  output wire CO_FABRIC0;

  (* DELAY_CONST_CYINIT="0.529e-9" *)
  (* DELAY_CONST_CIN="0.178e-9" *)
  (* DELAY_CONST_S0="0.433e-9" *)
  (* DELAY_CONST_S1="0.469e-9" *)
  (* DELAY_CONST_DI0="0.396e-9" *)
  (* DELAY_CONST_DI1="0.376e-9" *)
  output wire CO_FABRIC1;

  (* DELAY_CONST_CYINIT="0.617e-9" *)
  (* DELAY_CONST_CIN="0.250e-9" *)
  (* DELAY_CONST_S0="0.512e-9" *)
  (* DELAY_CONST_S1="0.548e-9" *)
  (* DELAY_CONST_S2="0.292e-9" *)
  (* DELAY_CONST_DI0="0.474e-9" *)
  (* DELAY_CONST_DI1="0.459e-9" *)
  (* DELAY_CONST_DI2="0.289e-9" *)
  output wire CO_FABRIC2;

  (* DELAY_CONST_CYINIT="0.580e-9" *)
  (* DELAY_CONST_CIN="0.114e-9" *)
  (* DELAY_CONST_S0="0.508e-9" *)
  (* DELAY_CONST_S1="0.528e-9" *)
  (* DELAY_CONST_S2="0.376e-9" *)
  (* DELAY_CONST_S3="0.380e-9" *)
  (* DELAY_CONST_DI0="0.456e-9" *)
  (* DELAY_CONST_DI1="0.443e-9" *)
  (* DELAY_CONST_DI2="0.324e-9" *)
  (* DELAY_CONST_DI3="0.327e-9" *)
  output wire CO_FABRIC3;

  (* DELAY_CONST_CYINIT="0.580e-9" *)
  (* DELAY_CONST_CIN="0.114e-9" *)
  (* DELAY_CONST_S0="0.508e-9" *)
  (* DELAY_CONST_S1="0.528e-9" *)
  (* DELAY_CONST_S2="0.376e-9" *)
  (* DELAY_CONST_S3="0.380e-9" *)
  (* DELAY_CONST_DI0="0.456e-9" *)
  (* DELAY_CONST_DI1="0.443e-9" *)
  (* DELAY_CONST_DI2="0.324e-9" *)
  (* DELAY_CONST_DI3="0.327e-9" *)
  output wire CO_CHAIN;

  input wire DI0, DI1, DI2, DI3;
  input wire S0, S1, S2, S3;

  input wire CYINIT;
  input wire CIN;

  wire CI0;
  wire CI1;
  wire CI2;
  wire CI3;
  wire CI4;

  assign CI0 = CYINIT_AX ? CYINIT :
               CYINIT_C1 ? 1'b1 :
               CYINIT_C0 ? 1'b0 :
               CIN;
  assign CI1 = S0 ? CI0 : DI0;
  assign CI2 = S1 ? CI1 : DI1;
  assign CI3 = S2 ? CI2 : DI2;
  assign CI4 = S3 ? CI3 : DI3;

  assign CO_FABRIC0 = CI1;
  assign CO_FABRIC1 = CI2;
  assign CO_FABRIC2 = CI3;
  assign CO_FABRIC3 = CI4;

  assign O0 = CI0 ^ S0;
  assign O1 = CI1 ^ S1;
  assign O2 = CI2 ^ S2;
  assign O3 = CI3 ^ S3;

  assign CO_CHAIN = CO_FABRIC3;
endmodule

// ============================================================================
// Distributed RAMs

module DPRAM64_for_RAM128X1D (
  output O,
  input  DI, CLK, WE, WA7,
  input [5:0] A, WA
);
  parameter [63:0] INIT = 64'h0;
  parameter IS_WCLK_INVERTED = 1'b0;
  parameter HIGH_WA7_SELECT = 1'b0;
  wire [5:0] A;
  wire [5:0] WA;
  reg [63:0] mem;
  initial mem <= INIT;
  assign O = mem[A];
  wire clk = CLK ^ IS_WCLK_INVERTED;
  always @(posedge clk) if (WE & (WA7 == HIGH_WA7_SELECT)) mem[WA] <= DI;
endmodule

module DPRAM64 (
  output O,
  input  DI, CLK, WE, WA7, WA8,
  input [5:0] A, WA
);
  parameter [63:0] INIT = 64'h0;
  parameter IS_WCLK_INVERTED = 1'b0;
  parameter WA7USED = 1'b0;
  parameter WA8USED = 1'b0;
  parameter HIGH_WA7_SELECT = 1'b0;
  parameter HIGH_WA8_SELECT = 1'b0;
  wire [5:0] A;
  wire [5:0] WA;
  reg [63:0] mem;
  initial mem <= INIT;
  assign O = mem[A];
  wire clk = CLK ^ IS_WCLK_INVERTED;

  wire WA7SELECT = !WA7USED | (WA7 == HIGH_WA7_SELECT);
  wire WA8SELECT = !WA8USED | (WA8 == HIGH_WA8_SELECT);
  wire address_selected = WA7SELECT & WA8SELECT;
  always @(posedge clk) if (WE & address_selected) mem[WA] <= DI;
endmodule

module DPRAM32 (
  output O,
  input  DI, CLK, WE,
  input [4:0] A, WA
);
  parameter [31:0] INIT_00 = 32'h0;
  parameter IS_WCLK_INVERTED = 1'b0;
  wire [4:0] A;
  wire [4:0] WA;
  reg [31:0] mem;
  initial mem <= INIT_00;
  assign O = mem[A];
  wire clk = CLK ^ IS_WCLK_INVERTED;
  always @(posedge clk) if (WE) begin
    mem[WA] <= DI;
  end
endmodule


// To ensure that all DRAMs are co-located within a SLICEM, this block is
// a simple passthrough black box to allow a pack pattern for dual port DRAMs.
module DRAM_2_OUTPUT_STUB(
    input SPO, DPO,
    output SPO_OUT, DPO_OUT
);
  wire SPO_OUT;
  wire DPO_OUT;
  assign SPO_OUT = SPO;
  assign DPO_OUT = DPO;
endmodule

module DRAM_4_OUTPUT_STUB(
    input DOA, DOB, DOC, DOD,
    output DOA_OUT, DOB_OUT, DOC_OUT, DOD_OUT
);
  assign DOA_OUT = DOA;
  assign DOB_OUT = DOB;
  assign DOC_OUT = DOC;
  assign DOD_OUT = DOD;
endmodule

module DRAM_8_OUTPUT_STUB(
    input DOA1, DOB1, DOC1, DOD1, DOA0, DOB0, DOC0, DOD0,
    output DOA1_OUT, DOB1_OUT, DOC1_OUT, DOD1_OUT, DOA0_OUT, DOB0_OUT, DOC0_OUT, DOD0_OUT
);
  assign DOA1_OUT = DOA1;
  assign DOB1_OUT = DOB1;
  assign DOC1_OUT = DOC1;
  assign DOD1_OUT = DOD1;
  assign DOA0_OUT = DOA0;
  assign DOB0_OUT = DOB0;
  assign DOC0_OUT = DOC0;
  assign DOD0_OUT = DOD0;
endmodule

// ============================================================================
// Block RAMs

module RAMB18E1_VPR (
	input CLKARDCLK,
	input CLKBWRCLK,
	input ENARDEN,
	input ENBWREN,
	input REGCLKARDRCLK,
	input REGCEAREGCE,
	input REGCEB,
	input REGCLKB,
	input RSTRAMARSTRAM,
	input RSTRAMB,
	input RSTREGARSTREG,
	input RSTREGB,

	input [1:0]  ADDRBTIEHIGH,
	input [13:0] ADDRBWRADDR,
	input [1:0]  ADDRATIEHIGH,
	input [13:0] ADDRARDADDR,
	input [15:0] DIADI,
	input [15:0] DIBDI,
	input [1:0] DIPADIP,
	input [1:0] DIPBDIP,
	input [3:0] WEA,
	input [7:0] WEBWE,

	output [15:0] DOADO,
	output [15:0] DOBDO,
	output [1:0] DOPADOP,
	output [1:0] DOPBDOP
);
	parameter IN_USE = 1'b0;

	parameter ZINIT_A = 18'h0;
	parameter ZINIT_B = 18'h0;

	parameter ZSRVAL_A = 18'h0;
	parameter ZSRVAL_B = 18'h0;

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

	parameter ZINV_CLKARDCLK = 1'b1;
	parameter ZINV_CLKBWRCLK = 1'b1;
	parameter ZINV_ENARDEN = 1'b1;
	parameter ZINV_ENBWREN = 1'b1;
	parameter ZINV_RSTRAMARSTRAM = 1'b1;
	parameter ZINV_RSTRAMB = 1'b1;
	parameter ZINV_RSTREGARSTREG = 1'b1;
	parameter ZINV_RSTREGB = 1'b1;
	parameter ZINV_REGCLKARDRCLK = 1'b1;
	parameter ZINV_REGCLKB = 1'b1;

	parameter DOA_REG = 1'b0;
	parameter DOB_REG = 1'b0;

	parameter integer SDP_READ_WIDTH_36 = 1'b0;
	parameter integer READ_WIDTH_A_18 = 1'b0;
	parameter integer READ_WIDTH_A_9 = 1'b0;
	parameter integer READ_WIDTH_A_4 = 1'b0;
	parameter integer READ_WIDTH_A_2 = 1'b0;
	parameter integer READ_WIDTH_A_1 = 1'b1;
	parameter integer READ_WIDTH_B_18 = 1'b0;
	parameter integer READ_WIDTH_B_9 = 1'b0;
	parameter integer READ_WIDTH_B_4 = 1'b0;
	parameter integer READ_WIDTH_B_2 = 1'b0;
	parameter integer READ_WIDTH_B_1 = 1'b1;

	parameter integer SDP_WRITE_WIDTH_36 = 1'b0;
	parameter integer WRITE_WIDTH_A_18 = 1'b0;
	parameter integer WRITE_WIDTH_A_9 = 1'b0;
	parameter integer WRITE_WIDTH_A_4 = 1'b0;
	parameter integer WRITE_WIDTH_A_2 = 1'b0;
	parameter integer WRITE_WIDTH_A_1 = 1'b1;
	parameter integer WRITE_WIDTH_B_18 = 1'b0;
	parameter integer WRITE_WIDTH_B_9 = 1'b0;
	parameter integer WRITE_WIDTH_B_4 = 1'b0;
	parameter integer WRITE_WIDTH_B_2 = 1'b0;
	parameter integer WRITE_WIDTH_B_1 = 1'b1;

	parameter WRITE_MODE_A_NO_CHANGE = 1'b0;
	parameter WRITE_MODE_A_READ_FIRST = 1'b0;
	parameter WRITE_MODE_B_NO_CHANGE = 1'b0;
	parameter WRITE_MODE_B_READ_FIRST = 1'b0;
endmodule

module RAMB36E1_PRIM (
        input CLKARDCLKU,           input CLKARDCLKL,
        input CLKBWRCLKU,           input CLKBWRCLKL,
        input ENARDENU,             input ENARDENL,
        input ENBWRENU,             input ENBWRENL,
        input REGCLKARDRCLKU,       input REGCLKARDRCLKL,
        input REGCEAREGCEU,         input REGCEAREGCEL,
        input REGCEBU,              input REGCEBL,
        input REGCLKBU,             input REGCLKBK,
        input RSTRAMARSTRAMU,       input RSTRAMARSTRAMLRST,
        input RSTRAMBU,             input RSTRAMBL,
        input RSTREGARSTREGU,       input RSTREGARSTREGL,
        input RSTREGBU,             input RSTREGBL,

        input [14:0] ADDRBWRADDRU,  input [15:0] ADDRBWRADDRL,
        input [14:0] ADDRARDADDRU,  input [15:0] ADDRARDADDRL,
        input [31:0] DIADI,
        input [31:0] DIBDI,
        input [3:0] DIPADIP,
        input [3:0] DIPBDIP,
        input [3:0] WEAU,           input [3:0] WEAL,
        input [7:0] WEBWEU,         input [7:0] WEBWEL,

        output [31:0] DOADO,
        output [31:0] DOBDO,
        output [3:0] DOPADOP,
        output [3:0] DOPBDOP
);
        parameter IN_USE = 1'b0;

        parameter ZINIT_A = 36'h0;
        parameter ZINIT_B = 36'h0;

        parameter ZSRVAL_A = 36'h0;
        parameter ZSRVAL_B = 36'h0;

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
        `INIT_BLOCK(INIT_1);
        `INIT_BLOCK(INIT_2);
        `INIT_BLOCK(INIT_3);
        `INIT_BLOCK(INIT_4);
        `INIT_BLOCK(INIT_5);
        `INIT_BLOCK(INIT_6);
        `INIT_BLOCK(INIT_7);
        `undef INIT_BLOCK

        parameter ZINV_CLKARDCLK = 1'b1;
        parameter ZINV_CLKBWRCLK = 1'b1;
        parameter ZINV_ENARDEN = 1'b1;
        parameter ZINV_ENBWREN = 1'b1;
        parameter ZINV_RSTRAMARSTRAM = 1'b1;
        parameter ZINV_RSTRAMB = 1'b1;
        parameter ZINV_RSTREGARSTREG = 1'b1;
        parameter ZINV_RSTREGB = 1'b1;
        parameter ZINV_REGCLKARDRCLK = 1'b1;
        parameter ZINV_REGCLKB = 1'b1;

        parameter DOA_REG = 1'b0;
        parameter DOB_REG = 1'b0;

        parameter integer SDP_READ_WIDTH_72 = 1'b0;
        parameter integer READ_WIDTH_A_36 = 1'b0;
        parameter integer READ_WIDTH_A_18 = 1'b0;
        parameter integer READ_WIDTH_A_9 = 1'b0;
        parameter integer READ_WIDTH_A_4 = 1'b0;
        parameter integer READ_WIDTH_A_2 = 1'b0;
        parameter integer READ_WIDTH_A_1 = 1'b1;
        parameter integer READ_WIDTH_B_18 = 1'b0;
        parameter integer READ_WIDTH_B_9 = 1'b0;
        parameter integer READ_WIDTH_B_4 = 1'b0;
        parameter integer READ_WIDTH_B_2 = 1'b0;
        parameter integer READ_WIDTH_B_1 = 1'b1;

        parameter integer SDP_WRITE_WIDTH_72 = 1'b0;
        parameter integer WRITE_WIDTH_A_36 = 1'b0;
        parameter integer WRITE_WIDTH_A_18 = 1'b0;
        parameter integer WRITE_WIDTH_A_9 = 1'b0;
        parameter integer WRITE_WIDTH_A_4 = 1'b0;
        parameter integer WRITE_WIDTH_A_2 = 1'b0;
        parameter integer WRITE_WIDTH_A_1 = 1'b1;
        parameter integer WRITE_WIDTH_B_18 = 1'b0;
        parameter integer WRITE_WIDTH_B_9 = 1'b0;
        parameter integer WRITE_WIDTH_B_4 = 1'b0;
        parameter integer WRITE_WIDTH_B_2 = 1'b0;
        parameter integer WRITE_WIDTH_B_1 = 1'b1;

        parameter WRITE_MODE_A_NO_CHANGE = 1'b0;
        parameter WRITE_MODE_A_READ_FIRST = 1'b0;
        parameter WRITE_MODE_B_NO_CHANGE = 1'b0;
        parameter WRITE_MODE_B_READ_FIRST = 1'b0;
endmodule

// ============================================================================
// SRLs

// SRLC32E_VPR
module SRLC32E_VPR
(
input CLK, CE, D,
input [4:0] A,
output Q, Q31
);
  parameter [64:0] INIT = 64'd0;
  parameter [0:0] IS_CLK_INVERTED = 1'b0;

  reg [31:0] r;
  integer i;

  initial for (i=0; i<32; i=i+1)
    r[i] <= INIT[2*i];

  assign Q31 = r[31];
  assign Q = r[A];

  generate begin
    if (IS_CLK_INVERTED) begin
      always @(negedge CLK) if (CE) r <= { r[30:0], D };
    end else begin
      always @(posedge CLK) if (CE) r <= { r[30:0], D };
    end
  end endgenerate

endmodule

// SRLC16E_VPR
module SRLC16E_VPR
(
input CLK, CE, D,
input A0, A1, A2, A3,
output Q, Q15
);
  parameter [15:0] INIT = 16'd0;
  parameter [0:0] IS_CLK_INVERTED = 1'b0;

  reg [15:0] r = INIT;

  assign Q15 = r[15];
  assign Q = r[{A3,A2,A1,A0}];

  generate
    if (IS_CLK_INVERTED) begin
      always @(negedge CLK) if (CE) r <= { r[14:0], D };
    end else begin
      always @(posedge CLK) if (CE) r <= { r[14:0], D };
    end
  endgenerate

endmodule

// ============================================================================
// IO

module INBUF_VPR (
	input PAD,
	output OUT
);
	assign OUT = PAD;
endmodule

module OUTBUF_VPR (
	input IN,
	output OUT
);
	assign OUT = IN;
endmodule

// ============================================================================
// Clock Buffers

// BUFGCTRL_VPR
module BUFGCTRL_VPR
(
output O,
input I0, input I1,
input S0, input S1,
input CE0, input CE1,
input IGNORE0, input IGNORE1
);

  parameter INIT_OUT = 1'b0;
  parameter ZPRESELECT_I0 = "FALSE";
  parameter ZPRESELECT_I1 = "FALSE";
  parameter ZINV_CE0 = 1'b0;
  parameter ZINV_CE1 = 1'b0;
  parameter ZINV_S0 = 1'b0;
  parameter ZINV_S1 = 1'b0;
  parameter IS_IGNORE0_INVERTED = 1'b0;
  parameter IS_IGNORE1_INVERTED = 1'b0;

  wire I0_internal = ((CE0 ^ ZINV_CE0) ? I0 : INIT_OUT);
  wire I1_internal = ((CE1 ^ ZINV_CE1) ? I1 : INIT_OUT);
  wire S0_true = (S0 ^ ZINV_S0);
  wire S1_true = (S1 ^ ZINV_S1);

  assign O = S0_true ? I0_internal : (S1_true ? I1_internal : INIT_OUT);

endmodule

// BUFHCE_VPR
module BUFHCE_VPR
(
output O,
input I,
input CE
);

  parameter [0:0] INIT_OUT = 1'b0;
  parameter CE_TYPE = "SYNC";
  parameter [0:0] IS_CE_INVERTED = 1'b0;

  wire I = ((CE ^ IS_CE_INVERTED) ? I : INIT_OUT);

  assign O = I;

endmodule
