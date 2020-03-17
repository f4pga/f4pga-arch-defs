(* whitebox *)
module F_FRAG (F1, F2, FS, FZ);
    input  wire F1;
    input  wire F2;
    input  wire FS;

    (* DELAY_CONST_F1="1e-11" *)
    (* DELAY_CONST_F2="1e-11" *)
    (* DELAY_CONST_FS="1e-11" *)
    output wire FZ;

    // The F-mux
    assign FZ = FS ? F2 : F1;

endmodule
