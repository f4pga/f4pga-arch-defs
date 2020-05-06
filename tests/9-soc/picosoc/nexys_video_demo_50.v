/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

module nexys_video_demo (
    input clk,

    output tx,
    input rx,

    input [7:0] sw,
    output [7:0] led
);
    // Input 100MHz clock through a BUFG
    wire clk100;
    BUFG bufg100 (.I(clk), .O(clk100));

    // Clock divider using logic to get 50MHz
    reg clk50 = 1'b0;
    always @(posedge clk100)
        clk50 <= !clk50;

    // Reset generator
    reg [5:0] reset_cnt = 0;
    wire resetn = &reset_cnt;

    always @(posedge clk50) begin
        reset_cnt <= reset_cnt + !resetn;
    end

    // A simple GPIO peripheral connected to LEDs
    wire        iomem_valid;
    reg         iomem_ready;
    wire [3:0]  iomem_wstrb;
    wire [31:0] iomem_addr;
    wire [31:0] iomem_wdata;
    reg  [31:0] iomem_rdata;

    reg [31:0] gpio;

    assign led = gpio[7:0];

    always @(posedge clk50) begin
        if (!resetn) begin
            gpio <= 0;
        end else begin
            iomem_ready <= 0;
            if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h 03) begin
                iomem_ready <= 1;
                iomem_rdata <= {gpio[31:24], sw, gpio[15:0]};
                if (iomem_wstrb[0]) gpio[ 7: 0] <= iomem_wdata[ 7: 0];
                if (iomem_wstrb[1]) gpio[15: 8] <= iomem_wdata[15: 8];
                if (iomem_wstrb[2]) gpio[23:16] <= iomem_wdata[23:16];
                if (iomem_wstrb[3]) gpio[31:24] <= iomem_wdata[31:24];
            end
        end
    end

    // The picosoc
    picosoc_noflash soc (
        .clk          (clk50),
        .resetn       (resetn      ),

        .ser_tx       (tx),
        .ser_rx       (rx),

        .irq_5        (1'b0        ),
        .irq_6        (1'b0        ),
        .irq_7        (1'b0        ),

        .iomem_valid  (iomem_valid ),
        .iomem_ready  (iomem_ready ),
        .iomem_wstrb  (iomem_wstrb ),
        .iomem_addr   (iomem_addr  ),
        .iomem_wdata  (iomem_wdata ),
        .iomem_rdata  (iomem_rdata )
    );

endmodule

