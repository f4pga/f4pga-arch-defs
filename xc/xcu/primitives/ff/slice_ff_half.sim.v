`include "fdse_or_fdre.sim.v"

(* MODES="FDSE_OR_FDRE;FDPE_OR_FDCE;LDCE_OR_LDPE" *)
module SLICE_FF_HALF(D, CE, SR, CLK, Q);
    input wire [7:0] D;
    input wire  SR;
    input wire  CE;
    input wire  CLK;
    output wire [7:0] Q;

    parameter MODE = "";

    if (MODE == "FDSE_OR_FDRE") begin
        genvar i;
        generate
            for (i = 0; i < 8; i = i+1) begin
                FDSE_OR_FDRE FDSE_OR_FDRE(.D(D[i]), .CE(CE), .SR(SR), .CLK(CLK), .Q(Q[i]));
            end
        endgenerate
    end else if (MODE == "FDPE_OR_FDCE") begin
        genvar i;
        generate
            for (i = 0; i < 8; i = i+1) begin
                FDSE_OR_FDRE FDSE_OR_FDRE_1(.D(D[i]), .CE(CE), .SR(SR), .CLK(CLK), .Q(Q[i]));
            end
        endgenerate
    end else if (MODE == "LDCE_OR_LDPE") begin
        genvar i;
        generate
            for (i = 0; i < 8; i = i+1) begin
                FDSE_OR_FDRE FDSE_OR_FDRE_2(.D(D[i]), .CE(CE), .SR(SR), .CLK(CLK), .Q(Q[i]));
            end
        endgenerate
    end
endmodule
