(* FASM_PARAMS="ZINV.QCK=Z_QCKS" *)
(* whitebox *)
module Q_FRAG(QCK, QST, QRT, QEN, QDI, QDS, CZI, QZ);
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

	(* SETUP="QCK {setup_QCK_QDI}" *) (* NO_COMB *)
	(* HOLD="QCK {hold_QCK_QDI}" *) (* NO_COMB *)
    input  wire QDI;

	(* SETUP="QCK {setup_QCK_QDS}" *) (* NO_COMB *)
	(* HOLD="QCK {hold_QCK_QDS}" *) (* NO_COMB *)
    input  wire QDS;

    // There is no setup/hold for CZI -> QZ. Instead there are setup/hold
    // constraints for other LOGIC inputs. Use the same timing as for QDI
	(* SETUP="QCK {setup_QCK_QDI}" *) (* NO_COMB *)
	(* HOLD="QCK {hold_QCK_QDI}" *) (* NO_COMB *)
    input  wire CZI;

	(* CLK_TO_Q = "QCK {iopath_QCK_QZ}" *)
    output reg  QZ;

    // Parameters
    parameter [0:0] Z_QCKS = 1'b1; // FIXME: Make this parameter used by the FF behavioarl model below.

    // The "QDS" mux just before the flip-flop
    wire d = (QDS) ? QDI : CZI;

    // The flip-flop
    initial QZ <= 1'b0;
	always @(posedge QCK or posedge QST or posedge QRT) begin
		if (QST)
			QZ <= 1'b1;
		else if (QRT)
			QZ <= 1'b0;
		else if (QEN)
			QZ <= d;
	end

endmodule
