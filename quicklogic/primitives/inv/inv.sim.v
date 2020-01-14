`include "./not.sim.v"
`include "./names.sim.v"

(* MODES="PASSTHROUGH;NAMES;INVERT" *)
module INV(I, O);

    input  wire I;
    output wire O;

    parameter MODE="";

    // Passthrough (no inversion) mode
    generate if (MODE == "PASSTHROUGH") begin
        // FIXME: V2X is missing an interconnect.
        assign O = I;

    // A mode for packing .names (LUT) with width of 1. Can be either an inverter
    // or passthrough.
    end else if (MODE == "NAMES") begin
        NAMES names(I, O);

    // Inversion with placeable inverter
    end else if (MODE == "INVERT") begin
        NOT inverter(I, O);

    end endgenerate
endmodule
