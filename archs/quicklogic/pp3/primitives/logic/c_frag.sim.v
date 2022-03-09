(* FASM_PARAMS="INV.TA1=TAS1;INV.TA2=TAS2;INV.TB1=TBS1;INV.TB2=TBS2;INV.BA1=BAS1;INV.BA2=BAS2;INV.BB1=BBS1;INV.BB2=BBS2" *)
(* whitebox *)
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
    endspecify

endmodule
