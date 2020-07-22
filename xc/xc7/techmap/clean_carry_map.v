// Output CO directly
module CARRY_CO_DIRECT(input CO, input O, input S, input DI, output OUT);

parameter TOP_OF_CHAIN = 0;

assign OUT = CO;

endmodule

// Compute CO from S, DI, O.
module CARRY_CO_LUT(input CO, input O, input S, input DI, output OUT);

parameter TOP_OF_CHAIN = 0;

generate if(TOP_OF_CHAIN)
    // S == S[i]
    // DI == DI[i]
    // O == O[i]
    // CO == CO[i]
    //
    // Need to replicate both MUXCY and XORCY to get CO[i].
    //
    // Equations:
    //   1) CO[i] = S[i] ? CO[i-1] : DI[i]
    //   2) O[i] = S[i] ^ CO[i-1]
    //
    //   -- Add "S[i] ^" to the front of both sides of eq 2 --
    //
    //   3) S[i] ^ O[i] = S[i] ^ S[i] ^ CO[i-1]
    //
    //   -- Apply A ^ A = 0 to eq 3 --
    //
    //   4) S[i] ^ O[i] = 0 ^ CO[i-1]
    //
    //   -- Apply A ^ B = B ^ A to eq 4
    //
    //   5) S[i] ^ O[i] = CO[i-1] ^ 0
    //
    //   -- Apply A ^ 0 = A to eq 5
    //
    //   6) S[i] ^ O[i] = CO[i-1]
    //
    //   -- subsititude CO[i-1] from eq 6 into equation 1 --
    //
    //   7) CO[i] = S[i] ? (S[i] ^ O[i]) : DI[i]
    //
    // DI, S, O (0, 0, 0) = 0 => OUT = DI => 0
    // DI, S, O (0, 0, 1) = 1 => OUT = DI => 0
    // DI, S, O (0, 1, 0) = 2 => OUT = S ^ O => 1
    // DI, S, O (0, 1, 1) = 3 => OUT = S ^ O => 0
    // DI, S, O (1, 0, 0) = 4 => OUT = DI => 1
    // DI, S, O (1, 0, 1) = 5 => OUT = DI => 1
    // DI, S, O (1, 1, 0) = 6 => OUT = S ^ O => 1
    // DI, S, O (1, 1, 1) = 7 => OUT = S ^ O => 0
    //
    LUT3 #(.INIT(4'b01110100)) mux_and_xor_lut (.I0(O), .I1(S), .I2(DI), .O(OUT));
else
    // S == S[i+1]
    // O == O[i+1]
    // CO == CO[i]
    //
    // Because S/O from next level is available, equation is simply:
    //
    // CO[i] = S[i+1] ^ O[i+1]
    //
    // S, O (0, 0) = 0 => 0
    // S, O (0, 1) = 1 => 1
    // S, O (1, 0) = 2 => 1
    // S, O (1, 1) = 3 => 0
    //
    LUT2 #(.INIT(4'b0110)) xor_lut (.I0(O), .I1(S), .O(OUT));
end endgenerate

endmodule
