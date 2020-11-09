`include "./gmux_ip.sim.v"
`include "./gmux_ic.sim.v"

(* MODES="IP;IC" *)
module GMUX (IP, IC, IS0, IZ);

    input  wire IP;
    input  wire IC;
    input  wire IS0;
    output wire IZ;

    parameter MODE = "IP";

    // Mode for the IP input connected
    generate if (MODE == "IP") begin

        (* FASM_PREFIX="GMUX.GMUX" *)
        GMUX_IP gmux (
            .IP  (IP),
            .IC  (IC),
            .IS0 (IS0),
            .IZ  (IZ) 
        );

    // Mode for the IP input disconnected
    end else if (MODE == "IC") begin

        (* FASM_PREFIX="GMUX.GMUX" *)
        GMUX_IC gmux (
            .IC  (IC),
            .IS0 (IS0),
            .IZ  (IZ) 
        );

    end endgenerate

endmodule
