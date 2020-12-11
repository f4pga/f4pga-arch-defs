module top(
    output wire [3:0] led,
    input wire rx,
    output wire tx,
    input wire clk125
);

wire [3:0] fclk;
wire [3:0] fresetn;
wire reset;
wire [1:0] gpios;
wire [19:0] irqf2p;
wire fclk0_bg;

/* Master AXI bus */
/* AR */
wire [31:0] MAXIGP0ARADDR;
wire MAXIGP0ARCACHE;
wire MAXIGP0ARVALID;
wire [2:0] MAXIGP0ARPROT;
wire MAXIGP0ARREADY;
wire [11:0] MAXIGP0ARID;
/* AW */
wire [31:0] MAXIGP0AWADDR;
wire MAXIGP0AWVALID;
wire [2:0] MAXIGP0AWPROT;
wire MAXIGP0AWREADY;
wire [11:0] MAXIGP0AWID;
/* B */
wire MAXIGP0BREADY;
wire [1:0] MAXIGP0BRESP;
wire MAXIGP0BVALID;
wire [11:0] MAXIGP0BID;
/* W */
wire MAXIGP0RREADY;
wire [31:0] MAXIGP0WDATA;
wire [3:0] MAXIGP0WSTRB;
wire MAXIGP0WVALID;
wire MAXIGP0WREADY;
wire [11:0] MAXIGP0WID;
/* R */
wire [31:0] MAXIGP0RDATA;
wire [1:0] MAXIGP0RRESP;
wire MAXIGP0RVALID;
wire [11:0] MAXIGP0RID;

/* PS7 Inputs */
wire MAXIGP0ACLK;

/* Slave AXI bus */
wire SAXIGP0ACLK;
wire MAXIGP0ARESETN;

/* AR */
wire [31:0] SAXIGP0ARADDR;
wire [1:0]  SAXIGP0ARBURST;
wire [3:0]  SAXIGP0ARCACHE;
wire [11:0] SAXIGP0ARID;
wire [3:0]  SAXIGP0ARLEN;
wire [1:0]  SAXIGP0ARLOCK;
wire [2:0]  SAXIGP0ARPROT;
wire [3:0]  SAXIGP0ARQOS;
wire [1:0]  SAXIGP0ARSIZE;
wire SAXIGP0ARVALID;
wire SAXIGP0ARREADY;
/* AW */
wire [31:0] SAXIGP0AWADDR;
wire [1:0]  SAXIGP0AWBURST;
wire [3:0]  SAXIGP0AWCACHE;
wire [11:0] SAXIGP0AWID;
wire [3:0]  SAXIGP0AWLEN;
wire [1:0]  SAXIGP0AWLOCK;
wire [2:0]  SAXIGP0AWPROT;
wire [3:0]  SAXIGP0AWQOS;
wire [1:0]  SAXIGP0AWSIZE;
wire SAXIGP0AWVALID;
wire SAXIGP0AWREADY;
/* B */
wire [11:0] SAXIGP0BID;
wire [1:0]  SAXIGP0BRESP;
wire SAXIGP0BVALID;
wire SAXIGP0BREADY;
/* R */
wire [31:0] SAXIGP0RDATA;
wire [11:0] SAXIGP0RID;
wire [1:0] SAXIGP0RRESP;
wire SAXIGP0RLAST;
wire SAXIGP0RVALID;
wire SAXIGP0RREADY;
/* W */
wire [31:0] SAXIGP0WDATA;
wire [11:0] SAXIGP0WID;
wire [3:0]  SAXIGP0WSTRB;
wire SAXIGP0WVALID;
wire SAXIGP0WLAST;
wire SAXIGP0WREADY;

wire litex_reset;

assign reset = ~fresetn[0];
assign litex_reset = ~(SAXIGP0ARESETN & gpios[0]);
assign SAXIGP0ACLK = fclk0_bg;
assign MAXIGP0ACLK = fclk0_bg;
assign irqf2p = 20'h00000;

reg [31:0] counter;

always @(posedge fclk0_bg)
if(reset) begin
        counter <= 32'h00000000;
