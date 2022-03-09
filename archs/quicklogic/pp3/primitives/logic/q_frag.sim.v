`timescale 1ns/10ps
(* FASM_PARAMS="ZINV.QCK=Z_QCKS" *)
(* whitebox *)
module Q_FRAG (QCK, QST, QRT, QEN, QZ, QD, CONST0, CONST1);
    (* CLOCK *)
    (* clkbuf_sink *)
    input  wire QCK;

    // Cannot model timing, VPR currently does not support async SET/RESET
    (* SETUP="QCK 1e-10" *) (* NO_COMB *)
    input  wire QST;

    // Cannot model timing, VPR currently does not support async SET/RESET
    (* SETUP="QCK 1e-10" *) (* NO_COMB *)
    input  wire QRT;

    // No timing for QEN -> QZ in LIB/SDF
    (* SETUP="QCK {setup_QCK_QEN}" *) (* NO_COMB *)
    (* HOLD="QCK {hold_QCK_QEN}" *) (* NO_COMB *)
    input  wire QEN;

    // QD can either go to CZI or QDI.
    // There is no setup/hold for CZI -> QZ. Instead there are setup/hold
    // constraints for other LOGIC inputs. Use the same timing as for QDI
    (* SETUP="QCK {setup_QCK_QDI}" *) (* NO_COMB *)
    (* HOLD="QCK {hold_QCK_QDI}" *) (* NO_COMB *)
    input  wire QD;

    // CONST0 and CONST1 are always connected to 0 and 1 respectively. Even
    // thouth they are routed through the QDS input of the LOGIC cell there
    // is no need for timing specification for them.
    (* NO_COMB *)
    input  wire CONST0;
    (* NO_COMB *)
    input  wire CONST1;

    // The output
    (* CLK_TO_Q = "QCK {iopath_QCK_QZ}" *)
    output reg  QZ;
    
    specify
        (QCK => QZ) = (0,0);
        $setup(QD, posedge QCK, "");
        $hold(posedge QCK, QD, "");
        $setup(QST, posedge QCK, "");
        $hold(posedge QCK, QST, "");
        $setup(QRT, posedge QCK, "");
        $hold(posedge QCK, QRT, "");
        $setup(QEN, posedge QCK, "");
        $hold(posedge QCK, QEN, "");
        $setup(CONST0, posedge QCK, "");
        $hold(posedge QCK, CONST0, "");
        $setup(CONST1, posedge QCK, "");
        $hold(posedge QCK, CONST1, "");
    endspecify

    // Parameters
    parameter [0:0] Z_QCKS = 1'b1;

    // The flip-flop model
    initial QZ <= 1'b0;

    generate if (Z_QCKS == 1'b1) begin
        always @(posedge QCK or posedge QST or posedge QRT) begin
            if (QST)
                QZ <= 1'b1;
            else if (QRT)
                QZ <= 1'b0;
            else if (QEN)
                QZ <= QD;
        end

    end else begin
        always @(negedge QCK or posedge QST or posedge QRT) begin
            if (QST)
                QZ <= 1'b1;
            else if (QRT)
                QZ <= 1'b0;
            else if (QEN)
                QZ <= QD;
        end

    end endgenerate

endmodule
