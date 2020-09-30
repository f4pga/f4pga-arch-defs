`include "ce_vcc.sim.v"
`include "ce_used.sim.v"

(* FASM_FEATURES_CE_USED="CEUSED.V1" *)
(* FASM_FEATURES_CE_VCC="CEUSED.V0" *)
(* MODES="CE_USED;CE_VCC" *)
(* lib_whitebox *)
module CEUSEDMUX(CE, CE_OUT);
    input wire CE;
    output wire [3:0] CE_OUT;

    parameter MODE = "";
    generate if (MODE == "CE_USED") begin
        genvar i;
        for (i = 0; i < 4; i = i+1) begin
            CE_USED CE_USED(.CE(CE), .CE_OUT(CE_OUT[i]));
        end
    end else if (MODE == "CE_VCC") begin
        genvar i;
        for (i = 0; i < 4; i = i+1) begin
            CE_VCC CE_VCC(.CE_OUT(CE_OUT[i]));
        end
    end endgenerate

endmodule
