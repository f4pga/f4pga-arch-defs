(* whitebox *)
module GMUX(IP, IC, IS0, IZ);

    (* CLOCK *)
    (* COMB_SINKS="IZ" *)
    input  wire IP;

    (* CLOCK *)
    (* COMB_SINKS="IZ" *)
    input  wire IC;

    input  wire IS0;

    (* DELAY_CONST_IP="{iopath_IP_IZ}" *)
    (* DELAY_CONST_IC="{iopath_IC_IZ}" *)
    (* DELAY_CONST_IS0="1e-10" *)  // No timing for the select pin
    output wire IZ;

    // TODO: To be verified!
    assign IZ = IS0 ? IC : IP;

endmodule
