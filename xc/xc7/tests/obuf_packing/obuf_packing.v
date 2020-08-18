module top (
    input  wire [7:0] inp,
    input  wire [1:0] hiz,
    output wire [3:0] out,
    output wire [3:0] out_p,
    output wire [3:0] out_n
);


// OBUF
OBUF #(
    .IOSTANDARD("LVCMOS33"),
    .DRIVE(8),
    .SLEW("FAST")
) obuf_0 (
    .I  (inp[0]),
    .O  (out[0])
);

// OBUFT, T=0
OBUFT #(
    .IOSTANDARD("LVCMOS33"),
    .DRIVE(8),
    .SLEW("FAST")
) obuf_1 (
    .I  (inp[1]),
    .T  (1'b0),
    .O  (out[1])
);

// OBUFT, T=1 (this case is useless as it is always 1'bz on output)
OBUFT #(
    .IOSTANDARD("LVCMOS33"),
    .DRIVE(8),
    .SLEW("FAST")
) obuf_2 (
    .I  (inp[2]),
    .T  (1'b1),
    .O  (out[2])
);

// OBUFT, T=<net>
OBUFT #(
    .IOSTANDARD("LVCMOS33"),
    .DRIVE(8),
    .SLEW("FAST")
) obuf_3 (
    .I  (inp[3]),
    .T  (hiz[0]),
    .O  (out[3])
);


// OBUFDS
OBUFDS # (
    .IOSTANDARD("DIFF_SSTL135"),
    .SLEW("FAST")
) obuftds_0 (
    .I (inp[4]),
    .O (out_p[0]),
    .OB(out_n[0])
);

// OBUFTDS, T=0
OBUFTDS # (
    .IOSTANDARD("DIFF_SSTL135"),
    .SLEW("FAST")
) obuftds_1 (
    .I (inp[5]),
    .T (1'b0),
    .O (out_p[1]),
    .OB(out_n[1])
);

// OBUFTDS, T=1 (this case is useless as it is always 1'bz on output)
OBUFTDS # (
    .IOSTANDARD("DIFF_SSTL135"),
    .SLEW("FAST")
) obuftds_2 (
    .I (inp[6]),
    .T (1'b1),
    .O (out_p[2]),
    .OB(out_n[2])
);

// OBUFTDS, T=<net>
OBUFTDS # (
    .IOSTANDARD("DIFF_SSTL135"),
    .SLEW("FAST")
) obuftds_3 (
    .I (inp[7]),
    .T (hiz[1]),
    .O (out_p[3]),
    .OB(out_n[3])
);

endmodule
