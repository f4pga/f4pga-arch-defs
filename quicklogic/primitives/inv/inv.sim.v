`include "./not.sim.v"
(* MODES="PASSTHROUGH;INVERT" *)
module INV(I, O);

    input  wire I;
    output wire O;

    parameter MODE="";

    // Passthrough (no inversion) mode
    generate if (MODE == "PASSTHROUGH") begin
        assign O = I;

    // Inversion with placeable inverter
    end else if (MODE == "INVERT") begin
        NOT inverter(I, O);

    end endgenerate
endmodule
