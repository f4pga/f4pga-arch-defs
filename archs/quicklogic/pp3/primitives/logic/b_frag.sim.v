`timescale 1ns/10ps
(* FASM_PARAMS="INV.BA1=XAS1;INV.BA2=XAS2;INV.BB1=XBS1;INV.BB2=XBS2" *)
(* MODEL_NAME="T_FRAG" *) // This is intentional!
(* whitebox *)
module B_FRAG (TBS, XAB, XSL, XA1, XA2, XB1, XB2, XZ);

    // This is assumed to be connected to const1 in the techmap
    input  wire TBS;

    input  wire XAB;
    input  wire XSL;
    input  wire XA1;
    input  wire XA2;
    input  wire XB1;
    input  wire XB2;

    // These timings differ whether an input inverter is on or off. To model
    // this in VPR it would require a different pb_type for each combination
    // of inverter configurations! So here we take the worst timing. See
    // bels.json for where these are taken from.
    (* DELAY_CONST_TBS="{iopath_TBS_CZ}" *)
    (* DELAY_CONST_XAB="{iopath_BAB_CZ}" *)
    (* DELAY_CONST_XSL="{iopath_BSL_CZ}" *)
    (* DELAY_CONST_XA1="{iopath_BA1_CZ}" *)
    (* DELAY_CONST_XA2="{iopath_BA2_CZ}" *)
    (* DELAY_CONST_XB1="{iopath_BB1_CZ}" *)
    (* DELAY_CONST_XB2="{iopath_BB2_CZ}" *)
    output wire XZ;
   
    specify
        (TBS => XZ) = (0,0);
        (XAB => XZ) = (0,0);
        (XSL => XZ) = (0,0);
        (XA1 => XZ) = (0,0);
        (XA2 => XZ) = (0,0);
        (XB1 => XZ) = (0,0);
        (XB2 => XZ) = (0,0);
    endspecify

    // Control parameters
    parameter [0:0] XAS1 = 1'b0;
    parameter [0:0] XAS2 = 1'b0;
    parameter [0:0] XBS1 = 1'b0;
    parameter [0:0] XBS2 = 1'b0;

    // Input routing inverters
    wire XAP1 = (XAS1) ? ~XA1 : XA1;
    wire XAP2 = (XAS2) ? ~XA2 : XA2;
    wire XBP1 = (XBS1) ? ~XB1 : XB1;
    wire XBP2 = (XBS2) ? ~XB2 : XB2;

    // 1st mux stage
    wire XAI = XSL ? XAP2 : XAP1;
    wire XBI = XSL ? XBP2 : XBP1;

    // 2nd mux stage
    wire XZI = XAB ? XBI : XAI;

    // 3rd mux stage. Note that this is fake purely to make the VPR work with
    // the actual FPGA architecture. It is assumed that TBI is always routed
    // to const1 co physically CZ is always connected to the bottom of the
    // C_FRAG.
    assign XZ = TBS ? XZI : 1'b0;

endmodule
