module ioddr_tester (
    input  wire CLK,
    output wire ERR,
    output wire Q,
    input  wire D
);

    parameter USE_PHY_ODDR = 1;
    parameter USE_PHY_IDDR = 1;
    parameter DDR_CLK_EDGE = "SAME_EDGE";

    // Data generator
    wire [1:0] g_dat;
    data_generator gen (
        .CLK    (CLK),
        .CE     (1'b1),
        .D1     (g_dat[0]),
        .D2     (g_dat[1])
    );

    // Data delay
    wire [1:0] d_dat;
    reg  [1:0] d_d1;
    reg  [1:0] d_d2;

    always @(posedge CLK) begin
        d_d1 <= {g_dat[0], d_d1[1]};
        d_d2 <= {g_dat[1], d_d2[1]};
    end

    assign d_dat = {d_d2[0], d_d1[0]};

    // ODDR
    oddr_wrapper # (
        .USE_PHY_ODDR   (USE_PHY_ODDR),
        .DDR_CLK_EDGE   (DDR_CLK_EDGE)
    ) oddr_wrapper (
        .C              (CLK),
        .OCE            (1'b1),
        .S              (0),
        .R              (0),
        .D1             (g_dat[0]),
        .D2             (g_dat[1]),
        .OQ             (Q)
    );

    // IDDR
    wire [1:0] r_dat;
    iddr_wrapper # (
        .USE_PHY_IDDR   (USE_PHY_IDDR),
        .DDR_CLK_EDGE   (DDR_CLK_EDGE)
    ) iddr_wrapper (
        .C              (CLK),
        .CE             (1'b1),
        .S              (0),
        .R              (0),
        .D              (D),
        .Q1             (r_dat[1]),
        .Q2             (r_dat[0])
    );

    // Re-clock received data in OPPOSITE_EDGE MODE
    wire [1:0] r_dat2;
    generate if(DDR_CLK_EDGE == "OPPOSITE_EDGE") begin

        reg [1:0] tmp;
        always @(posedge CLK)
            tmp <= r_dat;

        assign r_dat2 = tmp;

    end else begin

        assign r_dat2 = r_dat;

    end endgenerate


    // Data comparator
    reg err_r;
    always @(posedge CLK)
        err_r <= r_dat2 != d_dat;

    // Error pulse prolonger
    reg [20:0] cnt;
    wire err = !cnt[20];

    always @(posedge CLK)
        if (err_r)    cnt <= 1 << 24;
        else if (err) cnt <= cnt - 1;
        else          cnt <= cnt;

    assign ERR = err;

endmodule
