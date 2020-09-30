`include "fdse_or_fdre.sim.v"
`include "fdpe_or_fdce.sim.v"

(* MODES="FDSE_OR_FDRE;FDPE_OR_FDCE" *)
module SLICE_FF_BOT (D, CE, SR, CLK, Q);
    input wire [7:0] D;
    input wire [7:0] SR;
    input wire [7:0] CE;
    input wire  CLK;
    output wire [7:0] Q;

    parameter MODE = "";

    if (MODE == "FDSE_OR_FDRE") begin
        genvar i;
        generate
            for (i = 0; i < 4; i = i+1) begin
                (* FASM_PREFIX="AFF;BFF;CFF;DFF" *)
                FDSE_OR_FDRE FDSE_OR_FDRE_1(.D(D[i*2]), .CE(CE[i*2]), .SR(SR[i*2]), .CLK(CLK), .Q(Q[i*2]));
                (* FASM_PREFIX="AFF2;BFF2;CFF2;DFF2" *)
                FDSE_OR_FDRE FDSE_OR_FDRE_2(.D(D[i*2+1]), .CE(CE[i*2+1]), .SR(SR[i*2+1]), .CLK(CLK), .Q(Q[i*2+1]));
            end
        endgenerate
    end else if (MODE == "FDPE_OR_FDCE") begin
        genvar i;
        generate
            for (i = 0; i < 4; i = i+1) begin
                (* FASM_PREFIX="AFF;BFF;CFF;DFF" *)
                FDPE_OR_FDCE FDPE_OR_FDCE_1(.D(D[i*2]), .CE(CE[i*2]), .SR(SR[i*2]), .CLK(CLK), .Q(Q[i*2]));
                (* FASM_PREFIX="AFF2;BFF2;CFF2;DFF2" *)
                FDPE_OR_FDCE FDPE_OR_FDCE_2(.D(D[i*2+1]), .CE(CE[i*2+1]), .SR(SR[i*2+1]), .CLK(CLK), .Q(Q[i*2+1]));
            end
        endgenerate
    end
endmodule
