module FF(input D, C, CE, SR, output Q);

parameter INIT = 1'b0;
parameter FF_TYPE = "FDRE";

if(FF_TYPE == "FDRE") begin
    (* keep *) FDRE #(
        .INIT(INIT)
    ) fdre (
        .Q(Q),
        .C(C),
        .D(D),
        .CE(CE),
        .R(SR)
    );
end else if(FF_TYPE == "FDSE") begin
    (* keep *) FDSE #(
        .INIT(INIT)
    ) fdse (
        .Q(Q),
        .C(C),
        .D(D),
        .CE(CE),
        .S(SR)
    );
end else if(FF_TYPE == "FDCE") begin
    (* keep *) FDCE #(
        .INIT(INIT)
    ) fdce (
        .Q(Q),
        .C(C),
        .D(D),
        .CE(CE),
        .CLR(SR)
    );
end else if(FF_TYPE == "FDPE") begin
    (* keep *) FDPE #(
        .INIT(INIT)
    ) fdpe (
        .Q(Q),
        .C(C),
        .D(D),
        .CE(CE),
        .PRE(SR)
    );
end

endmodule
