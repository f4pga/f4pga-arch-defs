(* FASM_PARAMS="INV.TA1=TAS1;INV.TA2=TAS2;INV.TB1=TBS1;INV.TB2=TBS2;INV.BA1=BAS1;INV.BA2=BAS2;INV.BB1=BBS1;INV.BB2=BBS2;ZINV.QCK=Z_QCKS" *)
(* whitebox *)
module LOGIC_MACRO (QST, QDS, TBS, TAB, TSL, TA1, TA2, TB1, TB2, BAB, BSL, BA1, BA2, BB1, BB2, QDI, QEN, QCK, QRT, F1, F2, FS, TZ, CZ, QZ, FZ);

    // =============== C_FRAG ===============

    (* NO_SEQ *)
    input  wire TBS;
    (* NO_SEQ *)
    input  wire TAB;
    (* NO_SEQ *)
    input  wire TSL;
    (* NO_SEQ *)
    input  wire TA1;
    (* NO_SEQ *)
    input  wire TA2;
    (* NO_SEQ *)
    input  wire TB1;
    (* NO_SEQ *)
    input  wire TB2;
    (* NO_SEQ *)
    input  wire BAB;
    (* NO_SEQ *)
    input  wire BSL;
    (* NO_SEQ *)
    input  wire BA1;
    (* NO_SEQ *)
    input  wire BA2;
    (* NO_SEQ *)
    input  wire BB1;
    (* NO_SEQ *)
    input  wire BB2;

    (* DELAY_CONST_TAB="{iopath_TAB_TZ}" *)
    (* DELAY_CONST_TSL="{iopath_TSL_TZ}" *)
    (* DELAY_CONST_TA1="{iopath_TA1_TZ}" *)
    (* DELAY_CONST_TA2="{iopath_TA2_TZ}" *)
    (* DELAY_CONST_TB1="{iopath_TB1_TZ}" *)
    (* DELAY_CONST_TB2="{iopath_TB2_TZ}" *)
    output wire TZ;

    (* DELAY_CONST_TBS="{iopath_TBS_CZ}" *)
    (* DELAY_CONST_TAB="{iopath_TAB_CZ}" *)
    (* DELAY_CONST_TSL="{iopath_TSL_CZ}" *)
    (* DELAY_CONST_TA1="{iopath_TA1_CZ}" *)
    (* DELAY_CONST_TA2="{iopath_TA2_CZ}" *)
    (* DELAY_CONST_TB1="{iopath_TB1_CZ}" *)
    (* DELAY_CONST_TB2="{iopath_TB2_CZ}" *)
    (* DELAY_CONST_BAB="{iopath_BAB_CZ}" *)
    (* DELAY_CONST_BSL="{iopath_BSL_CZ}" *)
    (* DELAY_CONST_BA1="{iopath_BA1_CZ}" *)
    (* DELAY_CONST_BA2="{iopath_BA2_CZ}" *)
    (* DELAY_CONST_BB1="{iopath_BB1_CZ}" *)
    (* DELAY_CONST_BB2="{iopath_BB2_CZ}" *)
    output wire CZ;

    // Control parameters
    parameter [0:0] TAS1 = 1'b0;
    parameter [0:0] TAS2 = 1'b0;
    parameter [0:0] TBS1 = 1'b0;
    parameter [0:0] TBS2 = 1'b0;

    parameter [0:0] BAS1 = 1'b0;
    parameter [0:0] BAS2 = 1'b0;
    parameter [0:0] BBS1 = 1'b0;
    parameter [0:0] BBS2 = 1'b0;

    // Input routing inverters
    wire TAP1 = (TAS1) ? ~TA1 : TA1;
    wire TAP2 = (TAS2) ? ~TA2 : TA2;
    wire TBP1 = (TBS1) ? ~TB1 : TB1;
    wire TBP2 = (TBS2) ? ~TB2 : TB2;

    wire BAP1 = (BAS1) ? ~BA1 : BA1;
    wire BAP2 = (BAS2) ? ~BA2 : BA2;
    wire BBP1 = (BBS1) ? ~BB1 : BB1;
    wire BBP2 = (BBS2) ? ~BB2 : BB2;

    // 1st mux stage
    wire TAI = TSL ? TAP2 : TAP1;
    wire TBI = TSL ? TBP2 : TBP1;
    
    wire BAI = BSL ? BAP2 : BAP1;
    wire BBI = BSL ? BBP2 : BBP1;

    // 2nd mux stage
    wire TZI = TAB ? TBI : TAI;
    wire BZI = BAB ? BBI : BAI;

    // 3rd mux stage
    wire CZI = TBS ? BZI : TZI;

    // Output
    assign TZ = TZI;
    assign CZ = CZI;

    // =============== Q_FRAG ===============

    (* CLOCK *)
    (* clkbuf_sink *)
    input  wire QCK;
    
    // Cannot model timing, VPR currently does not support async SET/RESET
	(* SETUP="QCK 1e-10" *)
    (* NO_COMB *)
    input  wire QST;

    // Cannot model timing, VPR currently does not support async SET/RESET
	(* SETUP="QCK 1e-10" *)
    (* NO_COMB *)
    input  wire QRT;

    // No timing for QEN -> QZ in LIB/SDF
	(* SETUP="QCK {setup_QCK_QEN}" *)
	(* HOLD="QCK {hold_QCK_QEN}" *)
    (* NO_COMB *)
    input  wire QEN;

	(* SETUP="QCK {setup_QCK_QDI}" *)
	(* HOLD="QCK {hold_QCK_QDI}" *)
    (* NO_COMB *)
    input  wire QDI;

	(* SETUP="QCK {setup_QCK_QDS}" *)
	(* HOLD="QCK {hold_QCK_QDS}" *)
    (* NO_COMB *)
    input  wire QDS;

	(* CLK_TO_Q = "QCK {iopath_QCK_QZ}" *)
    // The following DELAY_CONST_xx represent a combinational delay from a
    // LOGIC input to the FF input QZI. Since when QDS=0 QZI is connected to
    // CZI then let's assume that the delay is the same as to the CZ output.
    (* DELAY_CONST_TBS="{iopath_TBS_CZ}" *)
    (* DELAY_CONST_TAB="{iopath_TAB_CZ}" *)
    (* DELAY_CONST_TSL="{iopath_TSL_CZ}" *)
    (* DELAY_CONST_TA1="{iopath_TA1_CZ}" *)
    (* DELAY_CONST_TA2="{iopath_TA2_CZ}" *)
    (* DELAY_CONST_TB1="{iopath_TB1_CZ}" *)
    (* DELAY_CONST_TB2="{iopath_TB2_CZ}" *)
    (* DELAY_CONST_BAB="{iopath_BAB_CZ}" *)
    (* DELAY_CONST_BSL="{iopath_BSL_CZ}" *)
    (* DELAY_CONST_BA1="{iopath_BA1_CZ}" *)
    (* DELAY_CONST_BA2="{iopath_BA2_CZ}" *)
    (* DELAY_CONST_BB1="{iopath_BB1_CZ}" *)
    (* DELAY_CONST_BB2="{iopath_BB2_CZ}" *)
    // The following SETUP and HOLD should represent timings for the FF itself.
    // However, these values are not given in any SDF as separate. So instead
    // let's use QDI setup and hold timings.
	(* SETUP="QCK {setup_QCK_QDI}" *)
	(* HOLD="QCK {hold_QCK_QDI}" *)
    output reg  QZ;
	
	input  wire F1;
    input  wire F2;
    input  wire FS;

    (* DELAY_CONST_F1="{iopath_F1_FZ}" *)
    (* DELAY_CONST_F2="{iopath_F2_FZ}" *)
    (* DELAY_CONST_FS="{iopath_FS_FZ}" *)
    output wire FZ;

    // Parameters
    parameter [0:0] Z_QCKS = 1'b1;

    // The QZI-mux
    wire QZI = (QDS) ? QDI : CZI;
		
    specify
        (TBS => CZ) = (0,0);
        (TAB => CZ) = (0,0);
        (TSL => CZ) = (0,0);
        (TA1 => CZ) = (0,0);
        (TA2 => CZ) = (0,0);
        (TB1 => CZ) = (0,0);
        (TB2 => CZ) = (0,0);
        (BAB => CZ) = (0,0);
        (BSL => CZ) = (0,0);
        (BA1 => CZ) = (0,0);
        (BA2 => CZ) = (0,0);
        (BB1 => CZ) = (0,0);
        (BB2 => CZ) = (0,0);
        (TAB => TZ) = (0,0);
        (TSL => TZ) = (0,0);
        (TA1 => TZ) = (0,0);
        (TA2 => TZ) = (0,0);
        (TB1 => TZ) = (0,0);
        (TB2 => TZ) = (0,0);
        (F1 => FZ) = (0,0);
        (F2 => FZ) = (0,0);
        (FS => FZ) = (0,0);
        (QCK => QZ) = (0,0);
		$setup(CZI, posedge QCK, "");
        $hold(posedge QCK, CZI, "");
        $setup(QDI, posedge QCK, "");
        $hold(posedge QCK, QDI, "");
        $setup(QST, posedge QCK, "");
        $hold(posedge QCK, QST, "");
        $setup(QRT, posedge QCK, "");
        $hold(posedge QCK, QRT, "");
        $setup(QEN, posedge QCK, "");
        $hold(posedge QCK, QEN, "");
        $setup(QDS, posedge QCK, "");
        $hold(posedge QCK, QDS, "");
    endspecify

    // The flip-flop
    initial QZ <= 1'b0;
	always @(posedge QCK or posedge QST or posedge QRT) begin
		if (QST)
			QZ <= 1'b1;
		else if (QRT)
			QZ <= 1'b0;
		else if (QEN)
			QZ <= QZI;
	end

   // The F-mux
    assign FZ = FS ? F2 : F1;

endmodule
