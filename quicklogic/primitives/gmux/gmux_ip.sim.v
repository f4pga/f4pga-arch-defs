(* whitebox *)
module GMUX_IP (IP, IC, IS0, IZ);

    input  wire IP;
    input  wire IC;
    input  wire IS0;

    (* DELAY_CONST_IP="{iopath_IP_IZ}" *)
    (* DELAY_CONST_IC="{iopath_IC_IZ}" *)
    (* DELAY_CONST_IS0="1e-10" *)  // No timing for the select pin
    (* clkbuf_driver *)
    output wire IZ;

    assign IZ = IS0 ? IC : IP;

endmodule
