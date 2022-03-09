`timescale 1ns/10ps
(* whitebox *)
module F_FRAG (F1, F2, FS, FZ);
    input  wire F1;
    input  wire F2;
    input  wire FS;

    (* DELAY_CONST_F1="{iopath_F1_FZ}" *)
    (* DELAY_CONST_F2="{iopath_F2_FZ}" *)
    (* DELAY_CONST_FS="{iopath_FS_FZ}" *)
    output wire FZ;
    specify
        (F1 => FZ) = (0,0);
        (F2 => FZ) = (0,0);
        (FS => FZ) = (0,0);
    endspecify
    // The F-mux
    assign FZ = FS ? F2 : F1;

endmodule
