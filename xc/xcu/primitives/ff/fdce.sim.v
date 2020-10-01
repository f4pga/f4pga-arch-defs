(* FASM_PARAMS="INIT.V0=INIT_V0;INIT.V1=INIT.V1;SRVAL.V0=SRVAL_V0;SRVAL.V1=SRVAL_V1" *)
(* whitebox *)
module FDCE(D, SR, CE, CLK, Q);
    input  D;
    input  SR;
    input  CE;
    input  CLK;
    output  Q;
endmodule
