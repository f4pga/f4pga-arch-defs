(* whitebox *)
module Q_FRAG(QCK, QST, QRT, QEN, QDI, QDS, CZI, QZ);
    input  wire QCK;

	(* SETUP="QCK 10e-12" *) (* NO_COMB *)
    input  wire QST;
	(* SETUP="QCK 10e-12" *) (* NO_COMB *)
    input  wire QRT;
	(* SETUP="QCK 10e-12" *) (* NO_COMB *)
    input  wire QEN;
	(* SETUP="QCK 10e-12" *) (* NO_COMB *)
    input  wire QDI;
	(* SETUP="QCK 10e-12" *) (* NO_COMB *)
    input  wire QDS;
	(* SETUP="QCK 10e-12" *) (* NO_COMB *)
    input  wire CZI;

	(* CLK_TO_Q = "QCK 10e-12" *)
    output reg  QZ;

    // FF init
    parameter [0:0] INIT = 1'b0;

    // The "QDS" mux just before the flip-flop
    wire d = (QDS) ? QDI : CZI;

    // TODO: Clock inverter.

    // The flip-flop
    initial QZ = INIT;
	always @(posedge QCK or posedge QST or posedge QRT) begin
		if (QST)
			QZ <= 1'b1;
		else if (QRT)
			QZ <= 1'b0;
		else if (QEN)
			QZ <= d;
	end

endmodule
