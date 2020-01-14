(* CLASS="lut" *)
module NAMES(in, out);
    (* PORT_CLASS="lut_in" *)
    input  wire [0:0] in;
    (* PORT_CLASS="lut_out" *)
    (* DELAY_CONST_in="1e-10" *)
    output wire       out;

    parameter [0:0] INIT = 0;

    // TODO: The VPR requires that there is at least one leaf pb_type that
    // supports the ".names" subcircuit (LUT). This module is for that.
    //
    // It is going to be treated by VPR as a "LUT1" with init parameter.
    // A LUT1 can be either a pass-through or an inverter fepending on content
    // of the INIT parameter. According to that correct fasm features have to
    // be emitter.

endmodule
