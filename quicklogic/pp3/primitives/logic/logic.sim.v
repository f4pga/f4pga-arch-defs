`include "./c_frag_modes.sim.v"
`include "./f_frag.sim.v"
`include "./q_frag.sim.v"

(* FASM_FEATURES="LOGIC.LOGIC.Ipwr_gates.J_pwr_st" *)
module LOGIC (QST, QDS, TBS, TAB, TSL, TA1, TA2, TB1, TB2, BAB, BSL, BA1, BA2, BB1, BB2, QDI, QEN, QCK, QRT, F1, F2, FS, TZ, CZ, QZ, FZ);
    input wire QST;
    input wire QDS;
    input wire TBS;
    input wire TAB;
    input wire TSL;
    input wire TA1;
    input wire TA2;
    input wire TB1;
    input wire TB2;
    input wire BAB;
    input wire BSL;
    input wire BA1;
    input wire BA2;
    input wire BB1;
    input wire BB2;
    input wire QDI;
    input wire QEN;
    (* CLOCK *)
    input wire QCK;
    input wire QRT;
    input wire F1;
    input wire F2;
    input wire FS;
    output wire TZ;
    output wire CZ;
    output wire QZ;
    output wire FZ;

    // The C-Frag (with modes)
    (* FASM_PREFIX="LOGIC.LOGIC" *)
    C_FRAG_MODES c_frag_modes (
    .TBS(TBS),
    .TAB(TAB),
    .TSL(TSL),
    .TA1(TA1),
    .TA2(TA2),
    .TB1(TB1),
    .TB2(TB2),
    .BAB(BAB),
    .BSL(BSL),
    .BA1(BA1),
    .BA2(BA2),
    .BB1(BB1),
    .BB2(BB2),
    .TZ (TZ),
    .CZ (CZ)
    );

    // The Q-Frag
    (* FASM_PREFIX="LOGIC.LOGIC" *)
    Q_FRAG q_frag (
    .QCK(QCK),
    .QST(QST),
    .QRT(QRT),
    .QEN(QEN),
    .QDI(QDI),
    .QDS(QDS),
    .CZI(),     // FIXME: Deliberately disconnected
    .QZ (QZ)
    );

    // The F-Frag
    F_FRAG f_frag (
    .F1 (F1),
    .F2 (F2),
    .FS (FS),
    .FZ (FZ)
    );

endmodule
