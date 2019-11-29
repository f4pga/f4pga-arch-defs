`include "../../primitives/ff/ff.sim.v"
`include "../../primitives/mux/mux.sim.v"
(* whitebox *)
module CELL (QST, QDS, TBS, TAB, TSL, TA1, TA2, TB1, TB2, BAB, BSL, BA1, BA2, BB1, BB2, QDI, QEN, QCK, QRT, F1, F2, FS, TZ, CZ, QZ, FZ);
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

    wire ta;
    wire tb;
    MUX ta_mux(TA1, TA2, TSL, ta);
    MUX tb_mux(TB1, TB2, TSL, tb);
    wire tab;
    MUX tab_mux(ta, tb, TAB, tab);

    assign TZ = tab;

    wire ba;
    wire bb;
    MUX ba_mux(BA1, BA2, BSL, ba);
    MUX bb_mux(BB1, BB2, BSL, bb);
    wire bab;
    MUX bab_mux(ba, bb, BAB, bab);

    wire tabbab;
    MUX tabbab_mux(tab, bab, TBS, tabbab);
    assign CZ = tabbab;

    wire d;
    MUX d_mux(tabbab, QDI, QDS, d);

    FF ff(QCK, d, QST, QRT, QEN, QZ);

    MUX f_mux(F1, F2, FS, FZ);
endmodule
