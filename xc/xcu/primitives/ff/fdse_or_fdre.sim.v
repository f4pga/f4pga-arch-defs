`include "fdse.sim.v"
`include "fdre.sim.v"

(* MODES="FDSE;FDRE" *)
(* whitebox *)
module FDSE_OR_FDRE(D, SR, CE, CLK, Q);
    input D;
    input SR;
    input CE;
    input CLK;
    output Q;

    parameter MODE = "";

    if (MODE == "FDSE") begin
        FDSE FDSE(D, SR, CE, CLK, Q);
    end else if (MODE == "FDRE") begin
        FDRE FDRE(D, SR, CE, CLK, Q);
    end
endmodule
