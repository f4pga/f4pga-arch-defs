`include "./c_frag.sim.v"
`include "./t_frag.sim.v"
`include "./b_frag.sim.v"

(* MODES="SINGLE;SPLIT" *)
module C_FRAG_MODES (TBS, TAB, TSL, TA1, TA2, TB1, TB2, BAB, BSL, BA1, BA2, BB1, BB2, TZ, CZ);

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

    parameter MODE = "SINGLE";

    // A single C_FRAG
    generate if (MODE == "SINGLE") begin

        (* pack="C_FRAG_to_FF" *)
        wire cz;

        C_FRAG c_frag (
            .TBS(TBS),
            .TAB(TAB),
            .TSL(TSL),
            .TA1(TA1),
            .TA2(TA2),
            .TB1(TB1),
            .TB2(TB2),
            .TZ (TZ),
            .BAB(BAB),
            .BSL(BSL),
            .BA1(BA1),
            .BA2(BA2),
            .BB1(BB1),
            .BB2(BB2),
            .CZ (cz)
        );

        assign CZ = cz;

    // A split C_FRAG consisting of a T_FRAG and a B_FRAG, both can host the
    // same cells.
    end else if (MODE == "SPLIT") begin

        (* pack="B_FRAG_to_FF" *)
        wire cz;

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
            .XZ (cz)
        );

        assign CZ = cz;

    end endgenerate

endmodule
