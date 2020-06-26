// This is a "proxy" cell for a GMUX connected to CLOCK. It is inserted by
// Yosys and techmapped to a GMUX_IP with IS0=1'b1

(* whitebox *)
module GMUX_PROXY (IP, IZ);
    input  wire IP;
    (* clkbuf_driver *)
    output wire IZ;

    assign IZ = IP;

endmodule
