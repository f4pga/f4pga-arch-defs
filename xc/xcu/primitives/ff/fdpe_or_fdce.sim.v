`include "fdpe.sim.v"
`include "fdce.sim.v"

(* MODES="FDPE;FDCE" *)
module FDPE_OR_FDCE(D, SR, CE, CLK, Q);
    input D;
    input SR;
    input CE;
    input CLK;
    output Q;

    parameter MODE = "";

    if (MODE == "FDPE") begin
        FDPE FDPE(.D(D), .SR(SR), .CE(CE), .CLK(CLK), .Q(Q));
    end else if (MODE == "FDCE") begin
        FDCE FDCE(.D(D), .SR(SR), .CE(CE), .CLK(CLK), .Q(Q));
    end
endmodule
