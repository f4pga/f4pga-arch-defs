module FD (output reg Q, input C, D);

parameter [0:0] INIT = 1'b0;

FDRE #(.INIT(INIT)) _TECHMAP_REPLACE_ (.Q(Q), .C(C), .D(D), .CE(1'b1), .R(1'b0));

endmodule
