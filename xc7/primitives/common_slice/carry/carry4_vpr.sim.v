(*blackbox*)
module CARRY4_VPR(O, CO_CHAIN, CO_FABRIC, CYINIT, CIN, DI, S);
  parameter CYINIT_AX = 1'b0;
  parameter CYINIT_C0 = 1'b0;
  parameter CYINIT_C1 = 1'b0;

  (* DELAY_MATRIX_CYINIT="10e-12 10e-12 10e-12 10e-12" *)
  (* DELAY_MATRIX_CIN="10e-12 10e-12 10e-12 10e-12" *)
  (* DELAY_MATRIX_S="10e-12 10e-12 10e-12 10e-12;10e-12 10e-12 10e-12 10e-12;10e-12 10e-12 10e-12 10e-12;10e-12 10e-12 10e-12 10e-12" *)
  (* DELAY_MATRIX_DI="10e-12 10e-12 10e-12 10e-12;10e-12 10e-12 10e-12 10e-12;10e-12 10e-12 10e-12 10e-12;10e-12 10e-12 10e-12 10e-12" *)
  output wire [3:0] O;

  (* DELAY_MATRIX_CYINIT="10e-12 10e-12 10e-12 10e-12" *)
  (* DELAY_MATRIX_CIN="10e-12 10e-12 10e-12 10e-12" *)
  (* DELAY_MATRIX_S="10e-12 10e-12 10e-12 10e-12;10e-12 10e-12 10e-12 10e-12;10e-12 10e-12 10e-12 10e-12;10e-12 10e-12 10e-12 10e-12" *)
  (* DELAY_MATRIX_DI="10e-12 10e-12 10e-12 10e-12;10e-12 10e-12 10e-12 10e-12;10e-12 10e-12 10e-12 10e-12;10e-12 10e-12 10e-12 10e-12" *)
  output wire [3:0] CO_FABRIC;

  (* DELAY_CONST_CYINIT="10e-12" *)
  (* DELAY_CONST_CIN="10e-12" *)
  (* DELAY_MATRIX_DI="10e-12 10e-12 10e-12 10e-12" *)
  (* DELAY_MATRIX_S="10e-12 10e-12 10e-12 10e-12" *)
  output wire CO_CHAIN;

  input wire [3:0] DI;
  input wire [3:0] S;

  input wire CYINIT;
  input wire CIN;

  wire [4:0] CI;

  wire CI_COMBINE;
  if(CYINIT_AX) begin
    assign CI_COMBINE = CI_INIT;
  end else if(CYINIT_C0) begin
    assign CI_COMBINE = 0;
  end else if(CYINIT_C1) begin
    assign CI_COMBINE = 1;
  end else begin
    assign CI_COMBINE = CI;
  end

  assign CI[0] = (CYINIT & CYINIT_AX) | CYINIT_C1 | (CIN & (!CYINIT_AX && !CYINIT_C0 && !CYINIT_C1));

  genvar i;
  generate for (i = 0; i < 4; i = i + 1) begin:carry
    assign CI[i+1] = S[i] ? CI[i] : DI[i];
    assign CO_FABRIC[i] = CI[i+1];
    assign O[i] = CI[i] ^ S[i];
  end endgenerate

  assign CO_CHAIN = CO_FABRIC[3];
endmodule
