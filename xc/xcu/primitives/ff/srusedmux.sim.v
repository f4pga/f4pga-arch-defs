`include "sr_gnd.sim.v"
`include "sr_used.sim.v"

(* FASM_FEATURES_SR_USED="SRUSED.V1" *)
(* FASM_FEATURES_SR_GND="SRUSED.V0" *)
(* MODES="SR_USED;SR_GND" *)
(* lib_whitebox *)
module SRUSEDMUX(SR, SR_OUT);
    input wire SR;
    output wire [3:0] SR_OUT;

    parameter MODE = "";
    generate if (MODE == "SR_USED") begin
        genvar i;
        for (i = 0; i < 4; i = i+1) begin
            SR_USED SR_USED(.SR(SR), .SR_OUT(SR_OUT[i]));
        end
    end else if (MODE == "SR_GND") begin
        genvar i;
        for (i = 0; i < 4; i = i+1) begin
            SR_GND SR_GND(.SR_OUT(SR_OUT[i]));
        end
    end endgenerate

endmodule
