// Converts a LUT2 to a mux2x0 directly if the LUT configuration allows for that.
module LUT2(
    input  I0,
    input  I1,
    output O
);

    parameter [3:0] INIT = 4'd0;
    parameter EQN = "(I0)";

    generate if (INIT == 4'b1000) begin
        mux2x0 _TECHMAP_REPLACE_ (.A( 0), .B(I0), .S(I1), .Q(O));
    end else if (INIT == 4'b1011) begin
        mux2x0 _TECHMAP_REPLACE_ (.A( 1), .B(I0), .S(I1), .Q(O));

//  end else if (INIT == 4'b1000) begin
//      mux2x0 _TECHMAP_REPLACE_ (.A( 0), .B(I1), .S(I0), .Q(O));
    end else if (INIT == 4'b1101) begin
        mux2x0 _TECHMAP_REPLACE_ (.A( 1), .B(I1), .S(I0), .Q(O));

    end else if (INIT == 4'b0010) begin
        mux2x0 _TECHMAP_REPLACE_ (.A(I0), .B( 0), .S(I1), .Q(O));
    end else if (INIT == 4'b1110) begin
        mux2x0 _TECHMAP_REPLACE_ (.A(I0), .B( 1), .S(I1), .Q(O));

    end else if (INIT == 4'b0100) begin
        mux2x0 _TECHMAP_REPLACE_ (.A(I1), .B( 0), .S(I0), .Q(O));
//  end else if (INIT == 4'b1110) begin
//      mux2x0 _TECHMAP_REPLACE_ (.A(I1), .B( 1), .S(I0), .Q(O));

    end else
        wire _TECHMAP_FAIL_ = 1'b1;
    endgenerate

endmodule
