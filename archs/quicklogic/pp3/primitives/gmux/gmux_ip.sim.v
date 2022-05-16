(* whitebox *)
(* FASM_FEATURES="I_invblock.I_J0.ZINV.IS0;I_invblock.I_J1.ZINV.IS1;I_invblock.I_J2.ZINV.IS0;I_invblock.I_J3.ZINV.IS0;I_invblock.I_J4.ZINV.IS1" *)
module GMUX_IP (IP, IC, IS0, IZ);

    (* CLOCK, NO_COMB=0 *)
    input  wire IP;
    (* CLOCK, NO_COMB=0 *)
    input  wire IC;
    input  wire IS0;

    (* DELAY_CONST_IP="{iopath_IP_IZ}" *)
    (* DELAY_CONST_IC="{iopath_IC_IZ}" *)
    (* DELAY_CONST_IS0="1e-10" *)  // No timing for the select pin
    (* clkbuf_driver *)
    output wire IZ;

    specify
        (IP => IZ) = (0,0);
		(IC => IZ) = (0,0);
		(IS0 => IZ) = (0,0);
    endspecify

    assign IZ = IS0 ? IC : IP;

endmodule
