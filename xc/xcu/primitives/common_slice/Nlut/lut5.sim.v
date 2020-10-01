(* CLASS="lut" *)
(* whitebox *)
module LUT5 (in, out);
    (* PORT_CLASS="lut_in" *)
    input wire [4:0] in;
    (* PORT_CLASS="lut_out" *)
    (* DELAY_MATRIX_MAX_in="1e-10;1e-10;1e-10;1e-10;1e-10" *)
    (* DELAY_MATRIX_MIN_in="1e-12;1e-12;1e-12;1e-12;1e-12" *)
    output wire out;
endmodule
