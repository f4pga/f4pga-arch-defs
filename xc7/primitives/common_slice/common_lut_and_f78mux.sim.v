`include "Nlut/alut.sim.v"
`include "Nlut/blut.sim.v"
`include "Nlut/clut.sim.v"
`include "Nlut/dlut.sim.v"
`include "muxes/f7amux/f7amux.sim.v"
`include "muxes/f7bmux/f7bmux.sim.v"
`include "muxes/f8mux/f8mux.sim.v"

module COMMON_LUT_AND_F78MUX(
        D1, D2, D3, D4, D5, D6,	    // D port
        CX, C1, C2, C3, C4, C5, C6, // C port
        BX, B1, B2, B3, B4, B5, B6, // B port
        AX, A1, A2, A3, A4, A5, A6, // A port
        DO5, CO5, BO5, AO5,         // LUT outputs
        DO6, CO6, BO6, AO6,         // LUT outputs
        F7AMUX_O, F7BMUX_O, F8MUX_O // Muxes outputs
);

  input wire D1;
  input wire D2;
  input wire D3;
  input wire D4;
  input wire D5;
  input wire D6;

  input wire CX;
  input wire C1;
  input wire C2;
  input wire C3;
  input wire C4;
  input wire C5;
  input wire C6;

  input wire BX;
  input wire B1;
  input wire B2;
  input wire B3;
  input wire B4;
  input wire B5;
  input wire B6;

  input wire AX;
  input wire A1;
  input wire A2;
  input wire A3;
  input wire A4;
  input wire A5;
  input wire A6;

  output wire DO6;
  output wire CO6;
  output wire BO6;
  output wire AO6;

  output wire DO5;
  output wire CO5;
  output wire BO5;
  output wire AO5;

  output wire F7AMUX_O;
  output wire F7BMUX_O;
  output wire F8MUX_O;

  wire alut_O5;
  wire alut_O6;
  wire blut_O5;
  wire blut_O6;
  wire clut_O5;
  wire clut_O6;
  wire dlut_O5;
  wire dlut_O6;

  wire f7_amux_o;
  wire f7_bmux_o;

  assign AO5 = alut_O5;
  assign AO6 = alut_O6;
  assign BO5 = blut_O5;
  assign BO6 = blut_O6;
  assign CO5 = clut_O5;
  assign CO6 = clut_O6;
  assign DO5 = dlut_O5;
  assign DO6 = dlut_O6;

  assign F7AMUX_O = f7_amux_o;
  assign F7BMUX_O = f7_bmux_o;
  ALUT a_lut(
            .A1(A1),
            .A2(A2),
            .A3(A3),
            .A4(A4),
            .A5(A5),
            .A6(A6),
            .O5(alut_O5),
            .O6(alut_O6),
          );

  BLUT b_lut(
            .A1(B1),
            .A2(B2),
            .A3(B3),
            .A4(B4),
            .A5(B5),
            .A6(B6),
            .O5(blut_O5),
            .O6(blut_O6),
          );

  CLUT c_lut(
            .A1(C1),
            .A2(C2),
            .A3(C3),
            .A4(C4),
            .A5(C5),
            .A6(C6),
            .O5(clut_O5),
            .O6(clut_O6),
          );

  DLUT d_lut(
            .A1(D1),
            .A2(D2),
            .A3(D3),
            .A4(D4),
            .A5(D5),
            .A6(D6),
            .O5(dlut_O5),
            .O6(dlut_O6),
          );
  F7AMUX f7_amux (
            .I0(blut_O6),
            .I1(alut_O6),
            .S(AX),
            .O(f7_amux_o)
          );
  F7BMUX f7_bmux (
            .I0(dlut_O6),
            .I1(clut_O6),
            .S(BX),
            .O(f7_bmux_o)
          );
  F8MUX f8_mux (
            .I0(f7_amux_o),
            .I1(f7_bmux_o),
            .S(CX),
            .O(F8MUX_O)
          );

endmodule
