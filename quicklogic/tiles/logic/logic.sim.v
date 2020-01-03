`include "../../primitives/ff/ff.sim.v"
`include "../../primitives/mux/mux.sim.v"

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

    // routable="false"
    localparam TAS1 = 1'b0;
    localparam TAS2 = 1'b0;
    localparam TBS1 = 1'b0;
    localparam TBS2 = 1'b0;
    localparam BAS1 = 1'b0;
    localparam BAS2 = 1'b0;
    localparam BBS1 = 1'b0;
    localparam BBS2 = 1'b0;
    // unet="vcc"
    localparam QCSK = 1'b1;

    wire ta;
    wire tb;
    MUX ta_mux(TAS1 ? ~TA1 : TA1, TAS2 ? ~TA2 : TA2, TSL, ta);
    MUX tb_mux(TBS1 ? ~TB1 : TB1, TBS2 ? ~TB2 : TB2, TSL, tb);
    wire tab;
    MUX tab_mux(ta, tb, TAB, tab);

    assign TZ = tab;

    wire ba;
    wire bb;
    MUX ba_mux(BAS1 ? ~BA1 : BA1, BAS2 ? ~BA2 : BA2, BSL, ba);
    MUX bb_mux(BBS1 ? ~BB1 : BB1, BBS2 ? ~BB2 : BB2, BSL, bb);
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
