module CARRY4(
  output [3:0] CO,
  output [3:0] O,
  input        CI,
  input        CYINIT,
  input  [3:0] DI, S
);
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
  wire [3:0] O;
  wire [3:0] CO;
  wire [3:0] CO_output;

  // Put in a placeholder object CARRY_CO_DIRECT.
  //
  // It will be used for 3 purposes:
  //  - Remain as CARRY_CO_DIRECT when OUT only connects to CARRY_COUT_PLUG
  //  - Remain as CARRY_CO_DIRECT when CO is used, but O is not used.
  //  - Change into CARRY_CO_LUT when O and CO are required (e.g. compute CO
  //    from O ^ S).
  genvar i;
  generate for (i = 0; i < 3; i = i + 1) begin:co_outputs
      CARRY_CO_DIRECT #(.TOP_OF_CHAIN(0)) co_output(
          .CO(CO_output[i]),
          .O(O[i+1]),
          .S(S[i+1]),
          .OUT(CO[i])
      );
  end endgenerate

  CARRY_CO_DIRECT #(.TOP_OF_CHAIN(1)) co_output(
      .CO(CO_output[3]),
      .O(O[3]),
      .S(S[3]),
      .DI(DI[3]),
      .OUT(CO[3])
  );

  if(IS_CYINIT_FABRIC) begin
    CARRY4_VPR #(
        .CYINIT_AX(1'b1),
        .CYINIT_C0(1'b0),
        .CYINIT_C1(1'b0)
    ) _TECHMAP_REPLACE_ (
        .CO0(CO_output[0]),
        .CO1(CO_output[1]),
        .CO2(CO_output[2]),
        .CO3(CO_output[3]),
        .CYINIT(CYINIT),
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
  end else if(IS_CI_ZERO || IS_CI_ONE) begin
    CARRY4_VPR #(
        .CYINIT_AX(1'b0),
        .CYINIT_C0(IS_CI_ZERO),
        .CYINIT_C1(IS_CI_ONE)
    ) _TECHMAP_REPLACE_ (
        .CO0(CO_output[0]),
        .CO1(CO_output[1]),
        .CO2(CO_output[2]),
        .CO3(CO_output[3]),
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
    wire cin_from_below;
    CARRY_COUT_PLUG cin_plug(
        .CIN(CI),
        .COUT(cin_from_below)
    );

    CARRY4_VPR #(
        .CYINIT_AX(1'b0),
        .CYINIT_C0(1'b0),
        .CYINIT_C1(1'b0)
    ) _TECHMAP_REPLACE_ (
        .CO0(CO_output[0]),
        .CO1(CO_output[1]),
        .CO2(CO_output[2]),
        .CO3(CO_output[3]),
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
        .CIN(cin_from_below)
    );
  end
endmodule
