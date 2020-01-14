(* FASM_PARAMS="ZINV.QCK=Z_QCKS" *)
(* whitebox *)
module Q_FRAG(QCK, QST, QRT, QEN, QDI, QDS, CZI, QZ);
    (* CLOCK *)
    input  wire QCK;

	(* SETUP="QCK 1e-11" *) (* NO_COMB *)
    input  wire QST;
	(* SETUP="QCK 1e-11" *) (* NO_COMB *)
    input  wire QRT;
	(* SETUP="QCK 1e-11" *) (* NO_COMB *)
    input  wire QEN;
	(* SETUP="QCK 1e-11" *) (* NO_COMB *)
    input  wire QDI;
	(* SETUP="QCK 1e-11" *) (* NO_COMB *)
    input  wire QDS;
	(* SETUP="QCK 1e-11" *) (* NO_COMB *)
    input  wire CZI;

	(* CLK_TO_Q = "QCK 1e-11" *)
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
