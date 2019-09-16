module CARRY4_COUT(output [3:0] CO, O, output COUT, input CI, CYINIT, input [3:0] DI, S);

wire [3:0] CO_INTERNAL;

assign COUT = CO_INTERNAL[3];
assign CO = CO_INTERNAL;

CARRY4 _TECHMAP_REPLACE_ (
    .CO(CO_INTERNAL),
    .O(O),
    .CI(CI),
    .CYINIT(CYINIT),
    .DI(DI),
    .S(S)
);

endmodule

module CARRY_COUT_PLUG(input CIN, output COUT);

assign COUT = CIN;

endmodule
