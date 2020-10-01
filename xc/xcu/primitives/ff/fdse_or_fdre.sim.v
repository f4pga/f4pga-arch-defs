`ifndef FDSE_OR_FDRE
`define FDSE_OR_FDRE

`include "fdse.sim.v"
`include "fdre.sim.v"

(* MODES="FDSE;FDRE" *)
module FDSE_OR_FDRE(D, SR, CE, CLK, Q);
    input D;
    input SR;
    input CE;
    input CLK;
    output Q;

    parameter MODE = "";

    if (MODE == "FDSE") begin
        FDSE FDSE(.D(D), .SR(SR), .CE(CE), .CLK(CLK), .Q(Q));
    end else if (MODE == "FDRE") begin
        FDRE FDRE(.D(D), .SR(SR), .CE(CE), .CLK(CLK), .Q(Q));
    end
endmodule
`endif