end else begin
    counter <= counter + 1'b1;
    if(counter == 32'hffffffff) begin
        counter <= 32'h00000000;
    end
end

assign led[0] = gpios[0];
assign led[1] = litex_reset;
assign led[2] = reset;
assign led[3] = counter[23];

BUFG bg (
    .I(clk125),
    .O(clk125_bg)
);

// The PS7
(* KEEP, DONT_TOUCH *)
PS7 the_PS (
    .FCLKCLK                (fclk),
    .FCLKRESETN             (fresetn),
    .MAXIGP0ARADDR          (MAXIGP0ARADDR  ),
    .MAXIGP0ARID            (MAXIGP0ARID),
    .MAXIGP0ARPROT          (MAXIGP0ARPROT  ),
    .MAXIGP0ARVALID         (MAXIGP0ARVALID ),
    .MAXIGP0AWADDR          (MAXIGP0AWADDR  ),
    .MAXIGP0AWID            (MAXIGP0AWID),
    .MAXIGP0AWPROT          (MAXIGP0AWPROT),
    .MAXIGP0AWVALID         (MAXIGP0AWVALID ),
    .MAXIGP0BREADY          (MAXIGP0BREADY  ),
    .MAXIGP0RREADY          (MAXIGP0RREADY  ),
    .MAXIGP0WDATA           (MAXIGP0WDATA   ),
    .MAXIGP0WID             (MAXIGP0WID),
    .MAXIGP0WSTRB           (MAXIGP0WSTRB   ),
    .MAXIGP0WVALID          (MAXIGP0WVALID  ),
    /* SAXI GP0 outputs */
    .SAXIGP1ARESETN         (SAXIGP0ARESETN ),
    .SAXIGP1ARREADY         (SAXIGP0ARREADY ),
    .SAXIGP1AWREADY         (SAXIGP0AWREADY ),
    .SAXIGP1BID             (SAXIGP0BID     ),
    .SAXIGP1BRESP           (SAXIGP0BRESP   ),
    .SAXIGP1BVALID          (SAXIGP0BVALID  ),
    .SAXIGP1RDATA           (SAXIGP0RDATA   ),
    .SAXIGP1RID             (SAXIGP0RID     ),
    .SAXIGP1RLAST           (SAXIGP0RLAST   ),
    .SAXIGP1RRESP           (SAXIGP0RRESP   ),
    .SAXIGP1RVALID          (SAXIGP0RVALID  ),
    .SAXIGP1WREADY          (SAXIGP0WREADY  ),
    .EMIOUSB0VBUSPWRFAULT   (1'b0),
    .EMIOUSB1VBUSPWRFAULT   (1'b0),
    .IRQF2P                 (irqf2p),
    .MAXIGP0ACLK            (MAXIGP0ACLK),
    .MAXIGP0ARREADY         (MAXIGP0ARREADY ),
    .MAXIGP0AWREADY         (MAXIGP0AWREADY ),
    .MAXIGP0BID             (MAXIGP0BID),
    .MAXIGP0BRESP           (MAXIGP0BRESP   ),
    .MAXIGP0BVALID          (MAXIGP0BVALID  ),
    .MAXIGP0RDATA           (MAXIGP0RDATA   ),
    .MAXIGP0RID             (MAXIGP0RID),
    .MAXIGP0RLAST           (1'b1),
    .MAXIGP0RRESP           (MAXIGP0RRESP   ),
    .MAXIGP0RVALID          (MAXIGP0RVALID  ),
    .MAXIGP0WREADY          (MAXIGP0WREADY  ),
    /* SAXI GP0 inputs */
    .SAXIGP1ACLK            (SAXIGP0ACLK    ),
    .SAXIGP1ARADDR          (SAXIGP0ARADDR  ),
    .SAXIGP1ARBURST         (SAXIGP0ARBURST ),
    .SAXIGP1ARCACHE         (SAXIGP0ARCACHE ),
    .SAXIGP1ARID            (SAXIGP0ARID    ),
    .SAXIGP1ARLEN           (SAXIGP0ARLEN   ),
    .SAXIGP1ARLOCK          (SAXIGP0ARLOCK  ),
    .SAXIGP1ARPROT          (SAXIGP0ARPROT  ),
    .SAXIGP1ARQOS           (SAXIGP0ARQOS   ),
    .SAXIGP1ARSIZE          (SAXIGP0ARSIZE  ),
    .SAXIGP1ARVALID         (SAXIGP0ARVALID ),
    .SAXIGP1AWADDR          (SAXIGP0AWADDR  ),
    .SAXIGP1AWBURST         (SAXIGP0AWBURST ),
    .SAXIGP1AWCACHE         (SAXIGP0AWCACHE ),
    .SAXIGP1AWID            (SAXIGP0AWID    ),
    .SAXIGP1AWLEN           (SAXIGP0AWLEN   ),
    .SAXIGP1AWLOCK          (SAXIGP0AWLOCK  ),
    .SAXIGP1AWPROT          (SAXIGP0AWPROT  ),
    .SAXIGP1AWQOS           (SAXIGP0AWQOS   ),
    .SAXIGP1AWSIZE          (SAXIGP0AWSIZE  ),
    .SAXIGP1AWVALID         (SAXIGP0AWVALID ),
    .SAXIGP1BREADY          (SAXIGP0BREADY  ),
    .SAXIGP1RREADY          (SAXIGP0RREADY  ),
    .SAXIGP1WDATA           (SAXIGP0WDATA   ),
    .SAXIGP1WID             (SAXIGP0WID     ),
    .SAXIGP1WLAST           (SAXIGP0WLAST   ),
    .SAXIGP1WSTRB           (SAXIGP0WSTRB   ),
    .SAXIGP1WVALID          (SAXIGP0WVALID  )
);

AxiPeriph testSlave (
    .clock(fclk0_bg),
    .reset(reset),
    .io_axi_s0_aw_awaddr(MAXIGP0AWADDR),
    .io_axi_s0_aw_awprot(MAXIGP0AWPROT),
    .io_axi_s0_aw_awvalid(MAXIGP0AWVALID),
    .io_axi_s0_aw_awready(MAXIGP0AWREADY),
    .io_axi_s0_aw_awid(MAXIGP0AWID),
    .io_axi_s0_w_wdata(MAXIGP0WDATA),
    .io_axi_s0_w_wstrb(MAXIGP0WSTRB),
    .io_axi_s0_w_wvalid(MAXIGP0WVALID),
    .io_axi_s0_w_wready(MAXIGP0WREADY),
    .io_axi_s0_w_wid(MAXIGP0WID),
    .io_axi_s0_b_bresp(MAXIGP0BRESP),
    .io_axi_s0_b_bvalid(MAXIGP0BVALID),
    .io_axi_s0_b_bready(MAXIGP0BREADY),
    .io_axi_s0_b_bid(MAXIGP0BID),
    .io_axi_s0_ar_araddr(MAXIGP0ARADDR),
    .io_axi_s0_ar_arprot(MAXIGP0ARPROT),
    .io_axi_s0_ar_arready(MAXIGP0ARREADY),
    .io_axi_s0_ar_arvalid(MAXIGP0ARVALID),
    .io_axi_s0_ar_arid(MAXIGP0ARID),
    .io_axi_s0_r_rdata(MAXIGP0RDATA),
    .io_axi_s0_r_rresp(MAXIGP0RRESP),
    .io_axi_s0_r_rvalid(MAXIGP0RVALID),
    .io_axi_s0_r_rready(MAXIGP0RREADY),
    .io_axi_s0_r_rid(MAXIGP0RID),
    .io_leds(gpios),
    .io_irqOut(testirq_f2p),
    .io_raddr(SAXIGP0ARADDR),
    .io_waddr(SAXIGP0AWADDR),
    .io_rdata(SAXIGP0RDATA),
    .io_wdata(SAXIGP0WDATA)
);

litex_top LitexTop(
    .serial_tx              (tx             ),
    .serial_rx              (rx             ),
    .cpu_reset              (litex_reset    ),
    .clk                    (clk125_bg      ),
    .clk_out                (fclk0_bg       ),
    .s_axi_axi_awready      (SAXIGP0AWREADY ),
    .s_axi_axi_awid         (SAXIGP0AWID    ),
    .s_axi_axi_awaddr       (SAXIGP0AWADDR  ),
    .s_axi_axi_awlen        (SAXIGP0AWLEN   ),
    .s_axi_axi_awsize       (SAXIGP0AWSIZE  ),
    .s_axi_axi_awburst      (SAXIGP0AWBURST ),
    .s_axi_axi_awlock       (SAXIGP0AWLOCK  ),
    .s_axi_axi_awcache      (SAXIGP0AWCACHE ),
    .s_axi_axi_awprot       (SAXIGP0AWPROT  ),
    .s_axi_axi_awqos        (SAXIGP0AWQOS   ),
    .s_axi_axi_awvalid      (SAXIGP0AWVALID ),
    .s_axi_axi_wready       (SAXIGP0WREADY  ),
    .s_axi_axi_wdata        (SAXIGP0WDATA   ),
    .s_axi_axi_wstrb        (SAXIGP0WSTRB   ),
    .s_axi_axi_wlast        (SAXIGP0WLAST   ),
    .s_axi_axi_wvalid       (SAXIGP0WVALID  ),
    .s_axi_axi_bid          (SAXIGP0BID     ),
    .s_axi_axi_bresp        (SAXIGP0BRESP   ),
    .s_axi_axi_bvalid       (SAXIGP0BVALID  ),
    .s_axi_axi_bready       (SAXIGP0BREADY  ),
    .s_axi_axi_arready      (SAXIGP0ARREADY ),
    .s_axi_axi_arid         (SAXIGP0ARID    ),
    .s_axi_axi_araddr       (SAXIGP0ARADDR  ),
    .s_axi_axi_arlen        (SAXIGP0ARLEN   ),
    .s_axi_axi_arsize       (SAXIGP0ARSIZE  ),
    .s_axi_axi_arburst      (SAXIGP0ARBURST ),
    .s_axi_axi_arlock       (SAXIGP0ARLOCK  ),
    .s_axi_axi_arcache      (SAXIGP0ARCACHE ),
    .s_axi_axi_arprot       (SAXIGP0ARPROT  ),
    .s_axi_axi_arqos        (SAXIGP0ARQOS   ),
    .s_axi_axi_arvalid      (SAXIGP0ARVALID ),
    .s_axi_axi_rresp        (SAXIGP0RRESP   ),
    .s_axi_axi_rvalid       (SAXIGP0RVALID  ),
    .s_axi_axi_rdata        (SAXIGP0RDATA   ),
    .s_axi_axi_rlast        (SAXIGP0RLAST   ),
    .s_axi_axi_rid          (SAXIGP0RID     ),
    .s_axi_axi_rready       (SAXIGP0RREADY  )
);
endmodule
