`include "./q_frag.sim.v"

(* MODES="INT;EXT" *)
module Q_FRAG_MODES (QCK, QST, QRT, QEN, QDI, QDS, CZI, QZ, FAKE_CONST);
    input  wire QCK;
    input  wire QST;
    input  wire QRT;
    input  wire QEN;
    input  wire QDI;
    input  wire QDS;
    input  wire CZI;
    output wire QZ;

    input  wire FAKE_CONST;

    parameter MODE = "INT";

    // Q_FRAG with the FF connected to CZI
    generate if (MODE == "INT") begin

        (* pack="C_FRAG_to_FF;B_FRAG_to_FF" *)
        wire   qd;
        assign qd = CZI;

        Q_FRAG q_frag (
            .QCK    (QCK),
            .QST    (QST),
            .QRT    (QRT),
            .QEN    (QEN),    
            .QZ     (QZ),
            .QD     (qd),
            .CONST0 (QDS),
            .CONST1 (FAKE_CONST)
        );

    // Q_FRAG with the FF connected to QDI (external)
    end else if (MODE == "EXT") begin

        Q_FRAG q_frag (
            .QCK    (QCK),
            .QST    (QST),
            .QRT    (QRT),
            .QEN    (QEN),    
            .QZ     (QZ),
            .QD     (QDI),
            .CONST0 (FAKE_CONST),
            .CONST1 (QDS)
        );

    end endgenerate

endmodule
