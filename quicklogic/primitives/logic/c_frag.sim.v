`include "./t_frag.sim.v"
`include "./b_frag.sim.v"

module C_FRAG (TBS, TAB, TSL, TA1, TA2, TB1, TB2, BAB, BSL, BA1, BA2, BB1, BB2, TZ, CZ);

    // Routing ports
    input  wire TBS;

    input  wire TAB;
    input  wire TSL;
    input  wire TA1;
    input  wire TA2;
    input  wire TB1;
    input  wire TB2;

    input  wire BAB;
    input  wire BSL;
    input  wire BA1;
    input  wire BA2;
    input  wire BB1;
    input  wire BB2;

    output wire TZ;
    output wire CZ;

    // The top part a.k.a. T_FRAG
    T_FRAG t_frag (
        .TBS(TBS),
        .XAB(TAB),
        .XSL(TSL),
        .XA1(TA1),
        .XA2(TA2),
        .XB1(TB1),
        .XB2(TB2),
        .XZ (TZ)
    );

    // The bottom part a.k.a. B_FRAG
    B_FRAG b_frag (
        .TBS(TBS),
        .XAB(BAB),
        .XSL(BSL),
        .XA1(BA1),
        .XA2(BA2),
        .XB1(BB1),
        .XB2(BB2),
        .XZ (CZ)
    );

endmodule
