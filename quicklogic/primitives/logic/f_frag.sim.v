(* whitebox *)
module F_FRAG (F1, F2, FS, FZ);
    input  wire F1;
    input  wire F2;
    input  wire FS;

    (* DELAY_CONST_F1="10e-10" *)
    (* DELAY_CONST_F2="10e-10" *)
    (* DELAY_CONST_FS="10e-10" *)
    output wire FZ;

    // The F-mux
    assign FZ = FS ? F2 : F1;

endmodule
