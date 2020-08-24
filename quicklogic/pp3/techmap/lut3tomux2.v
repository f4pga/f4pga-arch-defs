// Converts a LUT3 to a mux2x0 whenever the LUT configuration allows for that.

module LUT3 (
    input  I0,
    input  I1,
    input  I2,
    output O
);

    parameter [7:0] INIT = 8'd0;
    parameter EQN = "(I0)";

    generate if (INIT == 8'b1010_1100) begin
        mux2x0 _TECHMAP_REPLACE_ (.S(I2), .A(I1), .B(I0), .Q(O));
    end else if (INIT == 8'b1100_1010) begin
        mux2x0 _TECHMAP_REPLACE_ (.S(I2), .B(I1), .A(I0), .Q(O));
    end else if (INIT == 8'b1011_1000) begin
        mux2x0 _TECHMAP_REPLACE_ (.A(I2), .S(I1), .B(I0), .Q(O));
    end else if (INIT == 8'b1110_0010) begin
        mux2x0 _TECHMAP_REPLACE_ (.B(I2), .S(I1), .A(I0), .Q(O));
    end else if (INIT == 8'b1101_1000) begin
        mux2x0 _TECHMAP_REPLACE_ (.A(I2), .B(I1), .S(I0), .Q(O));
    end else if (INIT == 8'b1110_0100) begin
        mux2x0 _TECHMAP_REPLACE_ (.B(I2), .A(I1), .S(I0), .Q(O));
    end else
        wire _TECHMAP_FAIL_ = 1'b1;
    endgenerate

endmodule
