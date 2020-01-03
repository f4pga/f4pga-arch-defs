`include "../../primitives/ff/ff.sim.v"
`include "../../primitives/mux/mux.sim.v"
`include "../../primitives/inv/inv.sim.v"

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

    localparam QCSK = 1'b1;

    wire ta, ta_i0, ta_i1;
    wire tb, tb_i0, tb_i1;

    INV ta_i0_inv(TA1, ta_i0);
    INV ta_i1_inv(TA2, ta_i1);

    INV tb_i0_inv(TA1, tb_i0);
    INV tb_i1_inv(TA2, tb_i1);

    MUX ta_mux(ta_i0, ta_i1, TSL, ta);
    MUX tb_mux(tb_i0, tb_i1, TSL, tb);

    wire tab;
    MUX tab_mux(ta, tb, TAB, tab);

    assign TZ = tab;

    wire ba, ba_i0, ba_i1;
    wire bb, bb_i0, bb_i1;

    INV ba_i0_inv(BA1, ba_i0);
    INV ba_i1_inv(BA2, ba_i1);

    INV bb_i0_inv(BA1, bb_i0);
    INV bb_i1_inv(BA2, bb_i1);

    MUX ba_mux(ba_i0, ba_i1, BSL, ba);
    MUX bb_mux(bb_i0, bb_i1, BSL, bb);

    wire bab;
    MUX bab_mux(ba, bb, BAB, bab);

    wire tabbab;
    MUX tabbab_mux(tab, bab, TBS, tabbab);
    assign CZ = tabbab;

    wire d;
    MUX d_mux(tabbab, QDI, QDS, d);

    FF ff(QCSK ? QCK : ~QCK, d, QST, QRT, QEN, QZ);

    MUX f_mux(F1, F2, FS, FZ);
endmodule
