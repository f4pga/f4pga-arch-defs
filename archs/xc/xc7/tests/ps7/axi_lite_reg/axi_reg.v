module top(
    output wire [3:0] led
);

wire [3:0] fclk;
wire [3:0] fresetn;
wire reset;
wire testirq_f2p;
/* AXI bus */
/* AR */
wire [31:0] MAXIGP0ARADDR;
wire MAXIGP0ARCACHE;
wire MAXIGP0ARESETN;
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
wire [19:0] irqf2p;

wire clk;
BUFG bufg (.I(fclk[0]), .O(clk));

assign reset = ~fresetn[0];
assign irqf2p = {{19{1'b0}}, testirq_f2p};

reg [31:0] counter;

always @(posedge clk)
if(reset) begin
    counter <= 32'h00000000;
end else begin
    counter <= counter + 1'b1;
    if(counter == 32'hffffffff) begin
        counter <= 32'h00000000;
    end
end

assign led[2] = reset;
assign led[3] = counter[22];

(* KEEP, DONT_TOUCH *)
PS7 PS7 (
    .FCLKCLK                    (fclk),
    .FCLKRESETN                 (fresetn),
    .MAXIGP0ARADDR              (MAXIGP0ARADDR  ),
    .MAXIGP0ARID                (MAXIGP0ARID),
    .MAXIGP0ARPROT              (MAXIGP0ARPROT  ),
    .MAXIGP0ARVALID             (MAXIGP0ARVALID ),
    .MAXIGP0AWADDR              (MAXIGP0AWADDR  ),
    .MAXIGP0AWID                (MAXIGP0AWID),
    .MAXIGP0AWPROT              (MAXIGP0AWPROT),
    .MAXIGP0AWVALID             (MAXIGP0AWVALID ),
    .MAXIGP0BREADY              (MAXIGP0BREADY  ),
    .MAXIGP0RREADY              (MAXIGP0RREADY  ),
    .MAXIGP0WDATA               (MAXIGP0WDATA   ),
    .MAXIGP0WID                 (MAXIGP0WID),
    .MAXIGP0WSTRB               (MAXIGP0WSTRB   ),
    .MAXIGP0WVALID              (MAXIGP0WVALID  ),
    .EMIOUSB0VBUSPWRFAULT       (1'b0),
    .EMIOUSB1VBUSPWRFAULT       (1'b0),
    .IRQF2P                     (irqf2p),
    .MAXIGP0ACLK                (clk),
    .MAXIGP0ARREADY             (MAXIGP0ARREADY ),
    .MAXIGP0AWREADY             (MAXIGP0AWREADY ),
    .MAXIGP0BID                 (MAXIGP0BID),
    .MAXIGP0BRESP               (MAXIGP0BRESP   ),
    .MAXIGP0BVALID              (MAXIGP0BVALID  ),
    .MAXIGP0RDATA               (MAXIGP0RDATA   ),
    .MAXIGP0RID                 (MAXIGP0RID),
    .MAXIGP0RLAST               (1'b1),
    .MAXIGP0RRESP               (MAXIGP0RRESP   ),
    .MAXIGP0RVALID              (MAXIGP0RVALID  ),
    .MAXIGP0WREADY              (MAXIGP0WREADY  )
);

AxiPeriph testSlave (
    .clock                  (clk),
    .reset                  (reset),
    .io_axi_s0_aw_awaddr    (MAXIGP0AWADDR),
    .io_axi_s0_aw_awprot    (MAXIGP0AWPROT),
    .io_axi_s0_aw_awvalid   (MAXIGP0AWVALID),
    .io_axi_s0_aw_awready   (MAXIGP0AWREADY),
    .io_axi_s0_aw_awid      (MAXIGP0AWID),
    .io_axi_s0_w_wdata      (MAXIGP0WDATA),
    .io_axi_s0_w_wstrb      (MAXIGP0WSTRB),
    .io_axi_s0_w_wvalid     (MAXIGP0WVALID),
    .io_axi_s0_w_wready     (MAXIGP0WREADY),
    .io_axi_s0_w_wid        (MAXIGP0WID),
    .io_axi_s0_b_bresp      (MAXIGP0BRESP),
    .io_axi_s0_b_bvalid     (MAXIGP0BVALID),
    .io_axi_s0_b_bready     (MAXIGP0BREADY),
    .io_axi_s0_b_bid        (MAXIGP0BID),
    .io_axi_s0_ar_araddr    (MAXIGP0ARADDR),
    .io_axi_s0_ar_arprot    (MAXIGP0ARPROT),
    .io_axi_s0_ar_arready   (MAXIGP0ARREADY),
    .io_axi_s0_ar_arvalid   (MAXIGP0ARVALID),
    .io_axi_s0_ar_arid      (MAXIGP0ARID),
    .io_axi_s0_r_rdata      (MAXIGP0RDATA),
    .io_axi_s0_r_rresp      (MAXIGP0RRESP),
    .io_axi_s0_r_rvalid     (MAXIGP0RVALID),
    .io_axi_s0_r_rready     (MAXIGP0RREADY),
    .io_axi_s0_r_rid        (MAXIGP0RID),
    .io_leds                (led[1:0]),
    .io_irqOut              (testirq_f2p)
);
endmodule
